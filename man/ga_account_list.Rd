% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/accounts.R
\name{ga_account_list}
\alias{ga_account_list}
\title{Account summary for all accounts available to your user}
\usage{
ga_account_list(type = c("universal", "ga4", "data"))
}
\arguments{
\item{type}{Whether to get account summary from universal analytics of GA4 (App_Web) properties}
}
\value{
a dataframe of all account, webproperty and view data
}
\description{
This is the recommended way to get all your account details for your user, including the web property and View IDs.  The \verb{$viewId} column contains the ID you need for the data fetching functions such as \link{google_analytics}.
}
\details{
Get a summary of all your accounts, web properties and views your authenticated user can see.
}
\examples{

\dontrun{

library(googleAnalyticsR)
ga_auth()
al <- ga_account_list()
al$viewId

## get account summary of GA4 properties
ga_account_list("ga4")
}
}
\seealso{
https://developers.google.com/analytics/devguides/config/mgmt/v3/mgmtReference/management/accountSummaries/list

Other account structure functions: 
\code{\link{ga_accounts}()},
\code{\link{ga_view}()},
\code{\link{ga_view_list}()},
\code{\link{ga_webproperty}()},
\code{\link{ga_webproperty_list}()}
}
\concept{account structure functions}
