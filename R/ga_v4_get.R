#' Make a Google Analytics v4 API fetch
#' 
#' @description
#'   This function constructs the Google Analytics API v4 call to be called
#'   via [fetch_google_analytics_4]
#'
#' @param viewId viewId of data to get.
#' @param date_range character or date vector of format `c(start, end)` or 
#'   for two date ranges: `c(start1,end1,start2,end2)`
#' @param metrics Metric(s) to fetch as a character vector.  You do not need to 
#'   supply the `"ga:"` prefix.  See [meta] for a list of dimensons 
#'   and metrics the API supports. Also supports your own calculated metrics.
#' @param dimensions Dimension(s) to fetch as a character vector. You do not need to 
#'   supply the `"ga:"` prefix. See [meta] for a list of dimensons 
#'   and metrics the API supports.
#' @param dim_filters A [filter_clause_ga4] wrapping [dim_filter]
#' @param met_filters A [filter_clause_ga4] wrapping [met_filter]
#' @param filtersExpression A v3 API style simple filter string. Not used with other filters. 
#' @param order An [order_type] object
#' @param segments List of segments as created by [segment_ga4]
#' @param pivots Pivots of the data as created by [pivot_ga4]
#' @param cohorts Cohorts created by [make_cohort_group]
#' @param pageToken Where to start the data fetch
#' @param pageSize How many rows to fetch. Max 100000 each batch.
#' @param samplingLevel Sample level
#' @param metricFormat If supplying calculated metrics, specify the metric type
#' @param histogramBuckets For numeric dimensions such as hour, a list of buckets of data.
#'   See details in [make_ga_4_req]
#'
#' @section Metrics:
#'   Metrics support calculated metrics like ga:users / ga:sessions if you supply
#'   them in a named vector.
#'
#'   You must supply the correct 'ga:' prefix unlike normal metrics
#'
#'   You can mix calculated and normal metrics like so:
#'
#'   `customMetric <- c(sessionPerVisitor = "ga:sessions / ga:visitors",
#'                           "bounceRate",
#'                           "entrances")`
#'
#'    You can also optionally supply a `metricFormat` parameter that must be
#'    the same length as the metrics.  `metricFormat` can be:
#'    `METRIC_TYPE_UNSPECIFIED, INTEGER, FLOAT, CURRENCY, PERCENT, TIME`
#'
#'    All metrics are currently parsed to as.numeric when in R.
#'
#' @section Dimensions:
#'
#'   Supply a character vector of dimensions, with or without `ga:` prefix.
#'
#'   Optionally for numeric dimension types such as
#'   `ga:hour, ga:browserVersion, ga:sessionsToTransaction`, etc. supply
#'   histogram buckets suitable for histogram plots.
#'
#'   If non-empty, we place dimension values into buckets after string to int64.
#'   Dimension values that are not the string representation of an integral value
#'   will be converted to zero. The bucket values have to be in increasing order.
#'   Each bucket is closed on the lower end, and open on the upper end.
#'   The "first" bucket includes all values less than the first boundary,
#'   the "last" bucket includes all values up to infinity.
#'   Dimension values that fall in a bucket get transformed to a new dimension
#'   value. For example, if one gives a list of "0, 1, 3, 4, 7", then we
#'   return the following buckets: -
#' \itemize{
#'   \item bucket #1: values < 0, dimension value "<0"
#'   \item bucket #2: values in [0,1), dimension value "0"
#'   \item bucket #3: values in [1,3), dimension value "1-2"
#'   \item bucket #4: values in [3,4), dimension value "3"
#'   \item bucket #5: values in [4,7), dimension value "4-6"
#'   \item bucket #6: values >= 7, dimension value "7+"
#'  }
#'  
#' @examples 
#' 
#' \dontrun{
#' library(googleAnalyticsR)
#' 
#' ## authenticate, 
#' ## or use the RStudio Addin "Google API Auth" with analytics scopes set
#' ga_auth()
#' 
#' ## get your accounts
#' account_list <- ga_account_list()
#' 
#' ## pick a profile with data to query
#' 
#' ga_id <- account_list[23,'viewId']
#' 
#' ga_req1 <- make_ga_4_req(ga_id, 
#'                          date_range = c("2015-07-30","2015-10-01"),
#'                          dimensions=c('source','medium'), 
#'                          metrics = c('sessions'))
#' 
#' ga_req2 <- make_ga_4_req(ga_id, 
#'                          date_range = c("2015-07-30","2015-10-01"),
#'                          dimensions=c('source','medium'), 
#'                          metrics = c('users'))
#'                          
#' fetch_google_analytics_4(list(ga_req1, ga_req2))
#' 
#' }
#' 
#' 
#' @family GAv4 fetch functions
#' @import assertthat
#' @noRd
make_ga_4_req <- function(viewId,
                          date_range=NULL,
                          metrics=NULL,
                          dimensions=NULL,
                          dim_filters=NULL,
                          met_filters=NULL,
                          filtersExpression=NULL,
                          order=NULL,
                          segments=NULL,
                          pivots=NULL,
                          cohorts=NULL,
                          pageToken=0,
                          pageSize=1000,
                          samplingLevel=c("DEFAULT", "SMALL","LARGE"),
                          metricFormat=NULL,
                          histogramBuckets=NULL) {

  samplingLevel <- match.arg(samplingLevel)

  if(!is.dim_filter_clause(dim_filters)){
    assert_that_ifnn(dim_filters, is.dim_filter)
  }
  
  if(!is.met_filter_clause(met_filters)){
    assert_that_ifnn(met_filters, is.met_filter)
  }
  
  assert_that_ifnn(filtersExpression, is.string)
  
  if(all(is.null(date_range), is.null(cohorts))){
    stop("Must supply one of date_range or cohorts", call. = FALSE)
  }
  
  if(!is.null(cohorts)){
    assert_that(cohort_metric_check(metrics),
                cohort_dimension_check(dimensions))
    if(!is.null(date_range)){
      stop("Don't supply date_range when using cohorts", 
              call. = FALSE)
    }
  }
  
  if(is.null(metrics)){
    stop("Must supply a metric", call. = FALSE)
  }
  
  if(!is.null(segments)){
    if(!any("segment" %in% dimensions)){
      dimensions <- c(dimensions, "segment")
    }
  }

  id <- sapply(viewId, checkPrefix, prefix = "ga")

  date_list_one <- date_ga4(date_range[1:2])
  if(length(date_range) == 4){
    date_list_two <- date_ga4(date_range[3:4])
  } else {
    date_list_two <- NULL
  }

  dim_list <- dimension_ga4(dimensions, histogramBuckets)
  met_list <- metric_ga4(metrics, metricFormat)

  # order the dimensions if histograms
  if(all(is.null(order), !is.null(histogramBuckets))){
    bys <- intersect(dimensions, names(histogramBuckets))
    order <- lapply(bys,
                       order_type,
                       FALSE,
                       "HISTOGRAM_BUCKET")
  }


  request <-
    structure(
      list(
        viewId = id,
        dateRanges = list(
          date_list_one,
          date_list_two
        ),
        samplingLevel = samplingLevel,
        dimensions = dim_list,
        metrics = met_list,
        dimensionFilterClauses = dim_filters,
        metricFilterClauses = met_filters,
        filtersExpression = filtersExpression,
        orderBys = order,
        segments = segments,
        pivots = pivots,
        cohortGroup=cohorts,
        pageToken=as.character(pageToken),
        pageSize = pageSize,
        includeEmptyRows = TRUE
      ),
      class = "ga4_req")


  request <- rmNullObs(request)

}



