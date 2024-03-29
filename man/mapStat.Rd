% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genomic_statistics.R
\name{mapStat}
\alias{mapStat}
\title{Map marker summary statistics to Glist}
\usage{
mapStat(
  Glist = NULL,
  stat = NULL,
  excludeMAF = 0.01,
  excludeMAFDIFF = 0.05,
  excludeINFO = 0.8,
  excludeCGAT = TRUE,
  excludeINDEL = TRUE,
  excludeDUPS = TRUE,
  excludeMHC = FALSE,
  excludeMISS = 0.05,
  excludeHWE = 1e-12
)
}
\arguments{
\item{Glist}{list of information about genotype matrix stored on disk}

\item{stat}{dataframe with marker summary statistics}

\item{excludeMAF}{exclude marker if minor allele frequency (MAF) is below threshold (0.01 is default)}

\item{excludeMAFDIFF}{exclude marker if minor allele frequency difference (MAFDIFF) between Glist$af and stat$af is above threshold (0.05 is default)}

\item{excludeINFO}{exclude marker if info score (INFO) is below threshold (0.8 is default)}

\item{excludeCGAT}{exclude marker if alleles are ambigous (CG or AT)}

\item{excludeINDEL}{exclude marker if it an insertion/deletion}

\item{excludeDUPS}{exclude marker id if duplicated}

\item{excludeMHC}{exclude marker if located in MHC region}

\item{excludeMISS}{exclude marker if missingness (MISS) is above threshold (0.05 is default)}

\item{excludeHWE}{exclude marker if p-value for Hardy Weinberg Equilibrium test is below threshold (0.01 is default)}
}
\description{
Quality control is a critical step for working with summary statistics (in particular
                                                                        for external). 
Processing and quality control of GWAS summary statistics includes:                                                                      

- map marker ids (rsids/cpra (chr, pos, ref, alt)) to LD reference panel data 

- check effect allele (flip EA, EAF, Effect)

- check effect allele frequency

- thresholds for MAF and HWE

- exclude INDELS, CG/AT and MHC region

- remove duplicated marker ids

- check which build version

- check for concordance between marker effect and LD data
}
\author{
Peter Soerensen
}
\keyword{internal}
