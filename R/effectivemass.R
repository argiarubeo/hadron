effectivemass.cf <- function(cf, Thalf, type="solve", nrObs=1, replace.inf=TRUE, interval=c(0.000001,2.), 
                             weight.factor=1., deltat=1, tmax=Thalf) {
  if(missing(cf)) {
    stop("cf must be provided to effectivemass.cf! Aborting...\n")
  }
  ## cf is supposed to have nrObs*(Thalf+1) elements in time direction
  if(length(dim(cf)) == 2) {
    Cor <- apply(cf, 2, mean)
  }
  else {
    Cor <- cf
  }

  if(length(Cor) != nrObs*(tmax+1)) {
    stop("cf does not have the correct time extend in effectivemass.cf! Aborting...!\n")
  }
  ## here we generate the index arrays
  ## this is the complete index for time
  tt <- c(1:(nrObs*(tmax+1)))

  ## depending on the type, the result is not defined on all t
  ## so we have to cut
  ## this is for type "acosh", "temporal" and "shifted" where we loose t=0 and t=T/2
  cutii <- c()
  ## this is for "log" and "solve" where t=T/2 is not defined
  cutii2 <- c()

  for(i in 1:nrObs) {
    cutii <- c(cutii, (i-1)*(tmax+1)+1, i*(tmax+1))
    cutii2 <- c(cutii2, i*(tmax+1))
  }
  t2 <- tt[-cutii2]

  effMass <- rep(NA, nrObs*(tmax+1))
  if(type == "acosh" || type == "temporal" || type == "shifted" || type == "weighted") {
    t <- tt[-cutii]
    if(type == "acosh") effMass[t] <- acosh((Cor[t+1] + Cor[t-1])/2./Cor[t])
    else {
      ## we take differences to remove constant contributions from temporal states
      if(type == "shifted" || type == "weighted") Ratio <- Cor[t+1]/Cor[t]
      else Ratio <- (Cor[t]-Cor[t+1]) / (Cor[t-1]-Cor[t])
      w <- 1
      if(type == "weighted") w <- weight.factor
      ## the t-dependence needs to be modified accordingly
      fn <- function(m, t, T, Ratio, w) {
        return(Ratio - ( ( exp(-m*(t+1))+exp(-m*(T-t-1)) - w*( exp(-m*(t+1-deltat))+exp(-m*(T-(t+1-deltat))) ) ) /
                         ( exp(-m*t)+exp(-m*(T-t)) - w*( exp(-m*(t-deltat))+exp(-m*(T-(t-deltat))) ) ) ) ) 
      }
      for(i in t) {
        if(is.na(Ratio[i])) effMass[i] <- NA
        else if(fn(interval[1], t=(i %% (tmax+1)), T=2*Thalf, Ratio = Ratio[i], w=w)*fn(interval[2], t=(i %% (tmax+1)), T=2*Thalf, Ratio = Ratio[i], w=w) > 0) effMass[i] <- NA
        else effMass[i] <- uniroot(fn, interval=interval, t=(i %% (tmax+1)), T=2*Thalf, Ratio = Ratio[i], w=w)$root
      }
    }
  }
  else {
    t <- tt[c(1:(length(tt)-1))]
    Ratio <- Cor[t]/Cor[t+1]
    if(type == "log") {
      effMass[t2] <- log(Ratio[t2])
    }
    else {
      # note: for tmax > Thalf, this will produce NA
      for(t in t2) {
        effMass[t] <- invcosh(Ratio[t], timeextent=2*Thalf, t=(t %% (tmax+1)))
      }
    }
  }
  ## we replace Infs if wanted by NA
  if(replace.inf) effMass[is.infinite(effMass)] <- NA
  return(invisible(effMass[t2]))
}

