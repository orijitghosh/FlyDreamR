#' Convert Master File to FlyDreamR Metadata Format
#'
#' @description
#' Converts a DAM (Drosophila Activity Monitor) master file into the metadata
#' format required by FlyDreamR. The function reads the master file, validates
#' the start and end times against the corresponding monitor file's light sensor
#' data, and generates a properly formatted metadata CSV file.
#'
#' The validation process checks that:
#' \itemize{
#'   \item The provided start time matches the first "lights-ON" event on the
#'     specified start date
#'   \item The provided end time matches the "lights-OFF" event closest to the
#'     specified end time on that date
#' }
#'
#' @section Master File Format:
#' The master file must be a **tab-delimited text file without a header row**.
#' It must contain exactly 8 columns in the following order:
#' \enumerate{
#'   \item \strong{Monitor}: Monitor number (integer)
#'   \item \strong{Channel}: Channel number within the monitor (integer, 1-32 typically)
#'   \item \strong{Line}: Genotype or line identifier (character)
#'   \item \strong{Sex}: Sex of the individual (character, e.g., "M" or "F")
#'   \item \strong{Treatment}: Experimental treatment (character)
#'   \item \strong{Rep}: Replicate number (integer)
#'   \item \strong{Block}: Block number for experimental design (integer)
#'   \item \strong{SetupCode}: Inclusion flag (integer; use \code{1} to include
#'     the channel in output, any other value to exclude)
#' }
#'
#' Only rows with \code{SetupCode = 1} will be included in the output metadata.
#'
#' @section Example Master File:
#' \preformatted{
#' 53  1   w1118   F   control   1   1   1
#' 53  2   w1118   F   control   1   1   1
#' 53  3   mutant  M   drug      1   1   1
#' 53  4   mutant  M   drug      1   1   0
#' }
#' The 4th row would be excluded (SetupCode = 0).
#'
#' @param metafile Character string. Full path to the input master file.
#'   No default value - must be specified.
#'
#'   **Example**: \code{"path/to/master53.txt"}
#'
#' @param startDT Character string. Expected experimental start date and time
#'   in format \code{"YYYY-MM-DD HH:MM:SS"}.
#'
#'   Default: \code{"2024-04-11 06:00:00"}.
#'
#'   This should correspond to a lights-ON event in the monitor file. The function
#'   will validate this by checking the monitor file's light sensor data and warn
#'   if there's a mismatch.
#'
#' @param endDT Character string. Expected experimental end date and time
#'   in format \code{"YYYY-MM-DD HH:MM:SS"}.
#'
#'   Default: \code{"2024-04-16 06:00:00"}.
#'
#'   This should correspond to a lights-OFF event in the monitor file. The function
#'   will find the lights-OFF event on the specified date closest to this time.
#'
#' @param output_dir Character string. Directory path for saving the output
#'   metadata CSV file.
#'
#'   Default: \code{"."} (current working directory).
#'
#'   The directory will be created automatically if it doesn't exist.
#'
#' @return Invisibly returns a \code{data.frame} containing the formatted metadata
#'   (identical to the CSV file content). The function also writes a CSV file to
#'   disk.
#'
#'   **Output filename format**: \code{Metadata_Block[X]Rep[Y]Monitor[Z].csv}
#'
#'   For example: \code{Metadata_Block1Rep1Monitor53.csv}
#'
#'   **The output CSV contains 6 columns**:
#'   \describe{
#'     \item{\code{file}}{Monitor filename (e.g., "Monitor53.txt"). This should
#'       exist in the same directory as the master file.}
#'     \item{\code{start_datetime}}{Experiment start date and time (from \code{startDT})}
#'     \item{\code{stop_datetime}}{Experiment end date and time (from \code{endDT})}
#'     \item{\code{region_id}}{Channel number within the monitor (1-32)}
#'     \item{\code{genotype}}{Combined identifier in format "Line_Sex"
#'       (e.g., "w1118_F", "mutant_M")}
#'     \item{\code{replicate}}{Combined identifier in format "BlockXRepY"
#'       (e.g., "Block1Rep1", "Block2Rep3")}
#'   }
#'
#' @details
#' ## Validation Process
#' The function performs several validation steps:
#' \enumerate{
#'   \item **Read master file**: Loads and validates structure (8 columns, tab-delimited)
#'   \item **Filter rows**: Keeps only rows with \code{SetupCode = 1}
#'   \item **Locate monitor file**: Assumes monitor file (e.g., "Monitor53.txt")
#'     is in the same directory as the master file
#'   \item **Parse light sensor data**: Reads the monitor file's 10th column
#'     (light sensor status)
#'   \item **Find lights-ON event**: Identifies the first 0→1 transition on the
#'     start date
#'   \item **Find lights-OFF event**: Identifies the lights-OFF event (row before
#'     change==1) on the end date closest to the specified time
#'   \item **Compare times**: Issues color-coded warnings if provided times don't
#'     match actual transitions
#'   \item **Generate metadata**: Creates properly formatted output regardless of
#'     validation results
#'   \item **Save CSV**: Writes to disk with automatic filename generation
#' }
#'
#' ## Light Sensor Validation
#' The validation uses the monitor file's light sensor column (column 10):
#' \itemize{
#'   \item **Value 0**: Lights OFF (dark)
#'   \item **Value 1**: Lights ON (light)
#'   \item **Transition 0→1**: Lights turning ON (dawn)
#'   \item **Row before transition 1→0**: Lights turning OFF (dusk)
#' }
#'
#' This validation helps catch common errors like:
#' \itemize{
#'   \item Wrong start date (off by one day)
#'   \item Incorrect time (using 18:00 instead of 06:00)
#'   \item Daylight saving time issues
#'   \item Monitor clock drift
#' }
#'
#' ## Error Handling
#' The function will:
#' \itemize{
#'   \item **Stop with error** if:
#'     - Master file doesn't exist or can't be read
#'     - Master file doesn't have exactly 8 columns
#'     - No rows with SetupCode = 1 found
#'   \item **Issue warning** if:
#'     - Monitor file not found (validation skipped, metadata still generated)
#'     - Start/end times don't match monitor file transitions
#'     - Multiple unique monitor files implied by master data
#'   \item **Continue processing** even if validation fails
#' }
#'
#' ## File Location Assumptions
#' The function assumes:
#' \itemize{
#'   \item Monitor files (e.g., "Monitor53.txt") are in the **same directory**
#'     as the master file
#'   \item Monitor filename matches the pattern "Monitor[N].txt" where N is the
#'     monitor number from the master file
#' }
#'
#' If your files are organized differently, you may need to adjust file paths.
#'
#' @examples
#' \dontrun{
#' # Basic usage with default start/end times
#' metadata <- convMasterToMeta(
#'   metafile = "path/to/master53.txt"
#' )
#' # Output: Metadata_Block1Rep1Monitor53.csv (in current directory)
#'
#' # Specify custom start/end times and output directory
#' metadata <- convMasterToMeta(
#'   metafile = "experiment_data/master53.txt",
#'   startDT = "2024-01-15 09:00:00",  # Lights ON at 9 AM
#'   endDT = "2024-01-20 09:00:00",    # Lights OFF at 9 AM (5 days later)
#'   output_dir = "processed_metadata"
#' )
#' # Output: processed_metadata/Metadata_Block1Rep1Monitor53.csv
#'
#' # Process master file with validation
#' metadata <- convMasterToMeta(
#'   metafile = "raw_data/master54.txt",
#'   startDT = "2024-02-01 06:00:00",
#'   endDT = "2024-02-06 18:00:00"     # Ends at dusk instead of dawn
#' )
#' # Function will validate times against Monitor54.txt
#'
#' # Inspect the returned metadata
#' print(metadata)
#' str(metadata)
#' head(metadata)
#'
#' # Check what files were referenced
#' unique(metadata$file)
#'
#' # See genotype combinations
#' table(metadata$genotype)
#' }
#'
#' @note
#' **Common Issues:**
#'
#' 1. **"Start date-time does not match" warning**:
#'    - Check that your startDT corresponds to lights turning ON
#'    - Verify the date is correct (not off by one day)
#'    - Confirm time zone matches your incubator settings
#'
#' 2. **"Monitor file not found" warning**:
#'    - Ensure Monitor[N].txt is in the same directory as master file
#'    - Check the monitor number in your master file is correct
#'
#' 3. **"No rows with SetupCode = 1"**:
#'    - Verify your master file has some rows with SetupCode = 1
#'    - Check for tab-delimited format (not spaces)
#'
#' @seealso
#' \code{\link{convMasterToMetaBatch}} for processing multiple master files at once
#' \code{\link{HMMDataPrep}} for using the generated metadata to load DAM data
#'
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
