% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ga_data_order.R
\name{ga_data_order}
\alias{ga_data_order}
\title{Order DSL for GA4 OrderBy}
\usage{
ga_data_order(
  x,
  type = c("ALPHANUMERIC", "CASE_INSENSITIVE_ALPHANUMERIC", "NUMERIC")
)
}
\arguments{
\item{x}{Order DSL enabled syntax}

\item{type}{Order Type}
}
\value{
A list of \code{OrderBy} objects suitable for use in \link{ga_data}
}
\description{
Use with \link{ga_data} to create orderBys
}
\details{
The DSL rules are:

\itemize{
\item{Fields can be quoted or unquoted.  If unquoted they will be validated}
\item{Use + as a prefix to indicate ascending order e.g. \code{+sessions}}
\item{Use - as a prefix to indicate decreasing order e.g. \code{-sessions}}
\item{Combine order fields without commas e.g. \code{+sessions -city}}
\item{Ordering of dimensions can also specify a type of ordering: ALPHANUMERIC, CASE_INSENSITIVE_ALPHANUMERIC, NUMERIC}
}

The dimension ordering have these effects:

\itemize{
\item{ALPHANUMERIC - For example, "2" < "A" < "X" < "b" < "z"}
\item{CASE_INSENSITIVE_ALPHANUMERIC - Case insensitive alphanumeric sort by lower case Unicode code point. For example, "2" < "A" < "b" < "X" < "z"}
\item{NUMERIC - Dimension values are converted to numbers before sorting. For example in NUMERIC sort, "25" < "100", and in ALPHANUMERIC sort, "100" < "25". Non-numeric dimension values all have equal ordering value below all numeric values}
}
}
\examples{


# session in descending order
ga_data_order(-sessions)

# city dimension in ascending alphanumeric order
ga_data_order(+city)

# as above plus sessions in descending order
ga_data_order(+city -sessions)

# as above plus activeUsers in ascending order
ga_data_order(+city -sessions +activeUsers)

# dayOfWeek dimension in ascending numeric order
ga_data_order(+dayOfWeek, type = "NUMERIC")

# you can also combine them with c()
a <- ga_data_order(-sessions)
b <- ga_data_order(-dayOfWeek, type = "NUMERIC")
c(a, b)

\dontrun{
# example of use
ga_data(
  206670707,
  metrics = c("activeUsers","sessions"),
  dimensions = c("date","city","dayOfWeek"),
  date_range = c("2020-03-31", "2020-04-27"),
  orderBys = ga_data_order(-sessions -dayOfWeek)
  )


}


}
\seealso{
\url{https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1alpha/OrderBy}

Other GA4 functions: 
\code{\link{ga_data}()},
\code{\link{ga_data_filter}()}
}
\concept{GA4 functions}