bootstrap.effectivemass <- function(cf, boot.R, boot.l, seed=12345, type="solve", weight.factor = 1.) {

  if(!any(class(cf) == "cf")) {
    stop("bootstrap.effectivemass requires an object of class cf as input! Aborting!\n")
  }

  if(missing(boot.R)){
    if(cf$boot.samples){
      boot.R <- cf$boot.R
    } else {
      boot.R <- 400
    }
  }

  if(missing(boot.l)){
    if(cf$boot.samples){
      boot.l <- cf$boot.l
    } else {
      boot.l <- 20
    }
  }

  if(!cf$boot.samples || boot.R != cf$boot.R || boot.l != cf$boot.l) {
    cf <- bootstrap.cf(cf, boot.R=boot.R, boot.l=boot.l, seed=seed)
  }
  else {
    seed <- cf$seed
  }
  ## number of measurements
  N <- length(cf$cf[,1])
  if(is.null(cf$cf)) {
    N <- cf$N
  }
  deltat <- 1
  if(type == "shifted" && any(names(cf) == "deltat")) {
    deltat <- cf$deltat
  }

  ## number of time slices (hopefully in units of T/2+1 or T)
  Nt <- length(cf$cf0)
  
  tmax <- cf$Time/2
  if( "symmetrised" %in% names(cf) ) {
    if(!cf$symmetrised){
      tmax <- cf$Time-1
    }
  }
  nrObs <- floor(Nt/(tmax+1))
  ## we run on the original data first
  effMass <- effectivemass.cf(cf$cf0, Thalf=cf$Time/2, tmax=tmax, type=type, nrObs=nrObs, weight.factor=weight.factor, deltat=deltat)
  ## now we do the same on all samples
  effMass.tsboot <- t(apply(cf$cf.tsboot$t, 1, effectivemass.cf, Thalf=cf$Time/2, tmax=tmax, type=type, nrObs=nrObs, weight.factor=weight.factor, deltat=deltat))

  deffMass=apply(effMass.tsboot, 2, sd, na.rm=TRUE)
  ret <- list(t.idx=c(1:(tmax)),
              effMass=effMass, deffMass=deffMass, effMass.tsboot=effMass.tsboot,
              opt.res=NULL, t1=NULL, t2=NULL, type=type, useCov=NULL, CovMatrix=NULL, invCovMatrix=NULL,
              boot.R=boot.R, boot.l=boot.l, seed = seed, weight.factor=weight.factor,
              massfit.tsboot=NULL, Time=cf$Time, N=N, nrObs=nrObs, dof=NULL,
              chisqr=NULL, Qval=NULL
             )
  ret$cf <- cf
  ret$t0 <- effMass
  ret$t <- effMass.tsboot
  ret$se <- apply(ret$t, MARGIN=2L, FUN=sd, na.rm=TRUE)
  attr(ret, "class") <- c("effectivemass", class(ret))
  return(ret)
}

