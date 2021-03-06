% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read.rdf2.R
\name{read.rdf2}
\alias{read.rdf2}
\title{Read an rdf file into R.}
\usage{
read.rdf2(iFile)
}
\arguments{
\item{iFile}{The input rdf file that will be read into R.}
}
\value{
A multi-level list containing all metadata and slot data in the original rdf file.
}
\description{
\code{read.rdf2} reads an rdf file into R and formats it as a multi-level list containing
all of the metadata included in the rdf file.  Rdf files are generated by RiverWare
and are documented in the \href{http://riverware.org/PDF/RiverWare/documentation/}{RiverWare documentation}.
}
\details{
\code{read.rdf2} is faster than \code{read.rdf} since it uses \code{data.table::fread}
to read in the file. Two versions will be maintained for a while to ensure they 
behave identically.
}
\examples{
zz <- read.rdf2(system.file('extdata/Scenario/DNF,CT,IG', "KeySlots.rdf", package = "RWDataPlot"))

}

