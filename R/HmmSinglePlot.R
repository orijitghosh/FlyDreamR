#' Save Individual HMM State Plots to Disk
#'
#' @description
#' Generates and saves individual plots of HMM-inferred sleep states to PNG files.
#' Creates one plot per individual per day, organized in a directory structure
#' by genotype. Each plot shows the time-series of state assignments with a
#' light/dark phase annotation.
#'
#' **Note:** This function is designed for batch processing and automatically
#' saves plots to disk. It does not return plots for interactive viewing.
#' For interactive plotting, use \code{\link{HMMplot}} or \code{\link{HMMFacetedPlot}}.
#'
#' @param HMMinferList A list, typically the output from \code{\link{HMMbehavr}}.
#'   The second element (\code{HMMinferList[[2]]}) must be a data frame with
#'   the \code{VITERBIDecodedProfile} containing: \code{ID}, \code{day},
#'   \code{timestamp}, \code{state_name}, and \code{Genotype}.
#' @param col_palette Character string specifying the color palette. Options:
#'   \describe{
#'     \item{\code{"default"}}{Standard FlyDreamR colors}
#'     \item{\code{"AG"}}{Alternative palette}
#'   }
#'   Default: \code{"default"}.
#'
#' @return \code{NULL}. This function is called for its side effect of saving
#'   plot files to disk. It does not return plot objects.
#'
#' @details
#' ## File Organization
#' Plots are saved with the following structure:
#' \preformatted{
#' ./profiles_all/
#'   └── [Genotype]/
#'       ├── [ID]_day1_4states.png
#'       ├── [ID]_day2_4states.png
#'       └── ...
#' }
#'
#' ## File Naming
#' Each file is named: \code{[ID]_day[N]_4states.png}
#' \itemize{
#'   \item ID is sanitized (timestamps and pipe characters removed)
#'   \item Day number is appended
#'   \item Suffix "_4states" indicates 4-state HMM
#' }
#'
#' ## Directory Creation
#' The function automatically creates necessary directories:
#' \itemize{
#'   \item Base directory: \code{./profiles_all/}
#'   \item Subdirectories for each unique genotype
#' }
#'
#' ## Error Handling
#' \itemize{
#'   \item If state separation fails for an individual-day, that plot is skipped
#'     silently (wrapped in \code{tryCatch})
#'   \item If directory creation fails, file save is skipped
#'   \item Progress is printed to console for each file
#' }
#'
#' ## Performance
#' For large datasets:
#' \itemize{
#'   \item 32 individuals × 3 days = 96 PNG files
#'   \item Approximate time: 30-60 seconds
#'   \item Disk space: ~100-200 KB per plot
#' }
#'
#' @examples
#' \dontrun{
#' # Generate HMM results
#' hmm_results <- HMMbehavr(processed_data)
#'
#' # Save all plots with default colors
#' HMMSinglePlot(hmm_results)
#'
#' # Save with alternative palette
#' HMMSinglePlot(hmm_results, col_palette = "AG")
#'
#' # Check output directory structure
#' list.dirs("./profiles_all", recursive = TRUE)
#'
#' # List all generated files
#' list.files("./profiles_all",
#'            pattern = "\\.png$",
#'            recursive = TRUE)
#' }
#'
#' @note
#' This function is most useful for:
#' \itemize{
#'   \item Creating archival records of individual results
#'   \item Manual inspection of individual flies
#'   \item Sharing results with collaborators
#'   \item Supplementary materials for publications
#' }
#'
#' For interactive analysis or presentation figures, consider using
#' \code{\link{HMMplot}} or \code{\link{HMMFacetedPlot}} instead, which
#' return ggplot objects that can be customized and viewed interactively.
#'
#' @seealso
#' \code{\link{HMMplot}} for interactive tile plot
#' \code{\link{HMMFacetedPlot}} for interactive faceted plot
#' \code{\link{HMMbehavr}} for generating input data
#'
#' @export
HMMSinglePlot <- function(HMMinferList, col_palette = "default") {
  uniq <- unique(HMMinferList[[2]]$ID)
  for (i in 1:length(uniq)) {
    loopid <- uniq[i]
    for (j in min(HMMinferList[[2]]$day):max(HMMinferList[[2]]$day)) {
      loopday <- j
      df_loop <- as.data.frame(HMMinferList[[2]]) %>%
        dplyr::filter(ID == loopid & day == loopday)
      probs <- df_loop %>%
        as.data.frame() %>%
        dplyr::select(timestamp, state_name)
      probs_plot <- tryCatch(
        {
          probs %>%
            tidyfast::dt_separate(
              col = state_name,
              into = c("garbage1", "State"),
              sep = "ate", remove = F
            ) %>%
            dplyr::select(-garbage1)
        },
        error = function(e) NULL
      )
      p1 <- ggplot() +
        geom_line(probs_plot,
                  mapping = aes(x = (timestamp / 60), y = as.numeric(State) / 3),
                  color = "black", size = 0.5, alpha = 0.1
        ) +
        geom_point(probs_plot,
                   mapping = aes(x = (timestamp / 60), y = as.numeric(State) / 3, color = state_name),
                   size = 4, alpha = 1, stroke = 0.5, shape = 124
        ) +
        guides(color = guide_legend(
          override.aes = list(shape = 18, alpha = 1), title = "State name"
        )) +
        theme_minimal() +
        xlab("Time (hours)") +
        ylab(NULL) +
        (if (col_palette == "AG") {
          scale_color_manual(
            values = c(
              "State0" = "#fb8500",
              "State1" = "#ffb703",
              "State2" = "#8ecae6",
              "State3" = "#219ebc"
            )
          )
        } else {
          scale_color_manual(
            values = c(
              "State0" = "#f75c46",
              "State1" = "#ffa037",
              "State2" = "#33c5e8",
              "State3" = "#004a73"
            )
          )
        }) +
        scale_x_continuous(breaks = seq(0, 24, 4)) +
        scale_y_continuous(breaks = seq(0, 1, 0.33), labels = c("State0", "State1", "State2", "State3")) +
        theme(
          axis.text = element_text(size = 10, color = "black"), aspect.ratio = 0.15, panel.grid = element_blank(),
          axis.title = element_text(size = 12, face = "bold", color = "black"), legend.position = "none",
          # legend.text = element_text(size = 10, color = "black"), legend.title = element_text(size = 14),
          axis.title.x = element_text(margin = margin(t = 20, r = 0, b = 0, l = 0)),
          axis.text.y = element_text(margin = margin(t = 0, r = -20, b = 0, l = 0))
        )
      # p
      p1 <- p1 + ggtitle(paste0("Day:", j), subtitle = paste0("Genotype:", unique(df_loop$Genotype), " - ", i))
      p <- p1 +
        coord_cartesian(xlim = c(0, 24), ylim = c(0, 1), clip = "off") +
        annotate("segment", x = 0.0, xend = 24.01, y = -0.25, yend = -0.25, size = 4, color = "black") +
        annotate("segment", x = 0.0 + 0.01, xend = 24.01 - 12.01, y = -0.25, yend = -0.25, size = 3, color = "white")
      loop_filename <- paste0("./profiles_all/", unique(df_loop$Genotype), "/", loopid, "_day", loopday, "_4states.png")
      loop_filename <- gsub(":", "_", loop_filename)
      pattern_to_remove <- "\\d{4}-\\d{2}-\\d{2} \\d{2}_\\d{2}_\\d{2}\\|.*\\.txt\\|"
      loop_filename <- sub(pattern_to_remove, "", loop_filename)
      print(paste0("Writing image to ", loop_filename))
      tryCatch(
        {
          ggsave(plot = p, filename = loop_filename, dpi = 300, width = 10, units = "in", create.dir = TRUE)
        },
        error = function(e) NULL
      )
    }
  }
}
