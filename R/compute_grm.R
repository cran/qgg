#######################################################################################
# compute GRM functions
#######################################################################################
#'
#' Computing the genomic relationship matrix (GRM)
#'
#' @description
#' The grm function is used to compute a genomic relationship matrix (GRM) based on all,
#' or a subset of marker genotypes. GRM for additive, and non-additive (dominance and
#' epistasis) genetic models can be constructed. The output of the grm function can either be a
#' within-memory GRM object (n x n matrix), or a GRM-list which is a list structure that
#' contains information about the GRM stored in a binary file on the disk.
#'
#' @param Glist list providing information about genotypes stored on disk
#' @param GRMlist list providing information about GRM matrix stored in binary files on disk
#' @param ids vector of individuals used for computing GRM
#' @param rsids vector marker rsids used for computing GRM
#' @param rws rows in genotype matrix used for computing GRM
#' @param cls columns in genotype matrix used for computing GRM
#' @param W matrix of centered and scaled genotypes
#' @param scale logical if TRUE the genotypes in Glist has been scaled to mean zero and variance one
#' @param method indicator of method used for computing GRM: additive (add, default), dominance (dom) or epistasis (epi-pairs or epi-hadamard (all genotype markers))
#' @param msize number of genotype markers used for batch processing
#' @param ncores number of cores used to compute the GRM
#' @param fnG name of the binary file used for storing the GRM on disk
#' @param overwrite logical if TRUE the binary file fnG will be overwritten
#' @param returnGRM logical if TRUE function returns the GRM matrix to the R environment
#' @param task either computation of GRM (task="grm"  which is default) or eigenvalue decomposition of GRM (task="eigen")
#' @param miss the missing code (miss=NA is default) used for missing values in the genotype data
#' @param impute if missing values in the genotype matrix W then mean impute
#' @param pedigree is a dataframe with pedigree information
#'
#'
#' @return Returns a genomic relationship matrix (GRM) if returnGRM=TRUE else a list structure (GRMlist) with information about the GRM  stored on disk

#' @author Peter Soerensen

#' @examples
#'
#' # Simulate data
#' W <- matrix(rnorm(1000000), ncol = 1000)
#' 	colnames(W) <- as.character(1:ncol(W))
#' 	rownames(W) <- as.character(1:nrow(W))
#'
#' # Compute GRM
#' GRM <- grm(W = W)
#'
#' \donttest{
#' 
#' # Eigen value decompostion GRM
#' eig <- grm(GRM=GRM, task="eigen")
#'
#' }

#' @export
#'

# grm <- function(Glist = NULL, GRMlist = NULL, ids = NULL, rsids = NULL, rws = NULL, cls = NULL,
#                 W = NULL, method = "add", scale = TRUE, msize = 100, ncores = 1, fnG = NULL,
#                 overwrite = FALSE, returnGRM = FALSE, miss = NA, task = "grm") {
#   if (task == "grm") {
#     GRM <- computeGRM(
#       Glist = Glist, ids = ids, rsids = rsids, rws = rws, cls = cls,
#       W = W, method = method, scale = scale, msize = msize, ncores = ncores,
#       fnG = fnG, overwrite = overwrite, returnGRM = returnGRM, miss = miss
#     )
#     return(GRM)
#   }
#   if (task == "eigen") {
#     eig <- eigenGRM(GRM = GRM, GRMlist = GRMlist, method = "default", ncores = ncores)
#     return(eig)
#   }
# }

grm <- function(Glist = NULL, GRMlist = NULL, ids = NULL, rsids = NULL, rws = NULL, cls = NULL,
                W = NULL, method = "add", scale = TRUE, msize = 100, ncores = 1, fnG = NULL,
                overwrite = FALSE, returnGRM = FALSE, miss = NA, impute=TRUE, pedigree=NULL, task = "grm") {
  if(!is.null(pedigree)) {
    return(prm(pedigree=pedigree, task="additive"))
  } 
  if (task == "grm" & is.null(pedigree)) {
    GRM <- computeGRM(
      Glist = Glist, ids = ids, rsids = rsids, rws = rws, cls = cls,
      W = W, method = method, scale = scale, msize = msize, ncores = ncores,
      fnG = fnG, overwrite = overwrite, returnGRM = returnGRM, miss = miss, impute=impute
    )
    return(GRM)
  }
  if (task == "eigen") {
    eig <- eigenGRM(GRM = GRM, GRMlist = GRMlist, method = "default", ncores = ncores)
    return(eig)
  }
}

