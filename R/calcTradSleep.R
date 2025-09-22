#' @title Calculate Comprehensive Sleep Metrics
#' @description Processes activity data to calculate various sleep and activity
#'   summary statistics, including sleep duration, activity index, brief awakenings,
#'   and detailed sleep bout analysis.
#'
#' @param dt_test A data.table containing the detailed activity and sleep data,
#'   typically the output of a function like `HMMDataPrep`. It must
#'   contain columns like 'id', 'moving', 'asleep', 'activity', 'phase', 'day',
#'   'genotype', and 'replicate'.
#'
#' @return A list containing multiple data.tables with summary metrics:
#'   - `brief_awakenings_data`: The original data with a column for brief awakenings.
#'   - `sleep_summary_phase`: Time spent sleeping per phase and day.
#'   - `sleep_summary_whole_day`: Time spent sleeping per day.
#'   - `activity_index_phase`: Activity index per phase and day.
#'   - `activity_index_whole_day`: Activity index per day.
#'   - `bout_summary_day`: Detailed sleep bout metrics per day.
#'   - `bout_summary_phase`: Detailed sleep bout metrics per phase and day.
#'
#' @examples
#' \dontrun{
#' # Assume 'processed_data' is the output from the 'HMMDataPrep' function
#'
#' # Run the function
#' all_metrics <- calcTradSleep(processed_data)
#'
#' # You can then access each summary table from the list
#' daily_bout_summary <- all_metrics$bout_summary_day
#' phase_sleep_summary <- all_metrics$sleep_summary_phase
#'
#' # View one of the summary tables
#' print(daily_bout_summary)
#' }
#' @export
calcTradSleep <- function(dt_test) {
  # Ensure necessary packages are available for the function's scope

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
    latency = t[1] - ((day - 1) * 86400),
    first_bout_length = duration[1],
    latency_to_longest_bout = t[which.max(duration)] - ((day - 1) * 86400),
    length_longest_bout = max(duration),
    n_bouts = .N,
    mean_bout_length = mean(duration),
    total_bout_length = sum(duration)
  ), by = c("id", "day")]

  # Summarize bouts by phase (Light/Dark)
  bout_dt_new <- bout_dt[, phase := ifelse(t %% behavr::hours(24) > behavr::hours(12), "Dark", "Light")]
  bout_dt_new[, phase := factor(phase, levels = c("Light", "Dark"))]

  bout_summary_phase <- bout_dt_new[, .(
    n_bouts = .N,
    mean_bout_length = mean(duration),
    total_bout_length = sum(duration),
    latency = t[1] - ((day - 1) * 86400)
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
