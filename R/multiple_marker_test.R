####################################################################################################################
#    Module 2: Marker set tests
####################################################################################################################
#'
#' Gene set enrichment analysis
#'
#' @description
#' The function gsea can perform several different gene set enrichment analyses. The general procedure is to obtain
#' single marker statistics (e.g. summary statistics), from which it is possible to compute and evaluate a test statistic
#' for a set of genetic markers that measures a joint degree of association between the marker set and the phenotype.
#' The marker set is defined by a genomic feature such as genes, biological pathways, gene interactions,
#' gene expression profiles etc.
#'
#' Currently, four types of gene set enrichment analyses can be conducted with gsea; sum-based, count-based,
#' score-based, and our own developed method, the covariance association test (CVAT). For details and comparisons of
#' test statistics consult doi:10.1534/genetics.116.189498.
#'
#' The sum test is based on the sum of all marker summary statistics located within the feature set. The single marker
#' summary statistics can be obtained from linear model analyses (from PLINK or using the qgg glma approximation),
#' or from single or multiple component REML analyses (GBLUP or GFBLUP) from the greml function. The sum test is powerful
#' if the genomic feature harbors many genetic markers that have small to moderate effects.
#'
#' The count-based method is based on counting the number of markers within a genomic feature that show association
#' (or have single marker p-value below a certain threshold) with the phenotype. Under the null hypothesis (that the
#' associated markers are picked at random from the total number of markers, thus, no enrichment of markers in any
#' genomic feature) it is assumed that the observed count statistic is a realization from a hypergeometric distribution.
#'
#' The score-based approach is based on the product between the scaled genotypes in a genomic feature and the residuals
#' from the liner mixed model (obtained from greml).
#'
#' The covariance association test (CVAT) is derived from the fit object from greml (GBLUP or GFBLUP), and measures
#' the covariance between the total genomic effects for all markers and the genomic effects of the markers within the
#' genomic feature.
#'
#' The distribution of the test statistics obtained from the sum-based, score-based and CVAT is unknown, therefore
#' a circular permutation approach is used to obtain an empirical distribution of test statistics.
#'
#' @param stat vector or matrix of single marker statistics (e.g. coefficients, t-statistics, p-values)
#' @param sets list of marker sets - names corresponds to row names in stat
#' @param nperm number of permutations used for obtaining an empirical p-value
#' @param ncores number of cores used in the analysis
#' @param Glist list providing information about genotypes stored on disk
#' @param W matrix of centered and scaled genotypes (used if method = cvat or score)
#' @param fit list object obtained from a linear mixed model fit using the greml function
#' @param g vector (or matrix) of genetic effects obtained from a linear mixed model fit (GBLUP of GFBLUP)
#' @param e vector (or matrix) of residual effects obtained from a linear mixed model fit (GBLUP of GFBLUP)
#' @param method including sum, cvat, hyperg, score
#' @param threshold used if method='hyperg' (threshold=0.05 is default)

#' @return Returns a dataframe or a list including
#' \item{stat}{marker set test statistics}
#' \item{m}{number of markers in the set}
#' \item{p}{enrichment p-value for marker set}

#' @author Peter Soerensen


#' @examples
#'
#'
#'  # Simulate data
#'  W <- matrix(rnorm(1000000), ncol = 1000)
#'  colnames(W) <- as.character(1:ncol(W))
#'  rownames(W) <- as.character(1:nrow(W))
#'  y <- rowSums(W[, 1:10]) + rowSums(W[, 501:510]) + rnorm(nrow(W))
#'
#'  # Create model
#'  data <- data.frame(y = y, mu = 1)
#'  fm <- y ~ 0 + mu
#'  X <- model.matrix(fm, data = data)
#'
#'  # Single marker association analyses
#'  stat <- glma(y=y,X=X,W=W)
#'
#'  # Create marker sets
#'  f <- factor(rep(1:100,each=10), levels=1:100)
#'  sets <- split(as.character(1:1000),f=f)
#'
#'  # Set test based on sums
#'  b2 <- stat[,"stat"]**2
#'  names(b2) <- rownames(stat)
#'  mma <- gsea(stat = b2, sets = sets, method = "sum", nperm = 100)
#'  head(mma)
#'
#'  # Set test based on hyperG
#'  p <- stat[,"p"]
#'  names(p) <- rownames(stat)
#'  mma <- gsea(stat = p, sets = sets, method = "hyperg", threshold = 0.05)
#'  head(mma)
#'
#' \donttest{
#'  G <- grm(W=W)
#'  fit <- greml(y=y, X=X, GRM=list(G=G), theta=c(10,1))
#'
#'  # Set test based on cvat
#'  mma <- gsea(W=W,fit = fit, sets = sets, nperm = 1000, method="cvat")
#'  head(mma)
#'
#'  # Set test based on score
#'  mma <- gsea(W=W,fit = fit, sets = sets, nperm = 1000, method="score")
#'  head(mma)
#'
#' }


