% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/TCGADownload.R
\name{GDCdownload}
\alias{GDCdownload}
\title{Download GDC data}
\usage{
GDCdownload(query, token.file, method = "api", directory = "GDCdata")
}
\arguments{
\item{query}{A query for GDCquery function}

\item{token.file}{Token file to download controled data (only for method = "client")}

\item{method}{Uses the API (POST method) or gdc client tool. Options "api", "client".
API is faster, but the data might get corrupted in the download, and it might need to be executed again}

\item{directory}{Directory/Folder where the data was downloaded. Default: GDCdata}
}
\value{
Shows the output from the GDC transfer tools
}
\description{
Uses GDC API or GDC transfer tool to download gdc data
  The user can use query argument
  The data from query will be save in a folder: project/data.category
}
\examples{
query <- GDCquery(project = "TCGA-ACC",
                 data.category =  "Copy number variation",
                 legacy = TRUE,
                 file.type = "hg19.seg",
                 barcode = c("TCGA-OR-A5LR-01A-11D-A29H-01", "TCGA-OR-A5LJ-10A-01D-A29K-01"))
# data will be saved in  GDCdata/TCGA-ACC/legacy/Copy_number_variation/Copy_number_segmentation
GDCdownload(query, method = "api")
query <- GDCquery(project = "TARGET-AML",
                  data.category = "Transcriptome Profiling",
                  data.type = "miRNA Expression Quantification",
                  workflow.type = "BCGSC miRNA Profiling",
                  barcode = c("TARGET-20-PARUDL-03A-01R","TARGET-20-PASRRB-03A-01R"))
# data will be saved in  example_data_dir/TARGET-AML/harmonized/Transcriptome_Profiling/miRNA_Expression_Quantification
GDCdownload(query, method = "client", directory = "example_data_dir")
}