prm <- function(pedigree=NULL, task="additive") {
  n <- nrow(pedigree)
  A <- matrix(0,ncol=n,nrow=n)
  rownames(A) <- colnames(A) <- as.character(pedigree[,1])
  A[1, 1] <- 1
  for (i in 2:n) {
    if (pedigree[i,2] == 0 && pedigree[i,3] == 0) {
      A[i, i] <- 1
      for (j in 1:(i - 1)) A[j, i] <- A[i, j] <- 0
    }
    if (pedigree[i,2] == 0 && pedigree[i,3] != 0) {
      A[i, i] <- 1
      for (j in 1:(i - 1)) A[j, i] <- A[i, j] <- 0.5 *
          (A[j, as.character(pedigree[i,3])])
    }
    if (pedigree[i,2] != 0 && pedigree[i,3] == 0) {
      A[i, i] <- 1
      for (j in 1:(i - 1)) A[j, i] <- A[i, j] <- 0.5 *
          (A[j, as.character(pedigree[i,2])])
    }
    if (pedigree[i,2] != 0 && pedigree[i,3] != 0) {
      A[i, i] <- 1 + 0.5 * (A[as.character(pedigree[i,3]), as.character(pedigree[i,2])])
      for (j in 1:(i - 1)) A[j, i] <- A[i, j] <- 0.5 *
          (A[j, as.character(pedigree[i,2])] + A[j, as.character(pedigree[i,3])])
    }
  }
  if(task=="dominance"){
    n <- ncol(A)
    D <- matrix(0,ncol=n,nrow=n)
    for(i in 1:n){
      for(j in 1:n){
        si <- pedigree[i,2]
        sj <- pedigree[j,2]
        di <- pedigree[i,3]
        dj <- pedigree[j,3]
        u1 <- ifelse(length(A[si,sj])>0,A[si,sj],0)
        u2 <- ifelse(length(A[di,dj])>0,A[di,dj],0)
        u3 <- ifelse(length(A[si,dj])>0,A[si,dj],0)
        u4 <- ifelse(length(A[sj,di])>0,A[sj,di],0)
        D[i,j] <- D[j,i] <- 0.25*(u1*u2+u3*u4)
      }
    }
    diag(D)<-1
    A<-D
    D<-NULL
  }
  return(A)
}




computeGRM <- function(Glist = NULL, ids = NULL, rsids = NULL, rws = NULL, cls = NULL, W = NULL, method = "add", scale = TRUE, msize = 100, ncores = 1, fnG = NULL, overwrite = FALSE, returnGRM = FALSE, miss = NA, impute=TRUE) {
  if (method == "add") gmodel <- 1
  if (method == "dom") gmodel <- 2
  if (method == "epi-pairs") gmodel <- 3
  if (method == "epi-hadamard") gmodel <- 4

  if (!is.null(W)) {
    #SS <- tcrossprod(W) # compute crossproduct, all SNPs
    #N <- tcrossprod(!W == miss) # compute number of observations, all SNPs
    #G <- SS / N
    if(is.na(miss)) missing <- is.na(W)
    if(is.numeric(miss)) missing <- W == miss
    W <- scale(W, scale=FALSE)
    if(any(missing)) W[missing] <- 0
    N <- tcrossprod(!missing)
    G <- tcrossprod(W)/N
    return(G)
  }
  
  if (is.null(W)) {
    n <- Glist$n
    m <- Glist$m
    nbytes <- ceiling(n / 4)

    if (is.null(cls)) cls1 <- cls2 <- 1:m
    if (is.list(cls)) {
      gmodel <- 3
      cls1 <- cls[[1]]
      cls2 <- cls[[2]]
    }
    if (is.list(rsids)) {
      gmodel <- 3
      cls1 <- match(rsids[[1]], Glist$rsids)
      cls2 <- match(rsids[[2]], Glist$rsids)
    }
    if (is.vector(rsids) & !is.list(rsids)) {
      cls1 <- cls2 <- match(rsids, Glist$rsids)
    }
    nc <- length(cls1)

    if (is.null(rws)) {
      rws <- 1:n
      if (!is.null(ids)) rws <- match(ids, Glist$ids)
    }
    nr <- length(rws)
    fnRAW <- Glist$fnRAW

    # Initiate GRMlist
    idsG <- Glist$ids[rws]
    rsidsG <- Glist$rsids[unique(c(cls1, cls2))]
    nG <- length(idsG)
    mG <- length(rsidsG)
    GRMlist <- list(fnG = fnG, idsG = idsG, rsids = rsidsG, n = nG, m = mG, method = method)

    # Initiate G file
    if (file.exists(fnG)) {
      if (!overwrite) stop("G file name allready exist")
    }
    fnG <- GRMlist$fnG
    OS <- .Platform$OS.type
    if (OS == "windows") fnRAW <- tolower(gsub("/", "\\", fnRAW, fixed = T))
    if (OS == "windows") fnG <- gsub("/", "\\", fnG, fixed = T)

    #write.table(c(as.character(fnRAW),as.character(fnG)), file = "param.qgg", quote = FALSE, sep = " ", col.names = FALSE, row.names = FALSE)
    
    res <- .Fortran("grmbed",
      n = as.integer(n),
      nr = as.integer(nr),
      rws = as.integer(rws),
      nc = as.integer(nc),
      cls1 = as.integer(cls1),
      cls2 = as.integer(cls2),
      scale = as.integer(scale),
      nbytes = as.integer(nbytes),
      fnRAWCHAR = as.integer(unlist(sapply(as.character(fnRAW),charToRaw),use.names=FALSE)),
      nchars = nchar(as.character(fnRAW)),
      msize = as.integer(msize),
      ncores = as.integer(ncores),
      fnGCHAR = as.integer(unlist(sapply(as.character(fnG),charToRaw),use.names=FALSE)),
      ncharsg = nchar(as.character(fnG)),
      gmodel = as.integer(gmodel),
      # G = matrix(as.double(0),nrow=nr,ncol=nr),
      PACKAGE = "qgg"
    )
    #file.remove("param.qgg")
    if (!returnGRM) return(GRMlist)
    if (returnGRM) {
      GRM <- getGRM(GRMlist = GRMlist, ids = GRMlist$idsG)
      return(GRM)
    }
  }
}



