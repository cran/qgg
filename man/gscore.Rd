% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genomic_solve.R
\name{gscore}
\alias{gscore}
\title{Genomic prediction based on single marker summary statistics}
\usage{
gscore(
  Glist = NULL,
  bedfiles = NULL,
  bimfiles = NULL,
  famfiles = NULL,
  stat = NULL,
  ids = NULL,
  scale = TRUE,
  impute = TRUE,
  msize = 100,
  ncores = 1
)
}
\arguments{
\item{Glist}{list of information about genotype matrix}

\item{bedfiles}{name of the PLINK bed-files}

\item{bimfiles}{name of the PLINK bim-files}

\item{famfiles}{name of the PLINK fam-files}

\item{stat}{matrix of single marker effects}

\item{ids}{vector of individuals used in the analysis}

\item{scale}{logical if TRUE the genotype markers have been scale to mean zero and variance one}

\item{impute}{logical if TRUE missing genotypes are set to its expected value (2*af where af is allele frequency)}

\item{msize}{number of genotype markers used for batch processing}

\item{ncores}{number of cores used in the analysis}
}
\description{
The gscore function is used for genomic predictions based on single marker summary statistics
(coefficients, log-odds ratios, z-scores) and observed genotypes.
}
\examples{

bedfiles <- system.file("extdata", "sample_22.bed", package = "qgg")
bimfiles <- system.file("extdata", "sample_22.bim", package = "qgg")
famfiles <- system.file("extdata", "sample_22.fam", package = "qgg")

fnRAW <- tempfile(fileext=".raw")

Glist <- gprep(study="1000G", fnRAW=fnRAW, bedfiles=bedfiles, bimfiles=bimfiles,
               famfiles=famfiles, overwrite=TRUE)

rsids <- Glist$rsids
stat <- data.frame(rsids=Glist$rsids,alleles=Glist$a2, af=Glist$af, effect=rnorm(Glist$m))

W <- getW(Glist=Glist,rsids=Glist$rsids)
pgs1 <- W\%*\%stat[,4]

pgs2 <- gscore(Glist = Glist, stat = stat) 

pgs3 <- gscore(bedfiles=bedfiles, stat = stat) 

pgs4 <- gscore(bedfiles=bedfiles,bimfiles=bimfiles,famfiles=famfiles, stat = stat) 


cor(cbind(pgs1,pgs2,pgs3,pgs4))

file.remove(fnRAW)
}
\author{
Peter Soerensen
}
