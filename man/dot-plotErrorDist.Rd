% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/productivityAnalysis.R
\name{.plotErrorDist}
\alias{.plotErrorDist}
\title{Plots the error distribution for each region: CDRs, FRs, IGV, IGD, and IGJ}
\usage{
.plotErrorDist(productivityDirectories, prodOut, sampleNames,
  combinedNames, mashedNames, .save = TRUE)
}
\arguments{
\item{productivityDirectories}{list type. List of directories}

\item{prodOut}{string type. Output directory}

\item{sampleNames}{vector type. 1-1 with productivity directories}

\item{combinedNames}{string type. Title friendly "combined" sample names}

\item{mashedNames}{string type. File friendly "mashed-up" sample names}

\item{.save}{logical type. Save Rdata?}
}
\value{
None
}
\description{
Plots the distribution of indels (gaps), indels in
out-of-frame sequences, and the distribution of mismatches for CDRs,
FRs, IGV, IGD, and IGJ.
}
