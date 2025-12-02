#' FlyDreamR: Runs the Ghosh-Harbison Hidden Markov Model on Activity Counts to Infer Sleep/Wake States
#'
#' The FlyDreamR package implements the Ghosh-Harbison hidden Markov model.
#' It is designed to take activity count data as input and subsequently
#' infer sleep and wake states.
#'
#' @section Key Functions:
#' Important functions in this package:
#' \itemize{
#'   \item \code{\link{HMMDataPrep}}: This is the function to prepare DAM data for running the HMMs.
#'   \item \code{\link{HMMbehavr}}: The main function of the package to run HMMs for sleep state inference.
#'   \item \code{\link{HMMbehavrFast}}: Parallelized version of \code{HMMbehavr}.
#' }
#'
#' @author Arijit Ghosh <arijitghosh2009@gmail.com> (ORCID: 0000-0002-7910-3170)
#' @docType package
#' @name FlyDreamR-package
#' @aliases FlyDreamR
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL
