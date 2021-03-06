% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/aggregations.R
\name{getMinAnnValue}
\alias{getMinAnnValue}
\title{Find the minimum annual value for all years and traces.}
\usage{
getMinAnnValue(xx)
}
\arguments{
\item{xx}{A matrix (months by traces) such as that returned by \code{\link{rdfSlotToMatrix}}.
Will error if the number of rows in xx is not divisible by 12, i.e., the data must be monthly
for a full consecutive year.}
}
\value{
A matrix (years by traces) with the maximum annual value for each year and trace.
}
\description{
Find the minimum annual value for all years and traces.
}
\examples{
pe <- rdfSlotToMatrix(keyRdf,'Powell.Pool Elevation')
peMax <- getMinAnnValue(pe)
}
\seealso{
\code{\link{getMaxAnnValue}}
\code{\link{rdfSlotToMatrix}}
}