writeGRM <- function(GRM = NULL) {
  if (!is.null(GRM)) {
    for (i in 1:length(GRM)) {
      fileout <- file(paste("G", i, sep = ""), "wb")
      nr <- nrow(GRM[[i]])
      for (j in 1:nr) {
        writeBin(as.double(GRM[[i]][1:nr, j]), fileout, size = 8, endian = "little")
      }
      close(fileout)
    }
  }
}


#' Extract elements from genomic relationship matrix (GRM) stored on disk
#'
#' @description
#' Extract elements from genomic relationship matrix (GRM) (whole or subset) stored on disk.

#' @param GRMlist list providing information about GRM matrix stored in binary files on disk
#' @param ids vector of ids in GRM to be extracted
#' @param idsRWS vector of row ids in GRM to be extracted
#' @param idsCLS vector of column ids in GRM to be extracted
#' @param rws vector of rows in GRM to be extracted
#' @param cls vector of columns in GRM to be extracted
#' @keywords internal


#' @export
#'

getGRM <- function(GRMlist = NULL, ids = NULL, idsCLS = NULL, idsRWS = NULL, cls = NULL, rws = NULL) {

  # GRMlist(fnG=fnG,idsG=idsG,rsids=rsidsG,n=nG,m=mG)

  if (!is.null(ids)) {
    idsRWS <- idsCLS <- ids
  }
  if (!is.null(rws)) idsRWS <- GRMlist$idsG[rws]
  if (!is.null(cls)) idsCLS <- GRMlist$idsG[cls]
  if (is.null(idsRWS)) stop("Please specify ids or idsRWS and idsCLS or rws and cls")
  if (is.null(idsCLS)) stop("Please specify ids or idsRWS and idsCLS or rws and cls")

  if (sum(!idsCLS %in% GRMlist$idsG) > 0) stop("Error some ids not found in idsG")
  if (sum(!idsRWS %in% GRMlist$idsG) > 0) stop("Error some ids not found in idsG")

  rws <- match(idsRWS, GRMlist$idsG) # no reorder needed
  cls <- match(idsCLS, GRMlist$idsG)

  nG <- GRMlist$n # nG <- GRMlist$nG
  nr <- length(rws)
  nc <- length(cls)

  # Sub matrix
  G <- matrix(0, nrow = nr, ncol = nc)
  rownames(G) <- GRMlist$idsG[rws]
  colnames(G) <- GRMlist$idsG[cls]

  # If full stored project study matrix
  fileG <- file(GRMlist$fnG, "rb")
  for (i in 1:nr) {
    k <- rws[i]
    where <- (k - 1) * nG
    seek(fileG, where = where * 8)
    grws <- readBin(fileG, "double", n = nG, size = 8, endian = "little")
    G[i, ] <- grws[cls]
  }
  close(fileG)
  return(G)
}


#' Merge multiple GRMlist objects
#' 
#' @description
#' Merge multiple GRMlist objects each with information about a 
#' genomic rfelationship matrix stored on disk

#' @param GRMlist list providing information about GRM matrix stored in binary files on disk
#' @keywords internal

#' @export
#'


mergeGRM <- function(GRMlist = NULL) {
  GRMlist <- do.call(function(...) mapply(c, ..., SIMPLIFY = FALSE), args = GRMlist)
  GRMlist$idsG <- unique(GRMlist$idsG)
  GRMlist$n <- length(GRMlist$idsG)
  GRMlist$m <- length(GRMlist$rsids)
  GRMlist
}




eigenGRM <- function(GRM = NULL, GRMlist = NULL, method = "default", ncores = 1) {
  n <- ncol(GRM)
  evals <- rep(0, n)
  res <- .Fortran("eiggrm",
    n = as.integer(n),
    GRM = matrix(as.double(GRM), nrow = n, ncol = n),
    evals = as.double(evals),
    ncores = as.integer(ncores),
    PACKAGE = "qgg"
  )
  list(values = res$evals, U = res$GRM)
}
