#' @title Download GDC data
#' @description
#'   Uses GDC API or GDC transfer tool to download gdc data
#'   The user can use query argument
#'   The data from query will be save in a folder: project/data.category
#' @param query A query for GDCquery function
#' @param token.file Token file to download controled data (only for method = "client")
#' @param method Uses the API (POST method) or gdc client tool. Options "api", "client".
#' API is faster, but the data might get corrupted in the download, and it might need to be executed again
#' @param directory Directory/Folder where the data was downloaded. Default: GDCdata
#' @importFrom tools md5sum
#' @importFrom utils untar
#' @import httr
#' @export
#' @examples
#' query <- GDCquery(project = "TCGA-ACC",
#'                  data.category =  "Copy number variation",
#'                  legacy = TRUE,
#'                  file.type = "hg19.seg",
#'                  barcode = c("TCGA-OR-A5LR-01A-11D-A29H-01", "TCGA-OR-A5LJ-10A-01D-A29K-01"))
#' # data will be saved in  GDCdata/TCGA-ACC/legacy/Copy_number_variation/Copy_number_segmentation
#' GDCdownload(query, method = "api")
#' query <- GDCquery(project = "TARGET-AML",
#'                   data.category = "Transcriptome Profiling",
#'                   data.type = "miRNA Expression Quantification",
#'                   workflow.type = "BCGSC miRNA Profiling",
#'                   barcode = c("TARGET-20-PARUDL-03A-01R","TARGET-20-PASRRB-03A-01R"))
#' # data will be saved in  example_data_dir/TARGET-AML/harmonized/Transcriptome_Profiling/miRNA_Expression_Quantification
#' GDCdownload(query, method = "client", directory = "example_data_dir")
#' @return Shows the output from the GDC transfer tools
GDCdownload <- function(query,
                        token.file,
                        method = "api",
                        directory = "GDCdata") {

    if(missing(query)) stop("Please set query argument")
    if(!(method %in% c("api","client"))) stop("method arguments possible values are: 'api' or 'client'")
    manifest <- query$results[[1]][,c("file_id","file_name","md5sum","file_size","state")]
    colnames(manifest) <- c("id","filename","md5","size","state")

    source <- ifelse(query$legacy,"legacy","harmonized")

    path <- unique(file.path(query$project, source,
                             gsub(" ","_", query$results[[1]]$data_category),
                             gsub(" ","_",query$results[[1]]$data_type)))
    dir.create(directory, showWarnings = FALSE, recursive = TRUE)
    path <- file.path(directory, path)

    # Check if the files were already downloaded by this package

    files2Download <- !file.exists(file.path(path,manifest$id,manifest$filename))
    manifest <- manifest[files2Download,]
    # There is a bug in the API, if the files has the same name it will not download correctly
    # so method should be set to client if there are files with duplicated names
    if(nrow(manifest) > length(unique(manifest$filename))) method <- "client"
    if(nrow(manifest) != 0 & method == "client") {
        # There exists two options to download the data, using the query or using a manifest file
        # The second option was created to let users use legacy data or the API to search

        # This will find gdc clinet, if not installed it will install it
        gdc.client.bin <- GDCclientInstall()

        # Using the query argument we will organize the files to the user
        # Creates a file with the gdc manifest format
        write_delim(manifest,"gdc_manifest.txt",delim = "\t")

        cmd <- paste0(gdc.client.bin, " download -m gdc_manifest.txt")

        if(!missing(token.file)) cmd <- paste0(cmd," -t ", token.file)

        # Download all the files in the manifest using gdc client
        message(paste0("GDCdownload will download: ",
                       humanReadableByteCount(sum(as.numeric(manifest$size)))))
        message(paste0("Executing GDC client with the following command:\n",cmd))
        result = tryCatch({
            system(cmd)
        }, warning = function(w) {
        }, error = function(e) {
        }, finally = {
            # moving the file to make it more organized
            for(i in manifest$id) move(i,file.path(path,i))
        })



    } else if (nrow(manifest) != 0 & method =="api"){
        if(nrow(manifest) > 1) {
            name <- paste0(gsub(" |:","_",date()),".tar.gz")
            unlink(name)
            message(paste0("GDCdownload will download: ",
                           humanReadableByteCount(sum(as.numeric(manifest$size))),
                           " compressed in a tar.gz file"))
        } else {
            # case with one file only. This is not at tar.gz
            name <- query$results[[1]]$file_name
            message(paste0("GDCdownload will download: ",
                           humanReadableByteCount(sum(as.numeric(manifest$size)))))
        }
        message(paste0("Downloading as: ", name))

        # Is there a better way to do it using rcurl library?
        server <- ifelse(query$legacy,"https://gdc-api.nci.nih.gov/legacy/data/", "https://gdc-api.nci.nih.gov/data/")
        body <- list(ids=list(manifest$id))

        result = tryCatch({
            bin <- POST(server,
                        body = body,
                        encode = "json", progress())
            writeBin(content(bin,"raw",encoding = "UTF-8"), name)
        }, warning = function(w) {
        }, error = function(e) {
            unlink(name) # remove tar
        }, finally = {
            if(nrow(manifest) > 1) {
                success <- untar(name)
                unlink(name) # remove tar
                if(success != 0){
                    print(success)
                    stop("There was an error in the download process, please execute it again")
                }
            }
            # moving to project/source/data_category/data_type/file_id
            for(i in seq_along(manifest$filename)) {
                if(nrow(manifest) > 1) file <- file.path(manifest$id[i], manifest$filename[i])
                if(nrow(manifest) == 1) file <- file.path(manifest$filename[i])
                id <- manifest$id[i]

                # Check status
                if(!(md5sum(file) == manifest$md5[i])){
                    message(paste0("File corrupted:", file))
                    message("Run GDCdownload again to download it")
                    unlink(file)
                    next
                }
                if(nrow(manifest) > 1) {
                    move(file,file.path(path,file))
                }
                if(nrow(manifest) == 1) move(file,file.path(path,id,file))
            }
            message("Download completed")

        })
    } else {
        message("All samples have been already downloded")
    }
}


