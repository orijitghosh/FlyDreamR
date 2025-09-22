#' @title HMMplot
#' @description This function is used to save the sleep states inferred through a Hidden Markov Model (HMM) on behavioral data.
#' The function saves the plots in the current working directory.
#' @param HMMinferList A list. Output of \code{HMMbehavr}.
#' @param col_palette Name of desired color palette. Currently 2 options available - \code{default}, and \code{AG}.
#' @return A \code{ggplot2} object.
#' @examples
#' HMMSinglePlot(HMMinferList = res1)
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
