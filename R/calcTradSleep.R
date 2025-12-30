#' Calculate Comprehensive Sleep Metrics from Activity Data
#'
#' @description
#' Processes activity data to calculate traditional sleep metrics including sleep
#' duration, activity index during wakefulness, brief awakenings, and detailed
#' sleep bout characteristics. This function implements standard sleep analysis
#' metrics commonly used in Drosophila sleep research.
#'
#' A "brief awakening" is defined as a single time point of movement that is
#' immediately preceded and followed by immobility, potentially indicating
#' fragmented or shallow sleep.
#'
#' @param dt_test A \code{data.table} containing activity and sleep state data,
#'   typically the output from \code{\link{HMMDataPrep}}. Must contain the
#'   following columns:
#'   \itemize{
#'     \item \code{id}: Unique identifier for each individual
#'     \item \code{moving}: Logical indicator of movement
#'     \item \code{asleep}: Logical indicator of sleep state
#'     \item \code{activity}: Numeric activity count
#'     \item \code{phase}: Factor with levels "Light" and "Dark"
#'     \item \code{day}: Integer day number
#'     \item \code{genotype}: Character or factor indicating genotype
#'     \item \code{replicate}: Character or factor indicating replicate ID
#'   }
#'
#' @return A named list containing seven \code{data.table} objects with sleep
#'   metrics (all time values in **minutes**):
#'   \describe{
#'     \item{\code{brief_awakenings_data}}{Original data with added
#'       \code{brief_awakenings} column (logical)}
#'     \item{\code{sleep_summary_phase}}{Total sleep time per phase (Light/Dark)
#'       and day for each individual}
#'     \item{\code{sleep_summary_whole_day}}{Total sleep time per day for each
#'       individual}
#'     \item{\code{activity_index_phase}}{Mean activity during wakefulness per
#'       phase and day (total activity / time awake)}
#'     \item{\code{activity_index_whole_day}}{Mean activity during wakefulness
#'       per day}
#'     \item{\code{bout_summary_day}}{Detailed sleep bout metrics per day including:
#'       \itemize{
#'         \item \code{latency}: Time to first sleep bout (minutes from day start)
#'         \item \code{first_bout_length}: Duration of first sleep bout
#'         \item \code{latency_to_longest_bout}: Time to longest bout
#'         \item \code{length_longest_bout}: Duration of longest bout
#'         \item \code{n_bouts}: Number of sleep bouts
#'         \item \code{mean_bout_length}: Average bout duration
#'         \item \code{total_bout_length}: Total sleep time from bouts
#'       }}
#'     \item{\code{bout_summary_phase}}{Sleep bout metrics per phase and day}
#'   }
#'
#' @details
#' The function calculates metrics separately for light and dark phases based on
#' the \code{phase} column. Sleep bouts are identified using
#' \code{\link[sleepr]{bout_analysis}} from the \code{sleepr} package.
#'
#' Activity index provides a measure of movement intensity during wake periods,
#' which can indicate arousal threshold or sleep depth.
#'
#' @examples
#' \dontrun{
#' # Assume 'processed_data' is output from HMMDataPrep()
#' sleep_metrics <- calcTradSleep(processed_data)
#'
#' # Access individual metric tables
#' daily_bouts <- sleep_metrics$bout_summary_day
#' phase_sleep <- sleep_metrics$sleep_summary_phase
#'
#' # View brief awakening data
#' head(sleep_metrics$brief_awakenings_data)
#'
#' # Summary statistics
#' summary(sleep_metrics$sleep_summary_whole_day$time_spent_sleeping)
#' }
#'
#' @seealso
#' \code{\link{HMMDataPrep}} for preparing input data
#' \code{\link[sleepr]{bout_analysis}} for bout detection algorithm
#'
#' @export
calcTradSleep <- function(dt_test) {

  # --- 1. Identify Brief Awakenings ---
  # A brief awakening is a single time point of movement surrounded by immobility.
  dt_BA <- dt_test %>%
    dplyr::group_by(id) %>%
    dplyr::mutate(
      brief_awakenings = ifelse(moving == TRUE & dplyr::lag(moving) == FALSE & dplyr::lead(moving) == FALSE, TRUE, FALSE)
    )
  dt_BA <- setDT(dt_BA, key = "id")


  # --- 2. Summarize Time Spent Sleeping and Awake ---
  summary_sleep_phase <- dt_test[, .(
    time_spent_sleeping = length(asleep[asleep == TRUE])
  ), by = c("id", "phase", "day", "genotype", "replicate")]

  summary_sleep_whole_day <- dt_test[, .(
    time_spent_sleeping = length(asleep[asleep == TRUE])
  ), by = c("id", "day", "genotype", "replicate")]


  # --- 3. Calculate Activity Index ---
  # This is the total activity during wakefulness divided by the time spent awake.
  summary_awake_phase_foractivityindex <- dt_test[, .(
    time_spent_awake = length(asleep[asleep == FALSE]),
    activity_in_time_spent_awake = sum(activity[asleep == FALSE])
  ), by = c("id", "phase", "day", "genotype", "replicate")]

  activity_index_phase <- summary_awake_phase_foractivityindex[, .(
    activity_index = activity_in_time_spent_awake / time_spent_awake
  ), by = c("id", "phase", "day", "genotype", "replicate")]

  summary_awake_whole_day_foractivityindex <- dt_test[, .(
    time_spent_awake = length(asleep[asleep == FALSE]),
    activity_in_time_spent_awake = sum(activity[asleep == FALSE])
  ), by = c("id", "day", "genotype", "replicate")]

  activity_index_whole_day <- summary_awake_whole_day_foractivityindex[, .(
    activity_index = activity_in_time_spent_awake / time_spent_awake
  ), by = c("id", "day", "genotype", "replicate")]


  # --- 4. Perform Detailed Sleep Bout Analysis ---
  bout_dt <- sleepr::bout_analysis(asleep, dt_test)
  bout_dt[, day := ceiling(t / behavr::days(1))]
  bout_dt$day[bout_dt$day == 0] <- 1
  bout_dt <- bout_dt[asleep == TRUE, -"asleep"] # We only care about sleep bouts

  # Summarize bouts for the whole day
  bout_summary_day <- bout_dt[, .(
    latency = (t[1] - ((day - 1) * 86400))/60,
    first_bout_length = (duration[1])/60,
    latency_to_longest_bout = (t[which.max(duration)] - ((day - 1) * 86400))/60,
    length_longest_bout = (max(duration))/60,
    n_bouts = .N,
    mean_bout_length = (mean(duration))/60,
    total_bout_length = (sum(duration))/60
  ), by = c("id", "day")]

  # Summarize bouts by phase (Light/Dark)
  bout_dt_new <- bout_dt[, phase := ifelse(t %% behavr::hours(24) > behavr::hours(12), "Dark", "Light")]
  bout_dt_new[, phase := factor(phase, levels = c("Light", "Dark"))]

  bout_summary_phase <- bout_dt_new[, .(
    n_bouts = .N,
    mean_bout_length = (mean(duration))/60,
    total_bout_length = (sum(duration))/60,
    latency = (t[1] - ((day - 1) * 86400))/60
  ), by = c("id", "phase", "day")]


  # --- 5. Return All Results in a List ---
  return(list(
    brief_awakenings_data = dt_BA,
    sleep_summary_phase = summary_sleep_phase,
    sleep_summary_whole_day = summary_sleep_whole_day,
    activity_index_phase = activity_index_phase,
    activity_index_whole_day = activity_index_whole_day,
    bout_summary_day = bout_summary_day,
    bout_summary_phase = bout_summary_phase
  ))
}
