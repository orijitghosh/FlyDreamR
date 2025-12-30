#' Annotate Sleep Bouts in DAM Activity Data
#'
#' @description
#' Internal function that annotates sleep bouts based on immobility duration.
#' Used automatically by \code{\link{HMMDataPrep}} via \code{damr::load_dam}.
#'
#' This function is a modified version of \code{sleepr::sleep_dam_annotation}
#' tailored for the FlyDreamR workflow. It identifies periods of immobility
#' (activity = 0) and classifies them as sleep if they meet the duration criteria.
#'
#' @param data A \code{data.table} containing activity data for one or more animals.
#'   Must include columns:
#'   \itemize{
#'     \item \code{activity}: Numeric activity counts (beam crossings)
#'     \item \code{t}: Time in seconds
#'   }
#'   If the data.table has a key (typically \code{id}), processing is done
#'   separately for each individual.
#' @param min_time_immobile A numeric vector of length 2 specifying the minimum
#'   and maximum duration (in seconds) for an immobility bout to be classified
#'   as sleep. Format: \code{c(min_duration, max_duration)}.
#'
#'   **Default**: \code{c(behavr::mins(5), behavr::mins(1440))}
#'   \itemize{
#'     \item Minimum: 5 minutes (300 seconds) - standard Drosophila sleep definition
#'     \item Maximum: 1440 minutes (86400 seconds, 24 hours) - effectively unlimited
#'   }
#'
#'   **Common alternatives:**
#'   \itemize{
#'     \item \code{c(behavr::mins(1), behavr::mins(1440))}: 1-minute threshold
#'     \item \code{c(behavr::mins(10), behavr::mins(1440))}: 10-minute threshold
#'   }
#'
#' @return The input \code{data.table} with two new logical columns:
#'   \describe{
#'     \item{\code{moving}}{\code{TRUE} if activity > 0, \code{FALSE} otherwise}
#'     \item{\code{asleep}}{\code{TRUE} if the time point is part of an immobility
#'       bout meeting the duration criteria, \code{FALSE} otherwise}
#'   }
#'
#' @details
#' ## Sleep Definition
#' Sleep is defined using the standard Drosophila behavioral criterion:
#' **Immobility lasting at least 5 minutes**
#'
#' ## Processing by Individual
#' If \code{data} has a key set (e.g., \code{id}), the function automatically
#' processes each individual separately. This ensures that bouts don't span
#' across different animals.
#'
#' ## Integration with FlyDreamR
#' This function is called internally by \code{damr::load_dam} when invoked
#' from \code{\link{HMMDataPrep}}. Users can customize the threshold by passing
#' \code{min_time_immobile} to \code{HMMDataPrep} via the \code{...} argument.
#'
#' @examples
#' \dontrun{
#' # This function is typically not called directly by users
#' # Instead, customize it through HMMDataPrep:
#'
#' # Use 10-minute sleep threshold
#' data <- HMMDataPrep(
#'   metafile_path = "metadata.csv",
#'   min_time_immobile = c(behavr::mins(10), behavr::mins(1440))
#' )
#'
#' # Use 1-minute threshold (very sensitive)
#' data <- HMMDataPrep(
#'   metafile_path = "metadata.csv",
#'   min_time_immobile = c(behavr::mins(1), behavr::mins(1440))
#' )
#'
#' # If calling directly (advanced use):
#' library(data.table)
#' dt <- data.table(
#'   t = 1:1000,
#'   activity = sample(0:10, 1000, replace = TRUE)
#' )
#' dt_annotated <- sleepDAMAnnotation(dt)
#' head(dt_annotated)
#' }
#'
#' @references
#' Hendricks, J. C., Finn, S. M., Panckeri, K. A., Chavkin, J., Williams, J. A.,
#' Sehgal, A., & Pack, A. I. (2000). Rest in Drosophila is a sleep-like state.
#' Neuron, 25(1), 129-138.
#'
#' @seealso
#' \code{\link{HMMDataPrep}} for using this function via the standard workflow
#' \code{\link[sleepr]{bout_analysis}} for bout detection algorithm
#' \code{\link[sleepr]{sleep_dam_annotation}} for the original function
#'
#' @keywords internal
sleepDAMAnnotation <- function(data,
                               min_time_immobile = c(behavr::mins(5), behavr::mins(1440))) {
  # Define variables to avoid R CMD check notes
  asleep <- moving <- activity <- duration <- .SD <- . <- NULL

  # Define a helper function to process data for one animal
  wrapped <- function(d) {
    if (!all(c("activity", "t") %in% names(d))) {
      stop("data from DAM should have a column named `activity` and one named `t`")
    }

    out <- data.table::copy(d)
    col_order <- c(colnames(d), "moving", "asleep")
    out[, moving := activity > 0]
    bdt <- sleepr::bout_analysis(moving, out)
    bdt[, asleep := duration %between% min_time_immobile & !moving]
    out <- bdt[, .(t, asleep)][out, on = "t", roll = TRUE]
    data.table::setcolorder(out, col_order)
    out
  }

  # Apply the annotation function to the data
  if (is.null(key(data))) {
    return(wrapped(data))
  }
  data[,
    wrapped(.SD),
    by = key(data)
  ]
}
