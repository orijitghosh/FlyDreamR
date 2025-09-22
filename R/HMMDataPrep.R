#' @title Prepare DAM Activity Data for Analysis
#' @description This function processes Drosophila Activity Monitor (DAM) data and associated
#' metadata. It loads, links, cleans, filters, calculates features (day, phase,
#' normalized activity), and prepares the data into a `behavr` table suitable
#' for downstream analysis (e.g., HMM fitting, plotting).
#'
#' @param metafile_path Character string. The full path to the metadata CSV file.
#'   This file should contain columns linking unique identifiers (like `id`) to
#'   monitor files and experimental conditions (e.g., `genotype`, `replicate`).
#' @param result_dir Character string. The directory path where the raw DAM monitor
#'   files (referenced in the metadata) are located. Defaults to the current
#'   working directory (`getwd()`).
#' @param ldcyc Numeric. The duration of the light phase in hours
#'   within a 24-hour cycle (e.g., 12 for a standard LD 12:12 cycle). Used for
#'   calculating the 'phase' column. Defaults to 12.
#' @param day_range Numeric vector of length 2. Specifies the start and end day
#'   (inclusive) to retain for analysis, e.g., `c(1, 3)` for days 1, 2, and 3.
#'   To select only a single day, repeat the number, e.g., `c(2, 2)`.
#'   Defaults to `c(1, 2)`.
#'
#' @return A `behavr` table (`data.table` format) containing the processed
#'   activity data. Includes original metadata columns plus added columns:
#'   `moving` (logical, activity > 0), `day` (integer), `phase` (factor: "Light", "Dark"),
#'   `normact` (numeric, normalized activity within ID/day), and `t` (numeric, time in seconds).
#'
#' @examples
#' \dontrun{
#' # Define paths and parameters
#' metadata_file <- "path/to/your/metadata.csv"
#' dam_data_folder <- "path/to/your/dam_files/"
#'
#' # Prepare data for days 2 through 4
#' prepared_data <- HMMDataPrep(
#'   metafile_path = metadata_file,
#'   result_dir = dam_data_folder,
#'   ldcyc = 12,
#'   day_range = c(2, 4)
#' )
#'
#' # Check the resulting table
#' print(prepared_data)
#' summary(prepared_data)
#' }
#'
#' # Now, when you call HMMDataPrep, you can add arguments for sleepDAMAnnotation
#' # This call will use a 10-minute threshold instead of the default 5 minutes
#' annotated_data <- HMMDataPrep(metadata_file_path, min_time_immobile = c(behavr::mins(5), behavr::mins(1440)))
#'
#' # If you don't provide the argument, the default from sleepDAMAnnotation is used
#' annotated_data_default <- HMMDataPrep(metadata_file_path)
#'
#' @export
#' @import data.table
#' @importFrom damr link_dam_metadata load_dam
#' @importFrom behavr xmv days hours setbehavr is.behavr
#' @importFrom cli cli_alert_success cli_alert_info cli_alert_warning cli_alert_danger col_yellow col_cyan col_green col_red
#' @importFrom stats quantile na.omit
#' @importFrom utils packageVersion

