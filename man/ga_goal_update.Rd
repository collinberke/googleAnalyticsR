% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/goal_management.R
\name{ga_goal_update}
\alias{ga_goal_update}
\title{Updates an existing goal.}
\usage{
ga_goal_update(
  Goal,
  accountId,
  webPropertyId,
  viewId,
  goalId,
  method = c("PUT", "PATCH")
)
}
\arguments{
\item{Goal}{The Goal object to be updated
See examples from ga_goal_add()}

\item{accountId}{Account Id of the account in which to modify the Goal}

\item{webPropertyId}{Property Id of the property in which to modify the Goal}

\item{viewId}{View Id of the view in which to modify the Goal}

\item{goalId}{The id of the goal to be modified}

\item{method}{PUT by default. For patch semantics use PATCH}
}
\value{
A goalManagement object
}
\description{
Updates an existing goal.
}
\examples{

\dontrun{

# Change the goal 11 to visits over 3 minutes
Goal <- list(
  active = TRUE,
  name = 'Stayed for more than 3 minutes',
  type = 'VISIT_TIME_ON_SITE',
  visitTimeOnSiteDetails = list(
    comparisonType = 'GREATER_THAN',
    comparisonValue = 180
  )
)
ga_goal_update(Goal, accountId, propertyId, viewId, 11)

# Change destination url for goal 17
Goal <- list(
    urlDestinationDetails = list(
      url = '\\\\/checkout\\\\/success'
    )
  )

# Only the fields we're changing required because we're using PATCH method  
ga_goal_update(Goal, accountId, propertyId, viewId, 17, method = "PATCH")
  
}
  
}
\seealso{
\url{https://developers.google.com/analytics/devguides/config/mgmt/v3/mgmtReference/#Goals}

Other goal management functions: 
\code{\link{ga_goal}()},
\code{\link{ga_goal_add}()},
\code{\link{ga_goal_list}()}
}
\concept{goal management functions}
