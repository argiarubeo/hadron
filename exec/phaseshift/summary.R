library(plotrix)
load(paste("res.", pc, ".", TP, ".Rdata", sep=""))

replace.outliers <- function(x, lh, rh) {
  x[which(x < lh | x > rh)] <- NA
  return(x)
}


compute.weights <- function(err, pvalues) {
##  return(1./pvalues^2)
  return(pvalues^2 * min(err, na.rm=TRUE)^2/err^2)
}

ii <- which(dim(res) == 1)-1
jj <- c(2,3)
if(length(ii) > 0) {
  jj <- jj[-ii]
}
if(length(jj) == 0) {
  stop("only one fit range combination?\n")
}

## remove outliers 
lh <- quantile(res[,,,3], probs=0.25, na.rm=TRUE)
rh <- quantile(res[,,,3], probs=0.75, na.rm=TRUE)
step<- 1.5 * (rh-lh)
res[,,,3] <- apply(res[,,,3], jj, replace.outliers, lh=lh-step, rh=rh+step)

## this is the naive statistical uncertainty
err <- as.vector(apply(res[,,,3]/res[,,,5], jj, sd, na.rm=TRUE))
## p-values
pvalues <- as.vector((1-2*abs(res[1,,,7]-0.5)) * (1-2*abs(res[1,,,8]-0.5)))
## weights
w <- compute.weights(err, pvalues)

qcotdeltaovmpi <- weighted.quantile(as.vector(res[1,,,3]/res[1,,,5]), prob=c(0.5), w=w, na.rm=TRUE)
if(any(is.na(as.vector(res[1,,,3]/res[1,,,5])))) {
  weighted.hist(as.vector(res[1,,,3]/res[1,,,5])[-which(is.na(as.vector(res[1,,,3]/res[1,,,5])))], w=w[-which(is.na(as.vector(res[1,,,3]/res[1,,,5])))], main="qcotdeltaovmpi")
}
if(!any(is.na(as.vector(res[1,,,3]/res[1,,,5])))) {
  weighted.hist(as.vector(res[1,,,3]/res[1,,,5]), w=w, main="qcotdeltaovmpi")
}
## statistical error
qcotdeltaovmpi[2] <- sd(apply(res[,,,3]/res[,,,5], 1, weighted.quantile, prob=c(0.5), w=w, na.rm=TRUE), na.rm=TRUE)
## systematic error
## lower and upper
qcotdeltaovmpi[c(3:4)] <- weighted.quantile(as.vector(res[1,,,3]/res[1,,,5]), w=w, prob=c(0.1573, 0.8427), na.rm=TRUE)-qcotdeltaovmpi[1]

## this is the naive statistical uncertainty
err <- as.vector(apply(res[,,,3], jj, sd, na.rm=TRUE))
## weights
w <- compute.weights(err, pvalues)

qcotdelta <- weighted.quantile(as.vector(res[1,,,3]), w=w, prob=c(0.5), na.rm=TRUE)
if(any(is.na(as.vector(res[1,,,3])))) {
  weighted.hist(as.vector(res[1,,,3])[-which(is.na(as.vector(res[1,,,3])))], w=w[-which(is.na(as.vector(res[1,,,3])))], main="qcotdelta")
}
if(!any(is.na(as.vector(res[1,,,3])))) {
  weighted.hist(as.vector(res[1,,,3]), w=w, main="qcotdelta")
}
## statistical error
qcotdelta[2] <- sd(apply(res[,,,3], 1, weighted.quantile, w=w, prob=c(0.5), na.rm=TRUE), na.rm=TRUE)
## systematic error
## lower and upper
qcotdelta[c(3:4)] <- weighted.quantile(as.vector(res[1,,,3]), w=w, prob=c(0.1573, 0.8427), na.rm=TRUE)-qcotdelta[1]

## this is the statistical uncertainty
err <- as.vector(apply(res[,,,1]/res[,,,5]^2, jj, sd, na.rm=TRUE))
## q^2/mpi^2
w <- compute.weights(err, pvalues)

qsqovmpisq <- weighted.quantile(as.vector(res[1,,,1]/res[1,,,5]^2), w=w, prob=c(0.5), na.rm=TRUE)
if(any(is.na(as.vector(res[1,,,1]/res[1,,,5]^2)))) {
  weighted.hist(as.vector(res[1,,,1]/res[1,,,5]^2)[-which(is.na(as.vector(res[1,,,1]/res[1,,,5]^2)))], w=w[-which(is.na(as.vector(res[1,,,1]/res[1,,,5]^2)))], main="qsovmpisq")
}
if(!any(is.na(as.vector(res[1,,,1]/res[1,,,5]^2)))) {
  weighted.hist(as.vector(res[1,,,1]/res[1,,,5]^2), w=w, main="qsovmpisq")
}
##qsqovmpisq.statd
qsqovmpisq[2] <- sd(apply(res[,,,1]/res[,,,5]^2, 1, weighted.quantile, w=w, prob=c(0.5), na.rm=TRUE), na.rm=TRUE)
qsqovmpisq[c(3:4)] <- weighted.quantile(as.vector(res[1,,,1]/res[1,,,5]^2), w=w, prob=c(0.1573, 0.8427), na.rm=TRUE)-qsqovmpisq[1]

