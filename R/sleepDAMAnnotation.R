#' @title Custom Sleep Annotation Function
#' @description Annotates sleep bouts based on immobility duration.
#' This function is designed to be used with `damr::load_dam`.
#' This function is modified from `sleepr::sleep_dam_annotation` function.
#' @param data A data.table containing activity data for a single animal.
#'   Must include 'activity' and 't' columns.
#' @param min_time_immobile A vector of two durations defining the min and max
#'   length of an immobility bout to be considered sleep.
#' @return The input data.table with two new columns: 'moving' (boolean) and
#'   'asleep' (boolean).
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
