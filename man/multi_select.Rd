% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/shiny-modules.R
\name{multi_select}
\alias{multi_select}
\title{multi_select Shiny Module}
\usage{
multi_select(
  input,
  output,
  session,
  type = c("METRIC", "DIMENSION"),
  subType = c("all", "segment", "cohort"),
  default = NULL
)
}
\arguments{
\item{input}{shiny input}

\item{output}{shiny output}

\item{session}{shiny session}

\item{type}{metric or dimension}

\item{subType}{Limit selections to those relevant}

\item{default}{The default selected choice. First element if NULL}
}
\value{
the selected variable
}
\description{
Shiny Module for use with \link{multi_selectUI}
}
\details{
Call via \code{shiny::callModule(multi_select, "your_id")}
}
\seealso{
Other Shiny modules: 
\code{\link{accountPickerUI}()},
\code{\link{authDropdown}()},
\code{\link{authDropdownUI}()},
\code{\link{metricDimensionSelectUI}()},
\code{\link{multi_selectUI}()}
}
\concept{Shiny modules}
