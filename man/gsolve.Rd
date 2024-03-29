% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genomic_solve.R
\name{gsolve}
\alias{gsolve}
\title{Solve linear mixed model equations}
\usage{
gsolve(
  y = NULL,
  X = NULL,
  GRM = NULL,
  va = NULL,
  ve = NULL,
  Glist = NULL,
  W = NULL,
  ids = NULL,
  rsids = NULL,
  sets = NULL,
  scale = TRUE,
  lambda = NULL,
  weights = FALSE,
  maxit = 500,
  tol = 1e-05,
  method = "gsru",
  ncores = 1
)
}
\arguments{
\item{y}{vector or matrix of phenotypes}

\item{X}{design matrix of fixed effects}

\item{GRM}{genetic relationship matrix}

\item{va}{genetic variance}

\item{ve}{residual variance}

\item{Glist}{list of information about genotype matrix stored on disk}

\item{W}{matrix of centered and scaled genotypes}

\item{ids}{vector of individuals used in the analysis}

\item{rsids}{vector of marker rsids used in the analysis}

\item{sets}{list containing marker sets rsids}

\item{scale}{logical if TRUE the genotypes in Glist will be scaled to mean zero and variance one}

\item{lambda}{overall shrinkage factor}

\item{weights}{vector of single marker weights used in BLUP}

\item{maxit}{maximum number of iterations used in the Gauss-Seidel procedure}

\item{tol}{tolerance, i.e. the maximum allowed difference between two consecutive iterations of the solver to declare convergence}

\item{method}{used in solver (currently only methods="gsru": gauss-seidel with resiudal update)}

\item{ncores}{number of cores used in the analysis}
}
\description{
The gsolve function is used for solving of linear mixed model equations. The algorithm used to solve the equation
system is based on a Gauss-Seidel (GS) method (matrix-free with residual updates) that handles large data sets.

The linear mixed model fitted can account for multiple traits, multiple genetic factors (fixed or random genetic
marker effects), adjust for complex family relationships or population stratification, and adjust for other
non-genetic factors including lifestyle characteristics. Different genetic architectures (infinitesimal,
few large and many small effects) is accounted for by modeling genetic markers in different sets as fixed or
random effects and by specifying individual genetic marker weights.
}
\examples{

# Simulate data
W <- matrix(rnorm(1000000), ncol = 1000)
	colnames(W) <- as.character(1:ncol(W))
	rownames(W) <- as.character(1:nrow(W))
m <- ncol(W)
causal <- sample(1:ncol(W),50)
y <- rowSums(W[,causal]) + rnorm(nrow(W),sd=sqrt(50))

X <- model.matrix(y~1)

Sg <- 50
Se <- 50
h2 <- Sg/(Sg+Se)
lambda <- Se/(Sg/m)
lambda <- m*(1-h2)/h2

# BLUP of single marker effects and total genomic effects based on Gauss-Seidel procedure
fit <- gsolve( y=y, X=X, W=W, lambda=lambda)

}
\author{
Peter Soerensen
}
