#' Batch Convert Multiple Master Files to FlyDreamR Metadata Format
#'
#' @description
#' Processes multiple DAM master files in batch, converting each to the metadata
#' format required by FlyDreamR. This is a convenient wrapper around
#' \code{\link{convMasterToMeta}} that handles multiple files with the same
#' start/end times.
#'
#' The function validates each master file against its corresponding monitor
#' file, generates individual metadata CSV files, and returns a combined
#' metadata table for all processed files.
#'
#' @section Master File Format:
#' Each master file should follow the same format as described in
#' \code{\link{convMasterToMeta}}:
#' \itemize{
#'   \item Tab-delimited text file
#'   \item No header row
#'   \item 8 columns: Monitor, Channel, Line, Sex, Treatment, Rep, Block, SetupCode
#'   \item Only rows with SetupCode = 1 are processed
#' }
#'
#' @param metafiles Character vector containing full paths to all master files
#'   to process. Can be generated using \code{Sys.glob()} or \code{list.files()}.
#'   No default value.
#' @param startDT Character string. Expected experimental start date-time
#'   **applied to all files**. Format: \code{"YYYY-MM-DD HH:MM:SS"}.
#'   Default: \code{"2024-04-11 06:00:00"}.
#' @param endDT Character string. Expected experimental end date-time
#'   **applied to all files**. Format: \code{"YYYY-MM-DD HH:MM:SS"}.
#'   Default: \code{"2024-04-16 06:00:00"}.
#' @param output_dir Character string. Directory where all metadata CSV files
#'   will be saved. Defaults to current working directory (\code{"."}).
#'   Created if it doesn't exist.
#'
#' @return A single \code{data.frame} combining metadata from all successfully
#'   processed master files. Contains the same columns as individual metadata
#'   files (see \code{\link{convMasterToMeta}} for column details).
#'
#'   Individual CSV files are also written to \code{output_dir}, one per
#'   master file processed.
#'
#'   If a file fails to process, it is skipped with a warning message, and
#'   processing continues with remaining files.
#'
#' @details
#' ## Batch Processing Workflow
#' For each master file, the function:
#' \enumerate{
#'   \item Calls \code{\link{convMasterToMeta}} with provided parameters
#'   \item Validates start/end times against the monitor file
#'   \item Saves individual metadata CSV
#'   \item Collects metadata for combining
#'   \item Handles errors gracefully (skips failed files)
#' }
#'
#' ## Error Handling
#' \itemize{
#'   \item Each file is wrapped in \code{tryCatch}
#'   \item Failed files generate a warning but don't stop processing
#'   \item Successfully processed files are combined in the final output
#'   \item Summary statistics printed at completion
#' }
#'
#' ## Use Cases
#' Use batch processing when you have:
#' \itemize{
#'   \item Multiple monitor files from the same experiment (same timing)
#'   \item Multiple replicates run simultaneously
#'   \item Multiple blocks in a large-scale screen
#' }
#'
#' **Important**: All files must share the same start/end times. If your
#' master files have different timings, process them separately using
#' \code{\link{convMasterToMeta}}.
#'
#' ## Performance
#' Processing speed depends on:
#' \itemize{
#'   \item Number of files
#'   \item Size of monitor files (for validation)
#'   \item I/O speed
#' }
#' Typical: 1-2 seconds per file.
#'
#' @examples
#' \dontrun{
#' # Find all master files in a directory
#' master_files <- Sys.glob("experiment_data/master*.txt")
#'
#' # Process all with same start/end times
#' all_metadata <- convMasterToMetaBatch(
#'   metafiles = master_files,
#'   startDT = "2024-01-15 09:00:00",
#'   endDT = "2024-01-20 09:00:00",
#'   output_dir = "processed_metadata"
#' )
#'
#' # View combined results
#' print(all_metadata)
#' table(all_metadata$genotype)
#'
#' # Alternatively, specify files explicitly
#' master_files <- c(
#'   "data/master53.txt",
#'   "data/master54.txt",
#'   "data/master55.txt"
#' )
#' metadata <- convMasterToMetaBatch(master_files)
#'
#' # Use list.files() with pattern matching
#' master_files <- list.files(
#'   path = "raw_data",
#'   pattern = "^master.*\\.txt$",
#'   full.names = TRUE
#' )
#' metadata <- convMasterToMetaBatch(
#'   metafiles = master_files,
#'   output_dir = "metadata"
#' )
#' }
#'
#' @seealso
#' \code{\link{convMasterToMeta}} for single file processing and format details
#' \code{\link{HMMDataPrep}} for using the generated metadata
#' \code{\link[base]{Sys.glob}} for finding files with wildcards
#'
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