#' @export
gsea <- function(stat = NULL, sets = NULL, Glist = NULL, W = NULL, fit = NULL, g = NULL, e = NULL, threshold = 0.05, method = "sum", nperm = 1000, ncores = 1) {
  if(is.data.frame(stat)) {
    colstat <- !colnames(stat)%in%c("rsids","chr","pos","ea","nea","eaf")
    if(any(colstat)) stat <- as.matrix(stat[,colstat])**2
    if(!any(colstat)) stat <- as.matrix(stat[,colstat])
  }
  if (method == "sum") {
    #m <- length(stat)
    if (is.matrix(stat)) sets <- mapSets(sets = sets, rsids = rownames(stat), index = TRUE)
    if (is.vector(stat)) sets <- mapSets(sets = sets, rsids = names(stat), index = TRUE)
    nsets <- length(sets)
    msets <- sapply(sets, length)
    if (is.matrix(stat)) {
      p <- apply(stat, 2, function(x) {
        gsets(stat = x, sets = sets, ncores = ncores, np = nperm)
      })
      setstat <- apply(stat, 2, function(x) {
        sapply(sets, function(y) {
          sum(x[y])
        })
      })
      rownames(setstat) <- rownames(p) <- names(msets) <- names(sets)
      res <- list(m = msets, stat = setstat, p = p)
    }
    if (is.vector(stat)) {
      setstat <- sapply(sets, function(x) {
        sum(stat[x])
      })
      p <- gsets(stat = stat, sets = sets, ncores = ncores, np = nperm, method = method)
      res <- cbind(m = msets, stat = setstat, p = p)
      rownames(res) <- names(sets)
      res <- as.data.frame(res)
    }
    return(res)
  }
  if (method == "cvat") {
    if (!is.null(W)) res <- cvat(fit = fit, g = g, W = W, sets = sets, nperm = nperm)
    if (!is.null(Glist)) {
      sets <- mapSets(sets = sets, rsids = Glist$rsids, index = TRUE)
      nsets <- length(sets)
      msets <- sapply(sets, length)
      ids <- fit$ids
      Py <- fit$Py
      g <- as.vector(fit$g)
      Sg <- fit$theta[1]
      stat <- gstat(method = "cvat", Glist = Glist, g = g, Sg = Sg, Py = Py, ids = ids)
      setstat <- sapply(sets, function(x) {
        sum(stat[x])
      })
      p <- gsets(stat = stat, sets = sets, ncores = ncores, np = nperm, method = "sum")
      res <- cbind(m = msets, stat = setstat, p = p)
      rownames(res) <- names(sets)
    }
    return(res)
  }
  if (method == "score") {
    if (!is.null(W)) res <- scoretest(e = fit$e, W = W, sets = sets, nperm = nperm)
    if (!is.null(Glist)) {
        sets <- mapSets(sets = sets, rsids = Glist$rsids, index = TRUE)
      nsets <- length(sets)
      msets <- sapply(sets, length)
      ids <- fit$ids
      e <- fit$e
      stat <- gstat(method = "score", Glist = Glist, e = e, ids = ids)
      setstat <- sapply(sets, function(x) {
        sum(stat[x])
      })
      p <- gsets(stat = stat, sets = sets, ncores = ncores, np = nperm, method = "sum")
      res <- cbind(m = msets, stat = setstat, p = p)
      rownames(res) <- names(sets)
    }
    return(res)
  }
  if (method == "hyperg") {
    res <- hgtest(p = stat, sets = sets, threshold = threshold)
    return(as.data.frame(res))
  }
}