fit.effectivemass <- function(cf, t1, t2, useCov=FALSE, replace.na=TRUE, boot.fit=TRUE) {
  if(missing(cf) || !any(class(cf) == "effectivemass" )) {
    stop("cf is missing or must be of class \"effectivemass\"! Aborting...!\n")
  }
  if(missing(t1) || missing(t2)) {
    stop("t1 and t2 must be specified! Aborting...!\n")
  }
  tmax <- cf$Time/2
  if(!is.null(cf$cf$symmetrised)) {
    if(!cf$cf$symmetrised) {
      tmax <- cf$Time-1
    }
  }
  if((t2 <= t1) || (t1 < 0) || (t2 > (tmax))) {
    stop("t1 < t2 and both in 0...tmax is required, tmax depending on symmetrised or not. Aborting...\n")
  }
  else
  cf$effmassfit <- list()
  cf$t1 <- t1
  cf$effmassfit$t1 <- t1
  cf$t2 <- t2
  cf$effmassfit$t2 <- t2
  cf$useCov <- useCov
  cf$effmassfit$useCov <- useCov
  cf$replace.na <- replace.na
  cf$effmassfit$replace.na <- replace.na
  
  ## create an index array for the fit range
  ## the '+1' for Fortran index convention
  ## t1 and t2 can be in range 0-T/2
  ## if not symmetrised even in the range 0 - T-1
  ii <- c()
  for(i in 1:cf$nrObs) {
    ii <- c(ii, ((i-1)*tmax+t1+1):((i-1)*tmax+t2+1))
  }

  ## get rid of the NAs for the fit, if there are any
  if(any(is.na(cf$effMass[ii]))) {
    ii.na <- which(is.na(cf$t0[ii]))
    ii <- ii[-ii.na]
  }

  CovMatrix <- cov(cf$t[,ii])
  ## here we generate the inverse covariance matrix, if required
  ## otherwise take inverse errors squared
  M <- diag(1/cf$se[ii]^2)

  ## the chisqr function
  fn <- function(par, y, M) { sum((y-par[1]) %*% M %*% (y-par[1]))}
  
  cf$CovMatrix <- CovMatrix
  cf$effmassfit$CovMatrix <- CovMatrix
  tb.save <- cf$t
  ## now we replace all NAs by randomly chosen other bootstrap values
  ## or remove a given column if there are too many NAs to resample
  ii.remove <- c()
  if(replace.na && any(is.na(cf$t))) {
    for(k in ii) {
      cf$t[is.nan(cf$t[,k]),k] <- NA
      if(any(is.na(cf$t[,k]))) {
        ## indices of NA elements
        jj <- which(is.na(cf$t[,k]))
        ## if there are more NA elements than non-NA elements, the replacement
        ## below will fail
        if( length(cf$t[-jj, k]) > length(jj) ) {
          ## random indices in the non-NA elements of t
          rj <- sample.int(n=length(cf$t[-jj, k]), size=length(jj), replace=FALSE)
          ## replace
          cf$t[jj, k] <- cf$t[-jj, k][rj]
        }
        else {
          ## so we remove this column from the analysis below
          ii.remove <- c( ii.remove, which( ii == k ) )
        }
      }
    }
  }
  
  if( length( ii.remove ) > 0 ) {
    ## remove the columns that should be excluded from the fit below
    ii <- ii[ -ii.remove ]
    cat("Due to NAs we have removed the time slices", ii.remove-1, " from the fit\n")
  }
  cf$ii <- ii
  cf$dof <-  length(ii)-1
  cf$effmassfit$ii <- ii
  cf$effmassfit$dof <- length(ii)-1
  ## and treat the inverse covariance matrix accordingly
  if(useCov) {
    ## recompute covariance matrix and compute the correctly normalised inverse
    M <- try(invertCovMatrix(cf$t[,ii], boot.samples=TRUE), silent=TRUE)
    if(inherits(M, "try-error")) {
      M <- M[ -ii.remove, -ii.remove]
      warning("inversion of variance covariance matrix failed in bootstrap.effectivemasses during bootstrapping, continuing with uncorrelated chi^2\n")
      useCov <- FALSE
    }
  }
  else {
    if( length( ii.remove ) > 0 ) {
      ## if the matrix is diagonal, we simply restrict it
      M <- M[ -ii.remove, -ii.remove]
    }
  }

  par <- c(cf$effMass[t1])
  opt.res <- optim(par, fn = fn,
                   method="BFGS", M=M, y = cf$effMass[ii])
  opt.res <- optim(opt.res$par, fn = fn,
                   control=list(parscale=1/opt.res$par),
                   method="BFGS", M=M, y = cf$effMass[ii])
  par <- opt.res$par

  cf$chisqr <- opt.res$value
  cf$Qval <- 1-pchisq(cf$chisqr, cf$dof)
  cf$effmassfit$chisqr <- opt.res$value
  cf$effmassfit$Qval <- 1-pchisq(cf$chisqr, cf$dof)
  if( boot.fit ) {
    ## now we bootstrap the fit
    massfit.tsboot <- array(0, dim=c(cf$boot.R, 2))
    for(i in c(1:cf$boot.R)) {
      opt <- optim(par, fn = fn,
                   control=list(parscale=1/par),
                   method="BFGS", M=M, y = cf$t[i,ii])
      massfit.tsboot[i, 1] <- opt$par[1]
      massfit.tsboot[i, 2] <- opt$value
    }
    cf$massfit.tsboot <- massfit.tsboot
  }
  else {
    cf$massfit.tsboot <- NA
  } # if(boot.fit)
  cf$effmassfit$t <- cf$massfit.tsboot
  cf$effmassfit$t0 <- c(opt.res$par, opt.res$value)
  cf$effmassfit$se <-  sd(massfit.tsboot[c(1:(dim(massfit.tsboot)[1]-1)),1])
  cf$effmassfit$cf <- cf$cf
  cf$t <- tb.save

  cf$invCovMatrix <- M
  cf$opt.res <- opt.res
  cf$useCov <- useCov
  cf$effmassfit$useCov <- useCov
  attr(cf, "class") <- c("effectivemassfit", class(cf))
  return(invisible(cf))
}

