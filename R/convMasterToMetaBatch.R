#' @title Convert Multiple Master Files to FlyDreamR Metadata Format (Batch)
#' @description Reads one or more master files, optionally validates start/end times against
#'   their corresponding monitor files, and generates individual metadata CSVs.
#'
#' @section Master File Format:
#' Each master file should be a tab-delimited text file **without a header row**.
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
#' @param metafiles Character vector. Full paths to the input master files. No default.
#' @param startDT Character string. The expected start date and time.
#'   Default: `"2024-04-11 06:00:00"`. Format: "YYYY-MM-DD HH:MM:SS".
#' @param endDT Character string. The expected end date and time.
#'   Default: `"2024-04-16 06:00:00"`. Format: "YYYY-MM-DD HH:MM:SS".
#'   Note: Compared against a value derived only from the last date in the monitor file.
#' @param output_dir Character string. Path to the directory where the output metadata
#'   CSV files should be saved. Defaults to the current working directory (`.`).
#'
#' @return A single data frame containing the combined formatted metadata (equivalent to
#'   the written CSV content) from all successfully processed master files.
#'   Individual CSV files are also written to `output_dir`.
#'
#' @examples
#' \dontrun{
#' # Vector of master files (or use Sys.glob("path/master*.txt"))
#' my_master_files <- c("experiment_data/master53.txt", "experiment_data/master54.txt")
#'
#' all_metadata <- convMasterToMetaBatch(
#'   metafiles = my_master_files,
#'   startDT = "2024-04-11 06:00:00",
#'   endDT   = "2024-04-16 06:00:00",
#'   output_dir = "metadata_output"
#' )
#'
#' print(all_metadata)
#' }
#' @export
convMasterToMetaBatch <- function(metafiles,
                                   startDT = "2024-04-11 06:00:00",
                                   endDT   = "2024-04-16 06:00:00",
                                   output_dir = ".") {

  cli::cli_rule(left = "Batch conversion start")
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Helper to process one master file using the same logic as convMasterToMeta()
  .process_one <- function(current_metafile) {
    tryCatch({
      # --- 1. Read and Prepare Master Data ---
      cli::cli_rule(left = paste("Processing:", basename(current_metafile)))
      cli::cli_alert_info("Reading master file: {current_metafile}")

      if (!file.exists(current_metafile)) {
        stop("Input master file not found: ", current_metafile)
      }

      master_data_raw <- tryCatch(
        utils::read.delim(current_metafile, header = FALSE, stringsAsFactors = FALSE),
        error = function(e) {
          stop("Failed to read master file: ", current_metafile, ". Error: ", e$message)
        }
      )

      expected_cols <- c("Monitor", "Channel", "Line", "Sex", "Treatment", "Rep", "Block", "SetupCode")
      if (ncol(master_data_raw) != length(expected_cols)) {
        stop("Master file (after na.omit) does not have the expected 8 columns.")
      }
      colnames(master_data_raw) <- expected_cols

      # Filter for rows marked for inclusion
      master_data_selected <- master_data_raw %>%
        dplyr::filter(SetupCode == 1)

      if (nrow(master_data_selected) == 0) {
        warning("No rows with SetupCode = 1 found in: ", current_metafile, ". Skipping.")
        return(NULL)
      }

      # --- 2. Validate Start/End Times against Monitor File ---
      cli::cli_alert_info("Starting date/time validation against monitor file...")

      monitor_file_name <- unique(paste0("Monitor", master_data_selected$Monitor, ".txt"))
      if (length(monitor_file_name) > 1) {
        warning("Multiple unique monitor files implied by master data: ",
                paste(monitor_file_name, collapse = ", "),
                ". Using the first one: ", monitor_file_name[1])
        monitor_file_name <- monitor_file_name[1]
      }
      monitor_filepath <- file.path(dirname(current_metafile), monitor_file_name)

      if (!file.exists(monitor_filepath)) {
        warning("Monitor file for validation not found at: ", monitor_filepath, ". Skipping date/time validation.")
      } else {
        cli::cli_alert_info("Reading monitor file: {monitor_filepath}")
        monitor_data_raw <- tryCatch(
          {
            utils::read.delim(monitor_filepath, header = FALSE, stringsAsFactors = FALSE)
          },
          error = function(e) {
            warning("Failed to read monitor file: ", monitor_filepath,
                    ". Skipping date/time validation. Error: ", e$message)
            NULL
          }
        )

        if (!is.null(monitor_data_raw) && ncol(monitor_data_raw) >= 10) {
          # Assign temporary names for clarity
          colnames(monitor_data_raw)[c(2, 3, 10)] <- c("Date_Str", "Time_Str", "Light_Sensor_Status")

          # --- CORRECTED LIGHTS-ON DETECTION LOGIC (same as single-file fn) ---
          monitor_data_processed <- monitor_data_raw %>%
            dplyr::mutate(
              DateTime = lubridate::dmy_hms(paste(Date_Str, Time_Str), tz = "UTC", quiet = TRUE)
            ) %>%
            tidyr::drop_na(DateTime) %>%
            dplyr::arrange(DateTime) %>%
            dplyr::mutate(
              Light_Sensor_Status_num = as.numeric(Light_Sensor_Status),
              change = Light_Sensor_Status_num - dplyr::lag(Light_Sensor_Status_num, default = first(Light_Sensor_Status_num))
            )

          target_date <- as.Date(startDT)

          lights_on_event <- monitor_data_processed %>%
            dplyr::filter(as.Date(DateTime) == target_date, change > 0) %>%
            dplyr::slice(1)

          if (nrow(lights_on_event) > 0) {
            actual_start_dt <- lights_on_event$DateTime
            formatted_actual_start <- format(actual_start_dt, "%Y-%m-%d %H:%M:%S")

            if (isTRUE(startDT == formatted_actual_start)) {
              cli::cli_alert_success(cli::style_bold(cli::col_green(
                "Start date-time matches the actual start date-time"
              )))
            } else {
              cli::cli_alert_warning(cli::style_bold(cli::col_red(
                "Start date-time does not match the actual start date-time, please double-check the start date and lights-ON time in the monitor file, which is ",
                formatted_actual_start
              )))
            }
          } else {
            cli::cli_alert_warning("Skipping start date comparison as a 'lights-ON' event on the target date was not found.")
          }
          # --- END corrected logic ---

          # Derive and compare actual end date (from last Date column)
          actualEnd_str <- utils::tail(monitor_data_raw$Date_Str, 1)
          parsed_actual_end_date <- lubridate::dmy(actualEnd_str, quiet = TRUE)
          formatted_actual_end <- format(parsed_actual_end_date, "%Y-%m-%d %H:%M:%S")

          if (!is.na(formatted_actual_end)) {
            if (isTRUE(endDT == formatted_actual_end)) {
              cli::cli_alert_success(cli::style_bold(cli::col_green("End date matches the actual end date")))
            } else {
              cli::cli_alert_warning(cli::style_bold(cli::col_red(
                "End date does not match the actual end date, please double-check the end date in the monitor file, which is ",
                formatted_actual_end
              )))
            }
          } else {
            cli::cli_alert_warning("Skipping end date comparison as actual end date could not be derived.")
          }
        }
      }

      # --- 3. Create Metadata Output (Matrix -> Data Frame) ---
      cli::cli_alert_info("Creating output metadata structure.")
      output_metadata_matrix <- matrix(nrow = nrow(master_data_selected), ncol = 6)

      output_metadata_matrix[, 1] <- paste0("Monitor", master_data_selected$Monitor, ".txt")
      output_metadata_matrix[, 2] <- startDT
      output_metadata_matrix[, 3] <- endDT
      output_metadata_matrix[, 4] <- master_data_selected$Channel
      output_metadata_matrix[, 5] <- paste0(master_data_selected$Line, "_", master_data_selected$Sex)
      output_metadata_matrix[, 6] <- paste0("Block", master_data_selected$Block, "Rep", master_data_selected$Rep)

      colnames(output_metadata_matrix) <- c("file", "start_datetime", "stop_datetime", "region_id", "genotype", "replicate")
      output_metadata_df <- as.data.frame(output_metadata_matrix, stringsAsFactors = FALSE)

      # --- 4. Write Output File ---
      filename_parts <- paste0(
        "Metadata_Block", master_data_selected$Block,
        "Rep", master_data_selected$Rep,
        "Monitor", master_data_selected$Monitor
      )
      base_filename <- unique(filename_parts)
      if (length(base_filename) > 1) {
        warning("Multiple unique output filenames implied by master data: ",
                paste(base_filename, collapse = ", "),
                ". Using the first one: ", base_filename[1])
        base_filename <- base_filename[1]
      }
      output_filename <- paste0(base_filename, ".csv")
      output_filepath <- file.path(output_dir, output_filename)

      cli::cli_alert_success(cli::style_bold(cli::col_green("Writing metadata to: {output_filepath}")))
      tryCatch(
        {
          utils::write.csv(output_metadata_df, file = output_filepath, quote = FALSE, row.names = FALSE)
        },
        error = function(e) {
          stop("Failed to write output CSV file: ", output_filepath, ". Error: ", e$message)
        }
      )

      cli::cli_alert_info("Metadata created and file saved in disk.")
      return(output_metadata_df)

    }, error = function(e) {
      cli::cli_alert_danger("Failed to process {basename(current_metafile)}: {e$message}")
      return(NULL)
    })
  }

  # Process all master files and row-bind results (skipping NULLs)
  all_metadata_list <- lapply(metafiles, .process_one)
  all_metadata <- dplyr::bind_rows(all_metadata_list)

  cli::cli_rule(left = "Batch Complete")
  cli::cli_alert_success("Processed {length(metafiles)} file(s). Returning combined metadata.")

  return(all_metadata)
}
