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
#'   endDT = "2024-04-16 06:00:00",
#'   output_dir = "metadata_output"
#' )
#'
#' print(all_metadata)
#' }
#' @export
convMasterToMetaBatch <- function(metafiles,
                                  startDT = "2024-04-11 06:00:00",
                                  endDT = "2024-04-16 06:00:00",
                                  output_dir = ".") {
  cli::cli_rule(left = "Batch conversion start")

  # Process all master files by calling the single-file function
  # lapply will return a list of data frames (or NULLs for failures)
  all_metadata_list <- lapply(metafiles, function(file) {
    cli::cli_rule(left = paste("Processing:", basename(file)))
    tryCatch(
      {
        convMasterToMeta(
          metafile = file,
          startDT = startDT,
          endDT = endDT,
          output_dir = output_dir
        )
      },
      error = function(e) {
        cli::cli_alert_danger("Failed to process {basename(file)}: {e$message}")
        return(NULL) # Return NULL on error
      }
    )
  })

  # Use dplyr::bind_rows or data.table::rbindlist to combine results
  all_metadata <- dplyr::bind_rows(all_metadata_list)

  cli::cli_rule(left = "Batch Complete")
  cli::cli_alert_success("Processed {length(metafiles)} file(s). Returning combined metadata.")

  return(all_metadata)
}