## this is the statistical uncertainty
err <- as.vector(apply(res[,,,1], jj, sd, na.rm=TRUE))
## q^2/mpi^2
w <- compute.weights(err, pvalues)

qsq <- weighted.quantile(as.vector(res[1,,,1]), w=w, prob=c(0.5), na.rm=TRUE)
if(any(is.na(as.vector(res[1,,,1])))) {
  weighted.hist(as.vector(res[1,,,1])[-which(is.na(as.vector(res[1,,,1])))], w=w[-which(is.na(as.vector(res[1,,,1])))], main="qsq")
}
if(!any(is.na(as.vector(res[1,,,1])))) {
  weighted.hist(as.vector(res[1,,,1]), w=w, main="qsq")
}
##qsqovmpisq.statd
qsq[2] <- sd(apply(res[,,,1], 1, weighted.quantile, w=w, prob=c(0.5), na.rm=TRUE), na.rm=TRUE)
qsq[c(3:4)] <- weighted.quantile(as.vector(res[1,,,1]), w=w, prob=c(0.1573, 0.8427), na.rm=TRUE)-qsq[1]

## this is the statistical uncertainty
err <- as.vector(apply(sqrt(res[,,,1]), jj, sd, na.rm=TRUE))
## q^2/mpi^2
w <- compute.weights(err, pvalues)

q <- weighted.quantile(as.vector(sqrt(res[1,,,1])), w=w, prob=c(0.5), na.rm=TRUE)
if(any(is.na(as.vector(sqrt(res[1,,,1]))))) {
  weighted.hist(as.vector(sqrt(res[1,,,1]))[-which(is.na(as.vector(sqrt(res[1,,,1]))))], w=w[-which(is.na(as.vector(sqrt(res[1,,,1]))))], main="q")
}
if(!any(is.na(as.vector(res[1,,,1])))) {
  weighted.hist(as.vector(sqrt(res[1,,,1])), w=w, main="q")
}
##qsqovmpisq.statd
q[2] <- sd(apply(sqrt(res[,,,1]), 1, weighted.quantile, w=w, prob=c(0.5), na.rm=TRUE), na.rm=TRUE)
q[c(3:4)] <- weighted.quantile(as.vector(sqrt(res[1,,,1])), w=w, prob=c(0.1573, 0.8427), na.rm=TRUE)-q[1]


## this is the statistical uncertainty
err <- as.vector(apply(res[,,,4], jj, sd, na.rm=TRUE))
#delta
w <- compute.weights(err, pvalues)

delta <- weighted.quantile(as.vector(res[1,,,4]), w=w, prob=c(0.5), na.rm=TRUE)
if(any(is.na(as.vector(res[1,,,4])))) {
  weighted.hist(as.vector(res[1,,,4])[-which(is.na(as.vector(res[1,,,4])))], w=w[-which(is.na(as.vector(res[1,,,4])))], main="delta")
}
if(!any(is.na(as.vector(res[1,,,4])))) {
  weighted.hist(as.vector(res[1,,,4]), w=w, main="delta")
}
delta[2] <- sd(apply(res[,,,4], 1, weighted.quantile, w=w, prob=c(0.5), na.rm=TRUE), na.rm=TRUE)
delta[c(3,4)] <- weighted.quantile(as.vector(res[1,,,4]), w=w, prob=c(0.1573, 0.8427), na.rm=TRUE)-delta[1]

err <- as.vector(apply(res[,,,5], jj, sd, na.rm=TRUE))
w <- compute.weights(err, pvalues)

Epi <- weighted.quantile(as.vector(res[1,,,5]), w=w, prob=c(0.5), na.rm=TRUE)
if(any(is.na(as.vector(res[1,,,5])))) {
  weighted.hist(as.vector(res[1,,,5])[-which(is.na(as.vector(res[1,,,5])))], w=w[-which(is.na(as.vector(res[1,,,5])))], main="Epi")
}
if(!any(is.na(as.vector(res[1,,,5])))) {
  weighted.hist(as.vector(res[1,,,5]), w=w, main="Epi")
}
Epi[2] <- sd(apply(res[,,,5], 1, weighted.quantile, w=w, prob=c(0.5), na.rm=TRUE), na.rm=TRUE)
Epi[c(3,4)] <- weighted.quantile(as.vector(res[1,,,5]), w=w, prob=c(0.1573, 0.8427), na.rm=TRUE)-Epi[1]

err <- as.vector(apply(res[,,,6], jj, sd, na.rm=TRUE))
w <- compute.weights(err, pvalues)

Epipi <- weighted.quantile(as.vector(res[1,,,6]), w=w, prob=c(0.5), na.rm=TRUE)
if(any(is.na(as.vector(res[1,,,6])))) {
  weighted.hist(as.vector(res[1,,,6])[-which(is.na(as.vector(res[1,,,6])))], w=w[-which(is.na(as.vector(res[1,,,6])))], main="Epipi")
}
if(!any(is.na(as.vector(res[1,,,6])))) {
  weighted.hist(as.vector(res[1,,,6]), w=w, main="Epipi")
}
Epipi[2] <- sd(apply(res[,,,6], 1, weighted.quantile, w=w, prob=c(0.5), na.rm=TRUE), na.rm=TRUE)
Epipi[c(3,4)] <- weighted.quantile(as.vector(res[1,,,6]), w=w, prob=c(0.1573, 0.8427), na.rm=TRUE)-Epipi[1]

rm(w, res)
