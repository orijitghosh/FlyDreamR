#' @title Convert Master File to FlyDreamR Metadata Format
#' @description Reads a master file, optionally validates start/end times against a
#'   monitor file, and generates a metadata file for FlyDreamR.
#'
#' @section Master File Format:
#' The master file should be a tab-delimited text file **without a header row**.
#' It must contain the following columns in order:
#' 1.  Monitor number
#' 2.  Channel number
#' 3.  Genotype/Line
#' 4.  Sex
#' 5.  Treatment
#' 6.  Replicate number
#' 7.  Block number
#' 8.  SetupCode (Use `1` for channels to include, others ignored)
#'
#' @param metafile Character string. Full path to the input master file. No default.
#' @param startDT Character string. The expected start date and time.
#'   Default: `"2024-04-11 06:00:00"`. Format: "YYYY-MM-DD HH:MM:SS".
#' @param endDT Character string. The expected end date and time.
#'   Default: `"2024-04-16 06:00:00"`. Format: "YYYY-MM-DD HH:MM:SS".
#'   Note: Compared against a value derived from the monitor file.
#' @param output_dir Character string. Path to the directory where the output metadata
#'   CSV file should be saved. Defaults to the current working directory (`.`).
#'
#' @return A data frame containing the formatted metadata (equivalent to the written CSV content).
#'   A CSV file is also written to `output_dir`.
#'
#' @examples
#' \dontrun{
#' # Need actual 'master53.txt' and 'Monitor53.txt' files to run
#' convMasterToMeta(
#'   metafile = "master53.txt",
#'   startDT = "2011-10-12 06:15:00",
#'   endDT = "2011-10-16 06:00:00",
#'   output_dir = "."
#' )
#' }
#' @export
convMasterToMeta <- function(metafile,
                                startDT = "2024-04-11 06:00:00",
                                endDT = "2024-04-16 06:00:00",
                                output_dir = ".") {
  # --- 1. Read and Prepare Master Data ---
  cli::cli_alert_info("Reading master file: {metafile}")
  if (!file.exists(metafile)) {
    stop("Input master file not found: ", metafile)
  }
  master_data_raw <- tryCatch(
    {
      utils::read.delim(metafile, header = FALSE, stringsAsFactors = FALSE)
    },
    error = function(e) {
      stop("Failed to read master file: ", metafile, ". Error: ", e$message)
    }
  )

  # Assign column names (preserving original names)
  expected_cols <- c("Monitor", "Channel", "Line", "Sex", "Treatment", "Rep", "Block", "SetupCode")
  if (ncol(master_data_raw) != length(expected_cols)) {
    stop("Master file (after na.omit) does not have the expected 8 columns.")
  }
  colnames(master_data_raw) <- expected_cols

  # Filter for rows marked for inclusion
  master_data_selected <- master_data_raw %>%
    dplyr::filter(SetupCode == 1)

  if (nrow(master_data_selected) == 0) {
    warning("No rows with SetupCode = 1 found in: ", metafile, ". No metadata file will be generated.")
    return(invisible(NULL)) # Return nothing if no data selected
  }

  # --- 2. Validate Start/End Times against Monitor File ---
  cli::cli_alert_info("Starting date/time validation against monitor file...")

  # Determine monitor file name (logic: assumes unique relevant monitor)
  monitor_file_name <- unique(paste0("Monitor", master_data_selected$Monitor, ".txt"))
  if (length(monitor_file_name) > 1) {
    warning("Multiple unique monitor files implied by master data: ", paste(monitor_file_name, collapse = ", "), ". Using the first one: ", monitor_file_name[1])
    monitor_file_name <- monitor_file_name[1]
  }
  monitor_filepath <- file.path(dirname(metafile), monitor_file_name) # Assume monitor file is in the same dir as master file

  if (!file.exists(monitor_filepath)) {
    warning("Monitor file for validation not found at: ", monitor_filepath, ". Skipping date/time validation.")
  } else {
    cli::cli_alert_info("Reading monitor file: {monitor_filepath}")
    monitor_data_raw <- tryCatch(
      {
        utils::read.delim(monitor_filepath, header = FALSE, stringsAsFactors = FALSE)
      },
      error = function(e) {
        warning("Failed to read monitor file: ", monitor_filepath, ". Skipping date/time validation. Error: ", e$message)
        NULL # Set to NULL to skip validation block
      }
    )

    if (!is.null(monitor_data_raw) && ncol(monitor_data_raw) >= 10) {
      # Assign temporary names to relevant columns for clarity (V2=Date, V3=Time, V10=LightStatus)
      colnames(monitor_data_raw)[c(2, 3, 10)] <- c("Date_Str", "Time_Str", "Light_Sensor_Status")

      # --- Process Monitor Data for Change Detection ---
      # Process the monitor data to find when the light turns on/off.
      monitor_data_processed <- monitor_data_raw %>%
        dplyr::mutate(
          DateTime = lubridate::dmy_hms(paste(Date_Str, Time_Str), tz = "UTC", quiet = TRUE)
        ) %>%
        tidyr::drop_na(DateTime) %>%
        dplyr::arrange(DateTime) %>%
        dplyr::mutate(
          Light_Sensor_Status_num = as.numeric(Light_Sensor_Status),
          # **FIXED**: Added dplyr::first() to resolve namespace error
          change = Light_Sensor_Status_num - dplyr::lag(Light_Sensor_Status_num, default = dplyr::first(Light_Sensor_Status_num))
        )

      # --- LIGHTS-ON DETECTION LOGIC (Existing) ---
      # Determine the target date from the user-provided startDT parameter
      target_start_date <- as.Date(startDT)

      # Find the first "lights ON" event (change > 0) specifically ON THE TARGET DATE.
      lights_on_event <- monitor_data_processed %>%
        dplyr::filter(as.Date(DateTime) == target_start_date, change > 0) %>% # 0 -> 1 transition
        dplyr::slice(1) # Take the very first event on that day

      # Derive the actual start date/time string for comparison
      if (nrow(lights_on_event) > 0) {
        actual_start_dt <- lights_on_event$DateTime
        formatted_actual_start <- format(actual_start_dt, "%Y-%m-%d %H:%M:%S")
      } else {
        warning("Could not find a 'lights-ON' event (0->1 transition) for the provided start date: ", target_start_date)
        formatted_actual_start <- NA
      }
      # --- END OF LIGHTS-ON LOGIC ---


      # --- NEW LIGHTS-OFF DETECTION LOGIC ---
      # Derive actual end time by finding the closest "lights OFF" event
      # on the same calendar day as the provided endDT.

      # Parse the user-provided endDT
      target_end_datetime <- lubridate::ymd_hms(endDT, tz = "UTC", quiet = TRUE)

      if (is.na(target_end_datetime)) {
        warning("Could not parse the provided endDT: ", endDT, ". Skipping end time validation.")
        formatted_actual_end <- NA
      } else {
        # Determine the target date from the user-provided endDT parameter
        target_end_date <- as.Date(target_end_datetime)

        # Find the "lights OFF" event (change < 0) on that calendar day
        # that is closest to the provided time.
        lights_off_event <- monitor_data_processed %>%
          dplyr::filter(
            as.Date(DateTime) == target_end_date,
            # Use lead() to find the row *before* the change == 1 event
            dplyr::lead(change, default = 0) == 1
          ) %>%
          dplyr::mutate(
            abs_diff_secs = abs(as.numeric(difftime(DateTime, target_end_datetime, units = "secs")))
          ) %>%
          dplyr::arrange(abs_diff_secs) %>%
          dplyr::slice(1) # Take the one closest in time

        # Derive the actual end date/time string for comparison
        if (nrow(lights_off_event) > 0) {
          actual_end_dt <- lights_off_event$DateTime
          formatted_actual_end <- format(actual_end_dt, "%Y-%m-%d %H:%M:%S")
        } else {
          warning("Could not find a 'lights-OFF' event (row before change==1) for the provided end date: ", target_end_date)
          formatted_actual_end <- NA
        }
      }
      # --- END OF NEW LOGIC ---


      # --- Compare provided startDT with derived start time ---
      if (!is.na(formatted_actual_start)) {
        if (startDT == formatted_actual_start) {
          cli::cli_alert_success(cli::style_bold(cli::col_green("Start date-time matches the actual start date-time")))
        } else {
          cli::cli_alert_warning(cli::style_bold(cli::col_red(
            "Start date-time does not match the actual start date-time, please double-check the start date and lights-ON time in the monitor file, which is ",
            formatted_actual_start
          )))
        }
      } else {
        cli::cli_alert_warning("Skipping start date comparison as actual start time could not be derived.")
      }

      # --- Compare provided endDT with derived end time ---
      if (!is.na(formatted_actual_end)) {
        if (endDT == formatted_actual_end) {
          cli::cli_alert_success(cli::style_bold(cli::col_green("End date-time matches the actual end date-time")))
        } else {
          cli::cli_alert_warning(cli::style_bold(cli::col_red(
            "End date-time does not match the actual end date-time, please double-check the end date and lights-OFF time in the monitor file, which is ",
            formatted_actual_end
          )))
        }
      } else {
        cli::cli_alert_warning("Skipping end date comparison as actual end time could not be derived.")
      }
    } # End check for valid monitor data read
  } # End check for monitor file existence

  # --- 3. Create Metadata Output (Logic: Matrix -> Data Frame) ---
  cli::cli_alert_info("Creating output metadata structure.")

  # Create matrix first (preserving logic)
  output_metadata_matrix <- matrix(nrow = nrow(master_data_selected), ncol = 6)

  # Assign columns (preserving logic and order)
  output_metadata_matrix[, 1] <- paste0("Monitor", master_data_selected$Monitor, ".txt")
  output_metadata_matrix[, 2] <- startDT
  output_metadata_matrix[, 3] <- endDT
  output_metadata_matrix[, 4] <- master_data_selected$Channel
  output_metadata_matrix[, 5] <- paste0(master_data_selected$Line, "_", master_data_selected$Sex)
  output_metadata_matrix[, 6] <- paste0("Block", master_data_selected$Block, "Rep", master_data_selected$Rep)

  # Assign column names (preserving original names)
  output_colnames <- c("file", "start_datetime", "stop_datetime", "region_id", "genotype", "replicate")
  colnames(output_metadata_matrix) <- output_colnames

  # Convert matrix to data frame (preserving logic)
  output_metadata_df <- as.data.frame(output_metadata_matrix, stringsAsFactors = FALSE)

  # --- 4. Write Output File ---
  # Generate filename (logic: assumes unique combo of Block, Rep, Monitor)
  filename_parts <- paste0(
    "Metadata_Block", master_data_selected$Block,
    "Rep", master_data_selected$Rep,
    "Monitor", master_data_selected$Monitor
  )
  base_filename <- unique(filename_parts)
  if (length(base_filename) > 1) {
    warning("Multiple unique output filenames implied by master data: ", paste(base_filename, collapse = ", "), ". Using the first one: ", base_filename[1])
    base_filename <- base_filename[1]
  }
  output_filename <- paste0(base_filename, ".csv")
  output_filepath <- file.path(output_dir, output_filename)

  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  cli::cli_alert_success(cli::style_bold(cli::col_green("Writing metadata to: {output_filepath}")))
  tryCatch(
    {
      # Write CSV (preserving original parameters quote=F, row.names=F)
      utils::write.csv(output_metadata_df, file = output_filepath, quote = FALSE, row.names = FALSE)
    },
    error = function(e) {
      stop("Failed to write output CSV file: ", output_filepath, ". Error: ", e$message)
    }
  )

  # --- 5. Return Result ---
  cli::cli_alert_info("Metadata created and file saved in disk.")
  return(output_metadata_df)
}
