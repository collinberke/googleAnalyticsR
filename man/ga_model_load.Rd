% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/models.R
\name{ga_model_load}
\alias{ga_model_load}
\title{Load a created model}
\usage{
ga_model_load(filename = "my-model.gamr")
}
\arguments{
\item{filename}{name to load model from}
}
\description{
Load a created model
}
\examples{

# models used in ga_model_example() are here:
location <- system.file("models","examples","decomp_ga.gamr", 
                        package = "googleAnalyticsR")

ga_model_load(location)
}
\seealso{
Other GA modelling functions: 
\code{\link{ga_model}()},
\code{\link{ga_model_edit}()},
\code{\link{ga_model_example}()},
\code{\link{ga_model_make}()},
\code{\link{ga_model_save}()},
\code{\link{ga_model_shiny}()},
\code{\link{ga_model_shiny_load}()},
\code{\link{ga_model_shiny_template}()},
\code{\link{ga_model_write}()}
}
\concept{GA modelling functions}
