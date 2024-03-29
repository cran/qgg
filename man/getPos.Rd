% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genomic_matrix.R
\name{getPos}
\alias{getPos}
\title{Retrieve the positions for specified rsids on a given chromosome.}
\usage{
getPos(Glist = NULL, chr = NULL, rsids = NULL)
}
\arguments{
\item{Glist}{A list structure with information about genotypes stored on disk.}

\item{chr}{A chromosome from which the positions are retrieved.}

\item{rsids}{A vector of rsids for which the positions are needed.}
}
\value{
A vector containing the positions corresponding to the specified rsids on the given chromosome.
}
\description{
Fetch the genomic positions associated with provided rsids for a given chromosome from the list `Glist`.
}
\keyword{internal}
