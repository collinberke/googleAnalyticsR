% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/filter_management.R
\name{ga_filter_update}
\alias{ga_filter_update}
\title{Updates an existing filter.}
\usage{
ga_filter_update(Filter, accountId, filterId, method = c("PUT", "PATCH"))
}
\arguments{
\item{Filter}{The Filter object to be updated
See examples from ga_filter_add()}

\item{accountId}{Account Id of the account that contains the filter}

\item{filterId}{The id of the filter to be modified}

\item{method}{PUT by default. For patch semantics use PATCH}
}
\value{
A filterManagement object
}
\description{
Updates an existing filter.
}
\examples{

\dontrun{

# create a filter object
Filter <- list(
    name = 'googleAnalyticsR test1: Exclude Internal Traffic',
    type = 'EXCLUDE',
    excludeDetails = list(
                      field = 'GEO_IP_ADDRESS',
                      matchType = 'EQUAL',
                      expressionValue = '199.04.123.1',
                      caseSensitive = 'False'
                      )
                 )
 # add a filter (but don't link to a View)               
 filterId <- ga_filter_add(Filter, 
                           accountId = 123456, 
                           linkFilter = FALSE)
 
 # change the name of the filter                    
 change_name <- "googleAnalyticsR test2: Changed name via PATCH"
 
 # using PATCH semantics, only need to construct what you want to change
 filter_to_update <- list(name = test_name)
 
 # update the filter using the filterId 
 ga_filter_update(filter_to_update, accountId2, filterId, method = "PATCH")

}

}
\seealso{
\url{https://developers.google.com/analytics/devguides/config/mgmt/v3/mgmtReference/#Filters}

Other managementAPI functions: 
\code{\link{ga_experiment}()},
\code{\link{ga_experiment_list}()},
\code{\link{ga_filter_add}()},
\code{\link{ga_filter_apply_to_view}()},
\code{\link{ga_filter_update_filter_link}()},
\code{\link{ga_segment_list}()}
}
\concept{managementAPI functions}