gsets <- function(stat = NULL, sets = NULL, ncores = 1, np = 1000, method = "sum") {
  m <- length(stat)
  nsets <- length(sets)
  msets <- sapply(sets, length)
  setstat <- sapply(sets, function(x) {
    sum(stat[x])
  })
  p <- .Call("_qgg_psets", msets = msets,
              setstat = setstat,
              stat = stat,
              np = np)
  p <- p/np 

  return(p)
}


#' Map Sets to RSIDs
#'
#' This function maps sets to rsids. If a `Glist` is provided, `rsids` are extracted from the `Glist`.
#' It returns a list of matched RSIDs for each set.
#'
#' @param sets A list of character vectors where each vector represents a set of items. If the names
#'   of the sets are not provided, they are named as "Set1", "Set2", etc.
#' @param rsids A character vector of RSIDs. If `Glist` is provided, this parameter is ignored.
#' @param Glist A list containing an element `rsids` which is a character vector of RSIDs.
#' @param index A logical. If `TRUE` (default), it returns indices of RSIDs; otherwise, it returns the RSID names.
#' 
#' @return A list where each element represents a set and contains matched RSIDs or their indices.
#' 
#' @keywords internal
#' @export
mapSets <- function(sets = NULL, rsids = NULL, Glist = NULL, index = TRUE) {
  if (!is.null(Glist)) rsids <- unlist(Glist$rsids)
  nsets <- sapply(sets, length)
  if(is.null(names(sets))) names(sets) <- paste0("Set",1:length(sets))
  rs <- rep(names(sets), times = nsets)
  rsSets <- unlist(sets, use.names = FALSE)
  rsSets <- match(rsSets, rsids)
  inW <- !is.na(rsSets)
  rsSets <- rsSets[inW]
  if (!index) rsSets <- rsids[rsSets]
  rs <- rs[inW]
  rs <- factor(rs, levels = unique(rs))
  rsSets <- split(rsSets, f = rs)
  return(rsSets)
}




gstat <- function(method = NULL, Glist = NULL, g = NULL, Sg = NULL, Py = NULL, e = NULL, msize = 100, rsids = NULL,
                  impute = TRUE, scale = TRUE, ids = NULL, ncores = 1) {
  n <- Glist$n
  rws <- match(ids, Glist$ids)
  if (any(is.na(rws))) stop("Some ids in fit object not found in Glist")
  nr <- length(rws)
  nbytes <- ceiling(n / 4)
  cls <- 1:Glist$m
  if (!is.null(rsids)) cls <- match(rsids, Glist$rsids)
  nc <- length(cls)
  cls <- split(cls, ceiling(seq_along(cls) / msize))
  msets <- sapply(cls, length)
  nsets <- length(msets)
  setstat <- NULL
  fnRAW <- Glist$fnRAW
  for (j in 1:nsets) {
    nc <- length(cls[[j]])
    direction <- rep(1, nc)

# Check this again - should be getW using a bedfile
      W <- getW(Glist = Glist, rws = rws, cls = cls, scale = scale)
# End check this again

    if (method == "cvat") {
      s <- crossprod(W / nc, Py) * Sg
      Ws <- t(t(W) * as.vector(s))
      setstat <- c(setstat, colSums(g * Ws))
    }
    if (method == "score") {
      we2 <- as.vector((t(W) %*% e)**2)
      setstat <- c(setstat, we2)
    }
    message(paste("Finished block", j, "out of", nsets, "blocks"))
  }
  return(setstat)
}




settest <- function(stat = NULL, W = NULL, sets = NULL, nperm = NULL, method = "sum", threshold = 0.05) {
  if (method == "sum") setT <- sumtest(stat = stat, sets = sets, nperm = nperm)
  if (method == "hyperG") setT <- hgtest(p = stat, sets = sets, threshold = threshold)
  return(setT)
}