HMMDataPrep <- function(metafile_path,
                        result_dir = getwd(),
                        ldcyc = 12,
                        day_range = c(1, 2),
                        ...) {
  # --- 1. Input Validation and Setup ---
  # Check required packages silently, stop if missing
  pkgs <- c("data.table", "damr", "behavr", "cli")
  missing_pkgs <- pkgs[!sapply(pkgs, requireNamespace, quietly = TRUE)]
  if (length(missing_pkgs) > 0) {
    stop("Required packages are not installed: ", paste(missing_pkgs, collapse = ", "))
  }

  # Validate inputs
  if (!is.character(metafile_path) || length(metafile_path) != 1 || !file.exists(metafile_path)) {
    stop("`metafile_path` must be a valid path to an existing file.")
  }
  if (!is.character(result_dir) || length(result_dir) != 1) {
    stop("`result_dir` must be a single character string path.")
  }
  # Check if directory exists, warn if not (damr might handle some cases)
  if (!dir.exists(result_dir)) {
    cli::cli_alert_warning("Specified `result_dir` does not exist: {.path {result_dir}}", wrap = TRUE)
  }
  if (!is.numeric(ldcyc) || length(ldcyc) != 1 || !is.finite(ldcyc) || ldcyc <= 0 || ldcyc >= 24) {
    cli::cli_alert_warning("`ldcyc` should be a single positive number < 24. Resetting to default: 12")
    ldcyc <- 12
  }
  if (!is.numeric(day_range) || length(day_range) != 2 || any(!is.finite(day_range)) || day_range[1] < 1 || day_range[2] < day_range[1]) {
    stop("`day_range` must be a numeric vector of length 2 (start_day, end_day), with start_day >= 1 and end_day >= start_day.")
  }
  day_range <- floor(day_range) # Ensure integer days

  cli::cli_alert_info("Starting data preparation...")
  cli::cli_alert_info("Using parameters: light_duration={ldcyc}h, day_range=[{day_range[1]}, {day_range[2]}]")

  # --- 2. Load Metadata ---
  metadata <- tryCatch(
    {
      # Use paste0() defensively in case path needs it, though fread usually handles paths well
      data.table::fread(paste0(metafile_path), na.strings = c("NA", ""))
    },
    error = function(e) {
      stop("Failed to read metadata file: ", metafile_path, "\nError details: ", e$message)
    }
  )
  cli::cli_alert_success("Metadata file read successfully: {.path {metafile_path}}")

  # --- 3. Handle Missing Data in Metadata---
  initial_rows <- nrow(metadata)
  # Consider checking specific essential columns for NA instead of omitting entire row?
  # For now, keep na.omit as it matches the original logic.
  metadata <- stats::na.omit(metadata)
  final_rows <- nrow(metadata)
  if (final_rows < initial_rows) {
    cli::cli_alert_warning("{initial_rows - final_rows} rows removed from metadata due to NA values.")
  }
  if (final_rows == 0) {
    stop("No valid metadata rows remaining after removing NAs. Cannot proceed.")
  }

  # --- 4. Link Metadata to DAM Files ---
  metadata_proc <- tryCatch(
    {
      # link_dam_metadata adds file paths and validates metadata
      damr::link_dam_metadata(metadata, result_dir = result_dir)
    },
    error = function(e) {
      stop("Failed during `damr::link_dam_metadata`. Check metadata content (esp. file references) and `result_dir` path.\nError details: ", e$message)
    }
  )
  cli::cli_alert_success(cli::style_bold(cli::col_yellow("Metadata linked to DAM files.")))

  # --- 5. Load DAM Activity Data ---
  # `load_dam` returns a behavr table (inherits data.table) with time 't'
  dt <- tryCatch(
    {
      damr::load_dam(metadata_proc, FUN = sleepDAMAnnotation, ...)
    },
    error = function(e) {
      stop("Failed during `damr::load_dam`. Check DAM file paths in metadata and file integrity.\nError details: ", e$message)
    }
  )
  cli::cli_alert_success(cli::style_bold(cli::col_cyan("DAM activity data loaded ({nrow(dt)} rows).")))

  # --- 6. Basic Feature: Moving Status ---
  dt[, moving := activity > 0]
  dt[, genotype := behavr::xmv(genotype)]
  dt[, replicate := behavr::xmv(replicate)]

  # --- 7. Calculate Day ---
  # Ensure time column 't' (seconds) exists
  if (!"t" %in% names(dt)) {
    stop("Required column 't' (time in seconds) not found after loading data. Check `damr::load_dam` behavior.")
  }
  dt[, day := floor(t / behavr::days(1)) + 1] # Day 1 starts at t=0 up to t=86399

  # --- 8. Calculate Phase ---
  # Based on time within a 24h cycle vs light duration
  dt[, phase := ifelse(t %% behavr::hours(24) >= behavr::hours(ldcyc), "Dark", "Light")]
  # Ensure consistent factor levels
  dt[, phase := factor(phase, levels = c("Light", "Dark"))]

  # --- 9. Filter by Day Range ---
  initial_rows_filter <- nrow(dt)
  dt <- dt[data.table::between(day, day_range[1], day_range[2], incbounds = TRUE)]
  final_rows_filter <- nrow(dt)
  cli::cli_alert_info("Filtered data by day range [{day_range[1]}, {day_range[2]}]. Kept {final_rows_filter} of {initial_rows_filter} rows.")

  # Check if any data remains after filtering
  if (final_rows_filter == 0) {
    cli::cli_alert_danger(cli::style_bold(cli::col_red(
      "CRITICAL: No data remains after filtering for day range [{day_range[1]}, {day_range[2]}]. Check input data coverage and `day_range` parameter."
    )))
    # Stop execution as subsequent steps will fail
    stop("No data remains after day filtering.")
  }

  # --- 10. Normalize Activity ---
  # Calculate 'normact': activity as a percentage of total daily activity per individual
  # Handle potential division by zero if an animal has zero activity all day
  dt[, normact := {
    (activity / sum(activity, na.rm = TRUE)) * 100
  }, by = .(id, day)] # Group by individual and day

  # --- 11. Finalize as `behavr` Object ---
  # Ensure the output table maintains behavr class and metadata linkage
  # Use the metadata_proc corresponding to the potentially filtered data
  # Filter metadata_proc to only include IDs present in the final 'dt'?
  final_ids <- unique(dt$id)
  metadata_final <- metadata_proc[id %in% final_ids]
  # Re-apply setbehavr to ensure linkage is correct after filtering
  final_behavr_table <- behavr::setbehavr(dt, metadata_final)

  # Optional final check
  if (!behavr::is.behavr(final_behavr_table)) {
    cli::cli_alert_warning("The final data structure may not strictly conform to all `behavr` expectations.")
  }

  cli::cli_alert_success(
    cli::style_bold(cli::col_green("Data preparation complete. Output is a `behavr` table."))
  )

  # --- Return Result ---
  return(final_behavr_table)
}