summary.effectivemass <- function(effMass) {
  cat("\n ** effective mass values **\n\n")
  cat("no. measurements\t=\t", effMass$N, "\n")
  cat("boot.R\t=\t", effMass$boot.R, "\n")
  cat("boot.l\t=\t", effMass$boot.l, "\n")
  cat("Time extend\t=\t", effMass$Time, "\n")
  cat("total NA count in bootstrap samples:\t", length(which(is.na(effMass$t))), "\n")
  cat("values with errors:\n\n")
  print(data.frame(t= effMass$t.idx-1, m = effMass$t0, dm = effMass$se))
}

summary.effectivemassfit <- function(effMass, verbose=FALSE) {
  cat("\n ** Result of effective mass analysis **\n\n")
  cat("no. measurements\t=\t", effMass$N, "\n")
  cat("type\t=\t", effMass$type, "\n")
  cat("boot.R\t=\t", effMass$boot.R, "\n")
  cat("boot.l\t=\t", effMass$boot.l, "\n")
  cat("Time extend\t=\t", effMass$Time, "\n")
  cat("NA count in fitted bootstrap samples:\t", length(which(is.na(effMass$t[,effMass$ii]))),
      "(",100*length(which(is.na(effMass$t[,effMass$ii])))/ length(effMass$t[,effMass$ii]), "%)\n")
  cat("NAs replaced in fit:", effMass$effmassfit$replace.na, "\n")
  cat("time range from", effMass$effmassfit$t1, " to ", effMass$effmassfit$t2, "\n")
  cat("No correlation functions", effMass$nrObs, "\n")
  if(verbose) {
    cat("values with errors:\n\n")
    print(data.frame(t= effMass$t, m = effMass$t0, dm = effMass$se))
  }
  cat("correlated fit\t=\t", effMass$effmassfit$useCov, "\n")
  cat("m\t=\t", effMass$effmassfit$t0[1], "\n")
  cat("dm\t=\t", effMass$effmassfit$se[1], "\n")
  cat("chisqr\t=\t", effMass$effmassfit$chisqr, "\n")
  cat("dof\t=\t", effMass$effmassfit$dof, "\n")
  cat("chisqr/dof=\t",
      effMass$effmassfit$chisqr/effMass$effmassfit$dof, "\n")
  cat("Quality of the fit (p-value):",   effMass$effmassfit$Qval, "\n")

}

print.effectivemassfit <- function(effMass, verbose=FALSE) {
  summary(effMass, verbose=verbose)
}

plot.effectivemass <- function(effMass, ref.value, col,...) {
  if(missing(col)) {
    col <- c("black", rainbow(n=(effMass$nrObs-1)))
  }
  op <- options()
  options(warn=-1)
  # BaKo: is this also valid for acosh type effective masses?
  t <- effMass$t.idx
  plotwitherror(x=t-1, y=effMass$effMass[t], dy=effMass$deffMass[t], col=col[1], ...)
  if(effMass$nrObs > 1) {
    for(i in 1:(effMass$nrObs-1)) {
      plotwitherror(x=t-1, y=effMass$t0[t+i*length(t)], dy=effMass$se[t+i*length(t)], rep=TRUE, col=col[i+1], ...)
    }
  }
  options(op)
  if(!missing(ref.value)) {
    abline(h=ref.value, col=c("darkgreen"), lwd=c(3))
  }
  if(!is.null(effMass$effmassfit)){
    lines(x=c(effMass$t1,effMass$t2),
          y=c(effMass$effmassfit$t0[1],effMass$effmassfit$t0[1]),
          col=col[1],
          lwd=1.3)
      pcol <- col2rgb(col[1],alpha=TRUE)/255                                                                                                   
      pcol[4] <- 0.65
      pcol <- rgb(red=pcol[1],green=pcol[2],blue=pcol[3],alpha=pcol[4])
      rect(xleft=effMass$t1, ybottom=effMass$effmassfit$t0[1]-effMass$effmassfit$se[1],
           xright=effMass$t2, ytop=effMass$effmassfit$t0[1]+effMass$effmassfit$se[1],
           col=pcol,
           border=NA)
  }
}