sumtest <- function(stat = NULL, sets = NULL, nperm = NULL, method = "sum") {
  if (method == "mean") {
    setT <- sapply(sets, function(x) {
      mean(stat[x])
    })
  }
  if (method == "sum") {
    setT <- sapply(sets, function(x) {
      sum(stat[x])
    })
  }
  if (method == "max") {
    setT <- sapply(sets, function(x) {
      max(stat[x])
    })
  }
  if (!is.null(nperm)) {
    p <- rep(0, length(sets))
    n <- length(stat)
    nset <- sapply(sets, length)
    rws <- 1:n
    names(rws) <- names(stat)
    sets <- lapply(sets, function(x) {
      rws[x]
    })
    for (i in 1:nperm) {
      rws <- sample(1:n, 1)
      o <- c(rws:n, 1:(rws - 1))
      pstat <- stat[o]
      if (method == "mean") {
        setTP <- sapply(sets, function(x) {
          mean(pstat[x])
        })
      }
      if (method == "sum") {
        setTP <- sapply(sets, function(x) {
          sum(pstat[x])
        })
      }
      if (method == "max") {
        setTP <- sapply(sets, function(x) {
          max(pstat[x])
        })
      }
      p <- p + as.numeric(setT > setTP)
    }
    p <- 1 - p / nperm
    setT <- data.frame(setT, nset, p)
  }

  return(setT)
}



cvat <- function(fit = NULL, s = NULL, g = NULL, W = NULL, sets = NULL, nperm = 100) {
  if (!is.null(fit)) {
    s <- crossprod(W / ncol(W), fit$Py) * fit$theta[1]
  }
  Ws <- t(t(W) * as.vector(s))
  if (is.null(g)) g <- W %*% s
  cvs <- colSums(as.vector(g) * Ws)
  # setT <- setTest(stat = cvs, sets = sets, nperm = nperm, method = "sum")$p
  # names(setT) <- names(sets)
  setT <- settest(stat = cvs, sets = sets, nperm = nperm, method = "sum")
  if (!is.null(names(sets))) rownames(setT) <- names(sets)
  return(setT)
}


scoretest <- function(e = NULL, W = NULL, sets = NULL, nperm = 100) {
  we2 <- as.vector((t(W) %*% e)**2)
  names(we2) <- colnames(W)
  setT <- settest(stat = we2, sets = sets, nperm = nperm, method = "sum")$p
  return(setT)
}


hgtest <- function(p = NULL, sets = NULL, threshold = 0.05) {
  population_size <- length(p)
  sample_size <- sapply(sets, length)
  n_successes_population <- sum(p < threshold)
  n_successes_sample <- sapply(sets, function(x) {
    sum(p[x] < threshold)
  })
  phyperg <- rep(1,length(sets))
  names(phyperg) <- names(sets)
  for (i in 1:length(sets)) {
    phyperg[i] <- 1.0-phyper(n_successes_sample[i]-1, n_successes_population,
                             population_size-n_successes_population,
                             sample_size[i])
  }
  # Calculate enrichment factor
  ef <- (n_successes_sample/sample_size)/
    (n_successes_population/population_size)
  
  # Create data frame for table
  res <- data.frame(ng = sample_size,
                   nag = n_successes_sample,
                   ef=ef,
                   p = phyperg)
  #colnames(res) <- c("Feature", "Number of Genes",
  #                  "Number of Associated Genes",
  #                  "Enrichment Factor",
  #                  "p")
  res
}


# hgtest <- function(p = NULL, sets = NULL, threshold = 0.05) {
#   N <- length(p)
#   Na <- sum(p < threshold)
#   Nna <- N - Na
#   Nf <- sapply(sets, length)
#   Naf <- sapply(sets, function(x) {
#     sum(p[x] < threshold)
#   })
#   Nnaf <- Nf - Naf
#   Nanf <- Na - Naf
#   Nnanf <- Nna - Nnaf
#   phyperg <- 1 - phyper(Naf - 1, Nf, N - Nf, Na)
#   phyperg
# }
