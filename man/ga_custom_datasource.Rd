% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/custom_data_source.R
\name{ga_custom_datasource}
\alias{ga_custom_datasource}
\title{List Custom Data Sources}
\usage{
ga_custom_datasource(accountId, webPropertyId)
}
\arguments{
\item{accountId}{Account Id}

\item{webPropertyId}{Web Property Id}
}
\value{
Custom Data Source
}
\description{
Get a list of custom data sources you have configured in Google Analytics web UI.
}
\details{
You primarily need this to get the \code{customDataSourceId} for the uploads via \link{ga_custom_upload_file}
}
\seealso{
Other custom datasource functions: 
\code{\link{ga_custom_upload}()},
\code{\link{ga_custom_upload_delete}()},
\code{\link{ga_custom_upload_file}()},
\code{\link{ga_custom_upload_list}()}
}
\concept{custom datasource functions}
