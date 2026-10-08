#' Parallel Hidden Markov Model for Sleep State Inference
#'
#' @description
#' Parallelized wrapper for \code{\link{HMMbehavr}} that processes multiple
#' individuals simultaneously using multiple CPU cores. This function provides
#' significant speed improvements for large datasets while maintaining identical
#' output to the serial version.
#'
#' Each individual's data is processed independently in parallel, making this
#' approach ideal for experiments with many animals. The function automatically
#' handles cluster setup and cleanup.
#'
#' @param behavtbl A \code{behavr} table containing behavioral data for multiple
#'   individuals. See \code{\link{HMMbehavr}} for required columns.
#' @param it Integer (>= 100) specifying the number of HMM fitting iterations
#'   per individual per day. Default: 100. See \code{\link{HMMbehavr}} for details.
#' @param n_cores Integer specifying the number of CPU cores to use for parallel
#'   processing. Default: 4.
#'
#'   **Recommendations:**
#'   \itemize{
#'     \item Leave 1-2 cores free for system operations
#'     \item On HPC: request cores matching this parameter
#'     \item Typical desktop: use 2-4 cores
#'     \item Check available cores: \code{parallel::detectCores()}
#'   }
#' @param ldcyc Numeric specifying light phase duration in hours. If \code{NULL}
#'   (default), assumes 12-hour light phase. See \code{\link{HMMbehavr}} for details.
#' @param n_states Number of states to fit: 3, 4, or 5. Default: 4.
#'
#' @return A list containing three data frames with combined results from all
#'   individuals:
#'   \describe{
#'     \item{\code{TimeSpentInEachState}}{Time spent in each state for all individuals}
#'     \item{\code{VITERBIDecodedProfile}}{HMM-inferred state profiles for all individuals}
#'     \item{\code{QualityReport}}{Fit status and reason for each individual and day}
#'   }
#'
#'   See \code{\link{HMMbehavr}} for detailed description of output structure.
#'
#' @details
#' ## Parallelization Strategy
#' The function:
#' \enumerate{
#'   \item Splits data by individual ID
#'   \item Creates a parallel cluster with \code{n_cores} workers
#'   \item Distributes individuals across workers
#'   \item Each worker runs \code{\link{HMMbehavr}} independently
#'   \item Combines results after all workers complete
#'   \item Automatically cleans up cluster
#' }
#'
#' ## Performance Considerations
#' - **Speedup**: Near-linear with number of cores (e.g., 4x faster with 4 cores)
#' - **Memory**: Each worker needs enough RAM for one individual's data
#' - **Overhead**: Setup time ~1-2 seconds; only beneficial for >5-10 individuals
#' - **Progress**: No progress bar (runs silently in parallel)
#'
#' ## Timing Comparison
#' For 32 individuals, 3 days each, it=100:
#' \itemize{
#'   \item Serial (\code{HMMbehavr}): ~160 seconds
#'   \item 4 cores (\code{HMMbehavrFast}): ~45 seconds
#'   \item 8 cores: ~25 seconds
#' }
#'
#' ## Error Handling
#' Failed individual-days are recorded in \code{QualityReport}. Unexpected
#' worker errors stop the call.
#'
#' @examples
#' \dontrun{
#' # Basic parallel processing with 4 cores
#' hmm_results <- HMMbehavrFast(
#'   behavtbl = processed_data,
#'   n_cores = 4
#' )
#'
#' # Use more cores for large dataset
#' hmm_results <- HMMbehavrFast(
#'   behavtbl = processed_data,
#'   it = 200,
#'   n_cores = 8,
#'   ldcyc = 12
#' )
#'
#' # Check available cores first
#' available_cores <- parallel::detectCores()
#' use_cores <- max(1, available_cores - 2)  # Leave 2 for system
#'
#' hmm_results <- HMMbehavrFast(
#'   behavtbl = processed_data,
#'   n_cores = use_cores
#' )
#'
#' # Results structure identical to HMMbehavr
#' time_in_states <- hmm_results$TimeSpentInEachState
#' state_profile <- hmm_results$VITERBIDecodedProfile
#' }
#'
#' @seealso
#' \code{\link{HMMbehavr}} for serial implementation and detailed HMM description
#' \code{\link{HMMDataPrep}} for preparing input data
#' \code{\link[parallel]{makeCluster}} for details on parallel backends
#'
#' @export
#' @importFrom foreach foreach %dopar%
HMMbehavrFast <- function(behavtbl,
                          it = 100,
                          n_cores = 4,
                          ldcyc = NULL,
                          n_states = 4L) {
  # ---- small validation ----
  if (!(is.numeric(n_cores) && length(n_cores) == 1L && is.finite(n_cores) &&
        n_cores > 0 && n_cores == as.integer(n_cores))) {
    stop("'n_cores' must be a positive integer.", call. = FALSE)
  }
  if (!(is.numeric(n_states) && length(n_states) == 1L && n_states %in% 3:5)) {
    stop("'n_states' must be 3, 4, or 5.", call. = FALSE)
  }

  # make %dopar% available without attaching packages
  `%dopar%` <- foreach::`%dopar%`

  # time on main process only
  tictoc::tic("HMMbehavrFast")

  # ---- parallel backend ----
  cl <- parallel::makeCluster(n_cores)
  on.exit(parallel::stopCluster(cl), add = TRUE) # stop ONCE, here
  doParallel::registerDoParallel(cl)

  # local helper; will be exported to workers
  process_individual <- function(individual_id, behavtbl, it, ldcyc, n_states) {
    dat <- behavtbl[behavtbl$id == individual_id, ]

    # IMPORTANT: avoid progress bars/noisy printing in workers
    FlyDreamR::HMMbehavr(
      behavtbl = dat,
      it = it,
      ldcyc = ldcyc,
      n_states = n_states
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
    out <- tryCatch(
      process_individual(individual_id, behavtbl, it, ldcyc, n_states),
      error = function(e) stop("ID ", individual_id, ": ", conditionMessage(e), call. = FALSE)
    )
    list(out)
  }

  tictoc::toc()

  # Drop NULLs if any worker failed and returned NULL
  res_list <- Filter(Negate(is.null), res_list)

  # Safely extract the two dfs by NAME and coerce to plain data.frame
  get_ts <- function(x) as.data.frame(x[["TimeSpentInEachState"]])
  get_vb <- function(x) as.data.frame(x[["VITERBIDecodedProfile"]])
  get_qr <- function(x) as.data.frame(x[["QualityReport"]])

  # Use data.table::rbindlist (fast, tolerant) or dplyr::bind_rows
  time_spent_in_states <- data.table::rbindlist(lapply(res_list, get_ts), use.names = TRUE, fill = TRUE)
  hmm_sleep_profiles <- data.table::rbindlist(lapply(res_list, get_vb), use.names = TRUE, fill = TRUE)
  quality_report <- data.table::rbindlist(lapply(res_list, get_qr), use.names = TRUE, fill = TRUE)

  return(list(
    TimeSpentInEachState = time_spent_in_states,
    VITERBIDecodedProfile = hmm_sleep_profiles,
    QualityReport = quality_report
  ))
}