#' Get Google Analytics v4 data
#' 
#' @description
#' Fetch Google Analytics data using the v4 API.  For the v3 API use [google_analytics_3], for GA4's Data API use [ga_data].  See website help for lots of examples: [Google Analytics Reporting API v4 in R](https://8-bit-sheep.com/googleAnalyticsR/articles/v4.html)
#' 
#' 
#' @section Row requests:
#' 
#' By default the API call will use v4 batching that splits requests into 5 separate calls of 10k rows each.  This can go up to 100k, so this means up to 500k rows can be fetched per API call, however the API servers will fail with a 500 error if the query is too complicated as the processing time at Google's end gets too long.  In this case, you may want to tweak the `rows_per_call` argument downwards, or fall back to using `slow_fetch = FALSE` which will send an API request one at a time.  If fetching data via scheduled scripts this is recommended as the default.
#' 
#' 
#' @section Anti-sampling:
#' 
#' `anti_sample` being TRUE ignores `max` as the API call is split over days 
#'   to mitigate the sampling session limit, in which case a row limit won't work.  Take the top rows
#'   of the result yourself instead e.g. `head(ga_data_unsampled, 50300)`
#'   
#' `anti_sample` being TRUE will also set `samplingLevel='LARGE'` to minimise 
#'   the number of calls.
#' 
#' @section Resource Quotas:
#' 
#' If you are on GA360 and have access to resource quotas,
#'   set the `useResourceQuotas=TRUE` and set the Google Cloud 
#'   client ID to the project that has resource quotas activated, 
#'   via [gar_set_client][googleAuthR::gar_set_client] or options.
#'   
#' @section Caching:
#' 
#' By default local caching is turned on for v4 API requests.  This means that
#'   making the same request as one this session will read from memory and not
#'   make an API call. You can also set the cache to disk via 
#'   the [ga_cache_call] function.  This can be useful
#'   when running RMarkdown reports using data.
#' 
#' @section Metrics:
#'   Metrics support calculated metrics like ga:users / ga:sessions if you supply
#'   them in a named vector.
#'
#'   You must supply the correct 'ga:' prefix unlike normal metrics
#'
#'   You can mix calculated and normal metrics like so:
#'
#'   `customMetric <- c(sessionPerVisitor = "ga:sessions / ga:visitors",
#'                           "bounceRate",
#'                           "entrances")`
#'
#'    You can also optionally supply a `metricFormat` parameter that must be
#'    the same length as the metrics.  `metricFormat` can be:
#'    `METRIC_TYPE_UNSPECIFIED, INTEGER, FLOAT, CURRENCY, PERCENT, TIME`
#'
#'    All metrics are currently parsed to as.numeric when in R.
#'
#' @section Dimensions:
#'
#'   Supply a character vector of dimensions, with or without `ga:` prefix.
#'
#'   Optionally for numeric dimension types such as
#'   `ga:hour, ga:browserVersion, ga:sessionsToTransaction`, etc. supply
#'   histogram buckets suitable for histogram plots.
#'
#'   If non-empty, we place dimension values into buckets after string to int64.
#'   Dimension values that are not the string representation of an integral value
#'   will be converted to zero. The bucket values have to be in increasing order.
#'   Each bucket is closed on the lower end, and open on the upper end.
#'   The "first" bucket includes all values less than the first boundary,
#'   the "last" bucket includes all values up to infinity.
#'   Dimension values that fall in a bucket get transformed to a new dimension
#'   value. For example, if one gives a list of "0, 1, 3, 4, 7", then we
#'   return the following buckets: -
#' \itemize{
#'   \item bucket #1: values < 0, dimension value "<0"
#'   \item bucket #2: values in [0,1), dimension value "0"
#'   \item bucket #3: values in [1,3), dimension value "1-2"
#'   \item bucket #4: values in [3,4), dimension value "3"
#'   \item bucket #5: values in [4,7), dimension value "4-6"
#'   \item bucket #6: values >= 7, dimension value "7+"
#'  }
#' 
#' @param viewId viewId of data to get.
#' @param date_range character or date vector of format `c(start, end)` or 
#'   for two date ranges: `c(start1,end1,start2,end2)`
#' @param metrics Metric(s) to fetch as a character vector.  You do not need to 
#'   supply the `"ga:"` prefix.  See [meta] for a list of dimensons 
#'   and metrics the API supports. Also supports your own calculated metrics.
#' @param dimensions Dimension(s) to fetch as a character vector. You do not need to 
#'   supply the `"ga:"` prefix. See [meta] for a list of dimensons 
#'   and metrics the API supports.
#' @param dim_filters A [filter_clause_ga4] wrapping [dim_filter]
#' @param met_filters A [filter_clause_ga4] wrapping [met_filter]
#' @param filtersExpression A v3 API style simple filter string. Not used with other filters. 
#' @param order An [order_type] object
#' @param segments List of segments as created by [segment_ga4]
#' @param pivots Pivots of the data as created by [pivot_ga4]
#' @param cohorts Cohorts created by [make_cohort_group]
#' @param samplingLevel Sample level
#' @param metricFormat If supplying calculated metrics, specify the metric type
#' @param histogramBuckets For numeric dimensions such as hour, a list of buckets of data.
#' @param max Maximum number of rows to fetch. Defaults at 1000. Use -1 to fetch all results. Ignored when `anti_sample=TRUE`.
#' @param anti_sample If TRUE will split up the call to avoid sampling.
#' @param anti_sample_batches "auto" default, or set to number of days per batch. 1 = daily.
#' @param slow_fetch For large, complicated API requests this bypasses some API hacks that may result in 500 errors.  For smaller queries, leave this as `FALSE` for quicker data fetching. 
#' @param useResourceQuotas If using GA360, access increased sampling limits. 
#'   Default `NULL`, set to `TRUE` or `FALSE` if you have access to this feature. 
#' @param rows_per_call Set how many rows are requested by the API per call, up to a maximum of 100000.
#'   
#' @return A Google Analytics data.frame, with attributes showing row totals, sampling etc. 
#' 
#' @examples 
#' 
#' \dontrun{
#' library(googleAnalyticsR)
#' 
#' ## authenticate, or use the RStudio Addin "Google API Auth" with analytics scopes set
#' 
#' ga_auth()
#' 
#' ## get your accounts
#' 
#' account_list <- ga_account_list()
#' 
#' ## account_list will have a column called "viewId"
#' account_list$viewId
#' 
#' ## View account_list and pick the viewId you want to extract data from
#' ga_id <- 123456
#' 
#' # examine the meta table to see metrics and dimensions you can query
#' meta
#' 
#' ## simple query to test connection
#' google_analytics(ga_id, 
#'                  date_range = c("2017-01-01", "2017-03-01"), 
#'                  metrics = "sessions", 
#'                  dimensions = "date")
#' 
#' ## change the quotaUser to fetch under
#' google_analytics(1234567, date_range = c("30daysAgo", "yesterday"), metrics = "sessions")
#' 
#' options("googleAnalyticsR.quotaUser" = "test_user")
#' google_analytics(1234567, date_range = c("30daysAgo", "yesterday"), metrics = "sessions")
#' 
#' }
#' 
#' @family GAv4 fetch functions
#' @import assertthat
#' @importFrom methods as
#' @export
google_analytics <- function(viewId,
                             date_range=NULL,
                             metrics=NULL,
                             dimensions=NULL,
                             dim_filters=NULL,
                             met_filters=NULL,
                             filtersExpression=NULL,
                             order=NULL,
                             segments=NULL,
                             pivots=NULL,
                             cohorts=NULL,
                             max=1000,
                             samplingLevel=c("DEFAULT", "SMALL","LARGE"),
                             metricFormat=NULL,
                             histogramBuckets=NULL,
                             anti_sample = FALSE,
                             anti_sample_batches = "auto",
                             slow_fetch = FALSE,
                             useResourceQuotas= NULL,
                             rows_per_call = 10000L){
  
  if(is_default_project()){
    if(!interactive()){
      default_project_message()
      stop("The default Google Cloud Project for googleAnalyticsR is intended 
           \nfor evalutation only, not production scripts.  
           \nPlease set your own client.id and client.secret via googleAuthR::gar_set_client()
           \nor otherwise as suggested on the website.", call. = FALSE)
    }
  }
  
  timer_start <- Sys.time()

  assert_that_ifnn(useResourceQuotas, is.flag)
  
  # fix 253
  # make sure its a list of segment_ga4 objects
  segments <- assign_list_class(segments, "segment_ga4")
  
  # 279
  dim_filters <- assign_list_class(dim_filters, ".filter_clauses_ga4")
  met_filters <- assign_list_class(met_filters, ".filter_clauses_ga4")
  
  if(!is.null(filtersExpression)){
    filtersExpression <- as(filtersExpression, "character")
  }
  
  assert_that(is.count(rows_per_call),
              rows_per_call <= 100000L)
  
  # support increase from 10k to 100k
  api_max_rows <- rows_per_call
  
  max         <- as.integer(max)
  allResults  <- FALSE
  if(max < 0){
    ## size of 1 v4 batch 0 indexed
    max <- api_max_rows - 1L
    allResults <- TRUE
  }
  reqRowLimit <- as.integer(api_max_rows)
  
  if(!is.null(cohorts)){
    anti_sample <- FALSE
  }
  
  if(anti_sample){
    if(isTRUE(useResourceQuotas)){
      stop("Can't use anti_sample=TRUE and useResourceQuoteas=TRUE in same API call (and you shouldn't need to)", 
           call. = FALSE)
    }
    myMessage("anti_sample set to TRUE. Mitigating sampling via multiple API calls.", level = 3)
    return(anti_sample(viewId            = viewId,
                       date_range        = date_range,
                       metrics           = metrics,
                       dimensions        = dimensions,
                       dim_filters       = dim_filters,
                       met_filters       = met_filters,
                       filtersExpression = filtersExpression,
                       order             = order,
                       segments          = segments,
                       pivots            = pivots,
                       cohorts           = cohorts,
                       metricFormat      = metricFormat,
                       histogramBuckets  = histogramBuckets,
                       anti_sample_batches = anti_sample_batches,
                       slow_fetch          = slow_fetch,
                       rows_per_call     = rows_per_call))
  }
  
  if(max > reqRowLimit){
    myMessage("Multi-call to API", level = 1)
  }
  
  meta_batch_start_index <- seq(from=0, to=max, by=reqRowLimit)
  
  ## make a list of the requests
  requests <- lapply(meta_batch_start_index, function(start_index){
    
    start_index <- as.integer(start_index)
    
    if(allResults){
      remaining <- as.integer(api_max_rows)
    } else {
      remaining   <- min(as.integer(max - start_index), reqRowLimit)
    }

    make_ga_4_req(viewId            = viewId,
                  date_range        = date_range,
                  metrics           = metrics,
                  dimensions        = dimensions,
                  dim_filters       = dim_filters,
                  met_filters       = met_filters,
                  filtersExpression = filtersExpression,
                  order             = order,
                  segments          = segments,
                  pivots            = pivots,
                  cohorts           = cohorts,
                  pageToken         = start_index,
                  pageSize          = remaining,
                  samplingLevel     = samplingLevel,
                  metricFormat      = metricFormat,
                  histogramBuckets  = histogramBuckets)
    
    })
  
  ## if non-batching, fetch one at a time
  if(slow_fetch){
    out <- fetch_google_analytics_4_slow(requests, 
                                         max_rows = max, allRows = allResults, 
                                         useResourceQuotas = useResourceQuotas)
    allResults <- FALSE
  } else {
    ## only gets up to 50000 first time as we don't know true total row count yet
    out <- fetch_google_analytics_4(requests, 
                                    merge = TRUE, useResourceQuotas = useResourceQuotas)
  }

  ## if batching, get the rest of the results now we now precise rowCount
  if(allResults){
    all_rows <- as.integer(attr(out, "rowCount"))
    if(!is.null(out) && nrow(out) < all_rows){
      ## create the remaining requests
      meta_batch_start_index2 <- tryCatch(seq(from=api_max_rows, to=all_rows, by=reqRowLimit),
                                          error = function(ex){
                                            stop("Sequence batch error: ", 
                                                 "\n api_max_rows: ",api_max_rows,
                                                 "\n all_rows:", all_rows,
                                                 "\n reqRowLimit:", reqRowLimit, call. = FALSE)
                                          })
      ## make a list of the requests
      requests2 <- lapply(meta_batch_start_index2, function(start_index){
        
        start_index <- as.integer(start_index)
        remaining <- as.integer(api_max_rows)
        
        make_ga_4_req(viewId            = viewId,
                      date_range        = date_range,
                      metrics           = metrics,
                      dimensions        = dimensions,
                      dim_filters       = dim_filters,
                      met_filters       = met_filters,
                      filtersExpression = filtersExpression,
                      order             = order,
                      segments          = segments,
                      pivots            = pivots,
                      cohorts           = cohorts,
                      pageToken         = start_index,
                      pageSize          = remaining,
                      samplingLevel     = samplingLevel,
                      metricFormat      = metricFormat,
                      histogramBuckets  = histogramBuckets)
        
      })
      slow <- FALSE
      the_rest <- tryCatch(fetch_google_analytics_4(requests2, 
                                                    merge = TRUE, 
                                                    useResourceQuotas = useResourceQuotas),
                           error = function(ex){
                             myMessage("Error requesting v4 batch - retrying with slow_fetch=TRUE ...", 
                                       level = 3)
                             slow <<- TRUE
                             Sys.sleep(5)
                             fetch_google_analytics_4_slow(requests, 
                                                           max_rows = max, 
                                                           allRows = allResults, 
                                                           useResourceQuotas=useResourceQuotas)
                           })
      
      if(!slow){
        out <- rbind(out, the_rest)
      } else {
        out <- the_rest
      }

      myMessage("All data downloaded, total of [",all_rows,"] - download time: ",
                format(Sys.time() - timer_start), 
                level = 3)
      
    } else {
      myMessage("One batch enough to get all results", level = 1)
    }
    
  }
  
  sampling_message(attr(out, "samplesReadCounts"), 
                   attr(out, "samplingSpaceSizes"), 
                   hasDateComparison = any(grepl("\\.d1|\\.d2", names(out))))
  
  out

}

#' @rdname google_analytics
#' @param ... Arguments passed to [google_analytics]
#' @export
google_analytics_4 <- function(...){
  .Deprecated("google_analytics", package = "googleAnalyticsR")
  google_analytics(...)
}

#' Fetch GAv4 requests one at a time
#' 
#' Due to large complicated queries causing the v4 API to timeout, 
#'   this option is added to fetch via the more traditional one report per request
#' 
#' @param request_list A list of requests created by [make_ga_4_req]
#' @param max_rows Number of rows requested (if not fetched)
#' @param allRows Whether to fetch all available rows
#' @param useResourceQuotas If using GA360, access increased sampling limits. 
#'   Default `NULL`, set to `TRUE` or `FALSE` if you have access to this feature. 
#' 
#' @return A dataframe of all the requests
#' @importFrom googleAuthR gar_api_generator
#' @family GAv4 fetch functions
#' @noRd
fetch_google_analytics_4_slow <- function(request_list, 
                                          max_rows, 
                                          allRows = FALSE, 
                                          useResourceQuotas=NULL){
  
  ## make the fetch function
  myMessage("Calling APIv4 slowly....", level = 2)
  ## make the function
  f <- get_ga4_function()
  
  do_it <- TRUE
  
  ## just need the first one, which we modify
  the_req <- request_list[[1]]
  ## best guess at the moment
  actualRows <- max_rows
  
  response_list <- list()
  
  while(do_it){
    
    body <- list(
      reportRequests = the_req,
      useResourceQuotas = useResourceQuotas
    )
    
    body <- rmNullObs(body)
    
    myMessage("Slow fetch: [", 
              the_req$pageToken, "] from estimated actual Rows [", 
              actualRows, "]", 
              level = 3)

    out <- tryCatch(f(the_body = body),
                    error = function(err){
                      custom_error(err)
                    })

    actualRows <- attr(out[[1]], "rowCount")
    npt <- attr(out[[1]], "nextPageToken")
    if(allRows){
      max_rows <- as.integer(actualRows)
    }
    
    if(is.null(npt) || as.integer(npt) >= max_rows){
      do_it <- FALSE
    }

    the_req$pageToken <- npt
    response_list <- c(response_list, out)

  }

  Reduce(rbind, response_list)

}

#' Fetch multiple GAv4 requests
#' 
#' Fetch the GAv4 requests as created by [make_ga_4_req]
#' 
#' For same viewId, daterange, segments, samplingLevel and cohortGroup, v4 batches can be made
#'
#' @param request_list A list of requests created by [make_ga_4_req]
#' @param merge If TRUE then will rbind that list of data.frames
#' @param useResourceQuotas If using GA360, access increased sampling limits. 
#'   Default `NULL`, set to `TRUE` or `FALSE` if you have access to this feature. 
#'     
#' @return A dataframe if one request, or a list of data.frames if multiple.
#'
#' @importFrom googleAuthR gar_api_generator
#' 
#' @examples 
#' 
#' \dontrun{
#' library(googleAnalyticsR)
#' 
#' ## authenticate, 
#' ## or use the RStudio Addin "Google API Auth" with analytics scopes set
#' ga_auth()
#' 
#' ## get your accounts
#' account_list <- ga_account_list()
#' 
#' ## pick a profile with data to query
#' 
#' ga_id <- account_list[23,'viewId']
#' 
#' ga_req1 <- make_ga_4_req(ga_id, 
#'                          date_range = c("2015-07-30","2015-10-01"),
#'                          dimensions=c('source','medium'), 
#'                          metrics = c('sessions'))
#' 
#' ga_req2 <- make_ga_4_req(ga_id, 
#'                          date_range = c("2015-07-30","2015-10-01"),
#'                          dimensions=c('source','medium'), 
#'                          metrics = c('users'))
#'                          
#' fetch_google_analytics_4(list(ga_req1, ga_req2))
#' 
#' }
#' 
#' @family GAv4 fetch functions
#' @import assertthat
#' @noRd
fetch_google_analytics_4 <- function(request_list, merge = FALSE, useResourceQuotas = NULL){

  assert_that(is.list(request_list))
  ## amount of batches per v4 api call
  ga_batch_limit <- 5
  
  if(length(unique((lapply(request_list, function(x) x$viewId)))) != 1){
    stop("request_list must all have the same viewId", call. = FALSE)
  }
  
  if(length(unique((lapply(request_list, function(x) x$dateRanges)))) != 1){
    stop("request_list must all have the same dateRanges", call. = FALSE)
  }
  
  if(length(unique((lapply(request_list, function(x) x$segments)))) != 1){
    stop("request_list must all have the same segments", call. = FALSE)
  }
  
  if(length(unique((lapply(request_list, function(x) x$samplingLevel)))) != 1){
    stop("request_list must all have the same samplingLevel", call. = FALSE)
  }
  
  if(length(unique((lapply(request_list, function(x) x$cohortGroup)))) != 1){
    stop("request_list must all have the same cohortGroup", call. = FALSE)
  }
  
  myMessage("Calling APIv4....", level = 2)
  ## make the function
  f <- get_ga4_function()
  
  ## if under 5, one call
  if(!is.null(request_list$viewId) || length(request_list) <= ga_batch_limit){
    myMessage("Single v4 batch", level = 2)
    request_list <- unitToList(request_list)
    
    body <- list(
      reportRequests = request_list,
      useResourceQuotas = useResourceQuotas
    )
    
    body <- rmNullObs(body)

    out <- tryCatch(f(the_body = body),
                    error = function(err){
                      custom_error(err)
                    })
    
  } else {

    myMessage("Multiple v4 batch", level = 2)
    ## get list of lists of ga_batch_limit
    request_list_index <- seq(1, length(request_list), ga_batch_limit)
    batch_list <- lapply(request_list_index, 
                         function(x) request_list[x:(x+(ga_batch_limit-1))])
    
    ## make the body for each v4 api call
    body_list <- lapply(batch_list, function(x){
      bb <- list(reportRequests = x, 
                 useResourceQuotas = useResourceQuotas)
      rmNullObs(bb)
    })
    
    body_list <- rmNullObs(body_list)
      
    ## loop over the requests normally
    myMessage("Looping over maximum [", length(body_list), "] batches.", level = 1) 
    
    response_list <- lapply(body_list, function(b){

      myMessage("Fetching v4 data batch...", level = 3)
      out <- tryCatch(f(the_body = b),
                      error = function(err){
                        custom_error(err)
                      })
      
    })
    
    out <- unlist(response_list, recursive = FALSE)
    
    
  }
  

  
  ## if only one entry in the list, return the dataframe
  if(length(out) == 1){
    out <- out[[1]]
  } else {
    ## returned a list of data.frames
    if(merge){

      ## if an empty list, return NULL
      if(all(vapply(out, is.null, logical(1)))){
        out <- NULL
      } else {
        ## check all dataframes have same columns
        df_names <- rmNullObs(lapply(out, function(x) names(x)))
        if(length(unique(df_names)) != 1){
          stop("List of dataframes have non-identical column names. Got ", 
               paste(lapply(out, function(x) names(x)), collapse = " "))
        }
        
        out <- Reduce(rbind, out)
      }

      
    }
  }

  myMessage("Downloaded [",NROW(out),"] rows from a total of [",attr(out, "rowCount"), "].", level = 3)

  out
}

#' @noRd
#' @importFrom googleAuthR gar_api_generator
get_ga4_function <- function(){
  the_user <- getOption("googleAnalyticsR.quotaUser", Sys.info()[["user"]])
  
  if(the_user != Sys.info()[["user"]]){
    myMessage("Fetching API under quotaUser: ", the_user, level =3)
  }

  gar_api_generator("https://analyticsreporting.googleapis.com/v4/reports:batchGet",
                    "POST",
                    pars_args = list(quotaUser = the_user),
                    data_parse_function = google_analytics_4_parse_batch,
                    simplifyVector = FALSE)
}

