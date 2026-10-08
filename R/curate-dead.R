curate_dead <- function(data, time_window = behavr::hours(24),
                        step = behavr::hours(1), prop_moving_thresh = 0.02,
                        activity_threshold = 2, k_consecutive = 3) {
  data.table::setDT(data)
  data[, {
    d <- .SD[order(t)]
    spacing <- stats::median(diff(d$t))
    if (!is.finite(spacing) || max(d$t) - min(d$t) + spacing < time_window) {
      d
    } else {
      starts <- seq(min(d$t), max(d$t) - time_window + spacing, by = step)
      low <- vapply(starts, function(s) {
        window <- d[t >= s & t < s + time_window]
        if (nrow(window) < 0.8 * time_window / spacing) return(FALSE)
        moving <- window$activity >= activity_threshold
        if (!any(!is.na(moving))) return(FALSE)
        mean(moving, na.rm = TRUE) <= prop_moving_thresh
      }, logical(1))
      runs <- rle(low)
      hit <- which(runs$values & runs$lengths >= k_consecutive)[1]
      if (!is.na(hit)) {
        death_t <- starts[cumsum(runs$lengths)[hit] - runs$lengths[hit] + 1]
        death_day <- min(d$day[d$t >= death_t])
        d <- d[day < death_day]
      }
      d
    }
  }, by = .(id)]
}
