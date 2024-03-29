% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genomic_score.R
\name{mtadj}
\alias{mtadj}
\title{Adjustment of marker effects using correlated trait information}
\usage{
mtadj(
  h2 = NULL,
  rg = NULL,
  stat = NULL,
  b = NULL,
  z = NULL,
  n = NULL,
  mtotal = NULL,
  meff = 60000,
  method = "ols",
  statistics = "z"
)
}
\arguments{
\item{h2}{A vector of heritability estimates.}

\item{rg}{An n-by-n matrix of genetic correlations.}

\item{stat}{A dataframe containing marker summary statistics.}

\item{b}{A matrix of marker effects.}

\item{z}{A matrix of z-scores.}

\item{n}{A vector indicating the sample size used to estimate marker effects for each trait.}

\item{mtotal}{Total number of markers.}

\item{meff}{Effective number of uncorrelated genomic segments (default = 60,000).}

\item{method}{Method to estimate marker effects. Can be "OLS" (ordinary least square, default) or "BLUP" (best linear unbiased prediction).}

\item{statistics}{Specifies which kind of statistics ("b" or "z") should be used in the analysis.}
}
\value{
A matrix of adjusted marker effects for each trait.
}
\description{
The `mtadj` function uses selection index theory to determine the optimal weights across `n` traits. 
These weights are then used to adjust marker effects by `n` correlated traits. 
More details can be found [here](https://www.nature.com/articles/s41467-017-02769-6).
}
\examples{

 #bedfiles <- system.file("extdata", "sample_22.bed", package = "qgg")
 #bimfiles <- system.file("extdata", "sample_22.bim", package = "qgg")
 #famfiles <- system.file("extdata", "sample_22.fam", package = "qgg")
 #Glist <- gprep(study="1000G", bedfiles=bedfiles, bimfiles=bimfiles,famfiles=famfiles)
 #Glist <- gprep(Glist, task="sparseld",  msize=200)
 #
 ##Simulate data
 #set.seed(23)
 #
 #W <- getG(Glist, chr=1, scale=TRUE)
 #causal <- sample(1:ncol(W),50)
 #set1 <- c(causal, sample(c(1:ncol(W))[-causal],10))
 #set2 <- c(causal, sample(c(1:ncol(W))[-set1],10))
 #
 #b1 <- rnorm(length(set1))
 #b2 <- rnorm(length(set2))
 #y1 <- W[, set1]\%*\%b1 + rnorm(nrow(W))
 #y2 <- W[, set2]\%*\%b2 + rnorm(nrow(W))
 #
 ## Create model
 #data1 <- data.frame(y = y1, mu = 1)
 #data2 <- data.frame(y = y2, mu = 1)
 #X1 <- model.matrix(y ~ 0 + mu, data = data1)
 #X2 <- model.matrix(y ~ 0 + mu, data = data2)
 #
 ## Linear model analyses and single marker association test
 #maLM1 <- glma(y=y1, X=X1,W = W)
 #maLM2 <- glma(y=y2,X=X2,W = W)
 #
 ## Compute genetic parameters
 #z1 <- maLM1[,"stat"]
 #z2 <- maLM2[,"stat"]
 #
 #z <- cbind(z1=z1,z2=z2)
 #
 #h2 <- ldsc(Glist, z=z, n=c(500,500), what="h2")
 #rg <- ldsc(Glist, z=z, n=c(500,500), what="rg")
 #
 ## Adjust summary statistics using estimated genetic parameters
 #b <- cbind(b1=maLM1[,"b"],b2=maLM2[,"b"])
 #bm <- mtadj( h2=h2, rg=rg, b=b, n=c(500,500), method="ols")
 
 
}
\author{
Palle Duun Rohde and Peter Soerensen
}
