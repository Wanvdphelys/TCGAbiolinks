% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/TCGAanalyze.R
\name{TCGAanalyze_Preprocessing}
\alias{TCGAanalyze_Preprocessing}
\title{Array Array Intensity correlation (AAIC) and correlation boxplot to define outlier}
\usage{
TCGAanalyze_Preprocessing(object, cor.cut = 0, filename = NULL,
  width = 500, height = 500, datatype = "raw_counts")
}
\arguments{
\item{object}{of gene expression of class RangedSummarizedExperiment from TCGAprepare}

\item{cor.cut}{is a threshold to filter samples according their spearman correlation in
samples by samples. default cor.cut is 0}

\item{filename}{Filename of the image file}

\item{width}{Image width}

\item{height}{Image height}

\item{datatype}{is a string from RangedSummarizedExperiment assay}
}
\value{
Plot with array array intensity correlation and boxplot of correlation samples by samples
}
\description{
TCGAanalyze_Preprocessing perform Array Array Intensity correlation (AAIC).
It defines a square symmetric matrix of pearson correlation among samples.
According this matrix and boxplot of correlation samples by samples it is possible
to find samples with low correlation that can be identified as possible outliers.
}