humanReadableByteCount <- function(bytes) {
    unit <- 1000
    if (bytes < unit) return (paste0(bytes + " B"))
    exp <- floor(log(bytes) / log(unit))
    pre <- paste0(substr("KMGTPE",exp,exp))
    pre <- paste0(pre,"B")
    nb <- bytes / (unit ^ exp)
    return (paste(nb, pre))
}
GDCclientPath <- function(){
    global <- Sys.which("gdc-client")
    if(global != "") return(global)
    local <- dir(pattern = "gdc-client*[^zip]$")
    if(length(local) > 0) return(dir(pattern = "gdc-client*[^zip]$",full.names = TRUE))
    return("")
}

GDCclientExists <- function(){
    return(Sys.which("gdc-client.exe") != "" || Sys.which("gdc-client") != "" || length(dir(pattern = "gdc-client*[^zip]$") > 0))
}
#' @importFrom xml2 read_html
#' @importFrom downloader download
#' @importFrom rvest html_nodes html_attr
GDCclientInstall <- function(){
    if(GDCclientExists()) return(GDCclientPath())

    links <- read_html("https://gdc.nci.nih.gov/access-data/gdc-data-transfer-tool")  %>% html_nodes("a") %>% html_attr("href")
    bin <- links[grep("zip",links)]
    if(is.windows()) bin <- bin[grep("windows", bin)]
    if(is.mac()) bin <- bin[grep("OSX", bin)]
    if(is.linux()) bin <- bin[grep("Ubuntu", bin)]
    if(is.windows()) mode <- "wb" else  mode <- "w"
    download(paste0("https://gdc.nci.nih.gov/",bin), basename(bin), mode = mode)
    unzip(basename(bin))
    Sys.chmod("gdc-client")
    return(GDCclientPath())
}
#' @title Download the data from TCGA using as reference the output from TCGAquery
#' @description
#'      The TCGAdownload function will download the data using as reference
#'      the the lines of the TCGAquery search result.
#'
#'      There is an option to download the entire tar.gz folder or download
#'      specific files using the \emph{type} parameter or the \emph{samples}
#'      parameter
#'
#'      The outpufiles will be saved into the path parameters. If this path does
#'      not exists the package will try to create the directories.
#'
#'      By default, if a sample was already downloaded the function will not
#'      download again, unless the force parameter is set to \code{TRUE}
#'
#' @param data The TCGAquery output
#' @param path Directory to save the downloaded data
#' @param type Filter the files that will be downloaded by
#'  type. Example:"rsem.genes.results"
#' @param samples List of samples to download data
#' @param force Download files even if it was already downladed?
#' Default: \code{FALSE}
#' @examples
#' \dontrun{
#' samples <- c("TCGA-26-1442-01A-01R-1850-01")
#' query <- TCGAquery(tumor = "gbm",
#'                    platform = "IlluminaHiSeq_RNASeqV2",
#'                    level = "3",
#'                    samples = samples)
#' TCGAdownload(query,path = "RNA",
#'              samples = samples,
#'              type ="rsem.genes.results")
#' }
#' @export
#' @return Download TCGA data into the given path
#' @family data functions
TCGAdownload <- function(data = NULL, path = ".", type = NULL, samples = NULL, force = FALSE) {
    stop("TCGA data has moved from DCC server to GDC server. Please use GDCdownload function")
}

