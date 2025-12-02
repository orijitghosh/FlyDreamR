#' @title Run Hidden Markov Model (HMM) on behavioural data in parallel
#' @description This function applies a Hidden Markov Model (HMM) to behavioral data for multiple individuals in parallel using the `foreach` package. It serves as a wrapper for the `HMMbehavr` function.
#' @param behavtbl A data frame containing the behavioral data. This data frame must conform to the structure of a \code{behavr} table.
#' @param it Integer (>= 100) specifying the number of iterations for the HMM fitting process. Defaults to 100.
#' @param n_cores An integer specifying the number of CPU cores to use for parallel processing. Defaults to 4.
#' @param ldcyc A single numeric value specifying the duration of the light phase in hours. If NULL (default), a 12-hour light/12-hour dark cycle is assumed.
#' @return A list containing two data frames:
#'   \itemize{
#'     \item{\code{TimeSpentInEachState}: Time spent in each inferred state for each individual.}
#'     \item{\code{VITERBIDecodedProfile}: HMM-inferred state profiles for each individual over time.}
#'   }
#' @examples
#' \dontrun{
#' # Assuming 'dt_test' is a valid behavr table
#' results <- HMMbehavrFast(behavtbl = dt_test, iterations = 100, n_states = 4, n_cores = 10, ldcyc = 12, max_inner_it = 500)
#' }
#' @export
#' @importFrom foreach foreach %dopar%
HMMbehavrFast <- function(behavtbl,
                          it = 100,
                          n_cores = 4,
                          ldcyc = NULL) {
  # ---- small validation ----
  if (!is.numeric(n_cores) || n_cores <= 0 || n_cores != round(n_cores)) stop("'n_cores' must be a positive integer.")

  # make %dopar% available without attaching packages
  `%dopar%` <- foreach::`%dopar%`

  # time on main process only
  tictoc::tic("HMMbehavrFast")

  # ---- parallel backend ----
  cl <- parallel::makeCluster(n_cores)
  on.exit(parallel::stopCluster(cl), add = TRUE) # stop ONCE, here
  doParallel::registerDoParallel(cl)

  # local helper; will be exported to workers
  process_individual <- function(individual_id, behavtbl, it, ldcyc) {
    dat <- behavtbl[behavtbl$id == individual_id, ]

    # IMPORTANT: avoid progress bars/noisy printing in workers
    FlyDreamR::HMMbehavr(
      behavtbl = dat,
      it = it,
      ldcyc = ldcyc
    )
  }

  ids <- unique(behavtbl$id)

  res_list <- foreach::foreach(
    individual_id = ids,
    .combine = "c",
    .multicombine = TRUE,
    .packages = c("FlyDreamR", "depmixS4", "data.table", "dplyr")
    # .export   = c("process_individual") # not really needed, let future auto export
    # .errorhandling = "pass"   # uncomment to collect errors instead of stopping
  ) %dopar% {
    out <- process_individual(individual_id, behavtbl, it, ldcyc)
    list(out)
  }

  tictoc::toc()

  # Drop NULLs if any worker failed and returned NULL
  res_list <- Filter(Negate(is.null), res_list)

  # Safely extract the two dfs by NAME and coerce to plain data.frame
  get_ts <- function(x) as.data.frame(x[["TimeSpentInEachState"]])
  get_vb <- function(x) as.data.frame(x[["VITERBIDecodedProfile"]])

  # Use data.table::rbindlist (fast, tolerant) or dplyr::bind_rows
  time_spent_in_states <- data.table::rbindlist(lapply(res_list, get_ts), use.names = TRUE, fill = TRUE)
  hmm_sleep_profiles <- data.table::rbindlist(lapply(res_list, get_vb), use.names = TRUE, fill = TRUE)

  return(list(
    TimeSpentInEachState = time_spent_in_states,
    VITERBIDecodedProfile = hmm_sleep_profiles
  ))
}
