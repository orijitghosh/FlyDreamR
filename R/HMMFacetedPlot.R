#' @title Create a Faceted Plot of HMM Inferred States
#' @description This function generates a single faceted ggplot object displaying
#'              Hidden Markov Model (HMM) inferred behavioral states for multiple
#'              individuals and days. Global X and Y axis titles are displayed for the
#'              entire faceted plot. Axis tick labels are shown on the outer panels
#'              as per ggplot2's default faceting behavior. Facet strip labels for 'day'
#'              are prefixed with "Day: ".
#' @param HMMinferList A list. The output of \code{HMMbehavr}. The second element
#'                     HMMinferList[[2]] is expected to be a data frame.
#' @param col_palette Name of desired color palette. Currently 2 options are
#'                    partially supported - \code{default}, and \code{AG}.
#' @return A \code{ggplot2} object representing the faceted plot.
#' @examples
#' # Assuming res1 is the output from HMMbehavr
#' # faceted_plot <- HMMFacetedPlot(HMMinferList = res1, col_palette = "default")
#' # print(faceted_plot)
#' @export

HMMFacetedPlot <- function(HMMinferList, col_palette = "default") {
  # Basic validation of input
  if (is.null(HMMinferList) || length(HMMinferList) < 2 || !is.data.frame(HMMinferList[[2]])) {
    stop("HMMinferList[[2]] must be a data frame.", call. = FALSE)
  }

  source_data <- as.data.frame(HMMinferList[[2]])

  # Check for required columns
  required_cols <- c("ID", "day", "timestamp", "state_name", "Genotype")
  if (!all(required_cols %in% colnames(source_data))) {
    missing_cols_str <- paste(setdiff(required_cols, colnames(source_data)), collapse = ", ")
    stop(paste("Missing one or more required columns in HMMinferList[[2]]:", missing_cols_str), call. = FALSE)
  }

  all_ids_days <- source_data %>%
    dplyr::select(ID, day) %>%
    dplyr::distinct()

  if (nrow(all_ids_days) == 0) {
    warning("No unique ID-day combinations found in the data.")
    return(ggplot() +
      theme_void() +
      annotate("text", x = 0.5, y = 0.5, label = "No ID-day combinations to plot"))
  }

  all_plot_data_list <- list()

  cli::cli_progress_bar("Preparing data for facets...", total = nrow(all_ids_days))

  for (k in 1:nrow(all_ids_days)) {
    loopid <- all_ids_days$ID[k]
    loopday <- all_ids_days$day[k]
    cli::cli_progress_update()
    df_loop <- source_data %>% dplyr::filter(ID == loopid & day == loopday)
    if (nrow(df_loop) == 0) next
    probs_processed_loop <- tryCatch(
      {
        df_loop %>%
          tidyfast::dt_separate(
            col = state_name,
            into = c("garbage1", "State"),
            sep = "ate",
            remove = FALSE
          ) %>%
          dplyr::select(-garbage1)
      },
      error = function(e) {
        warning(paste0("Could not process state_name for ID: ", loopid, ", Day: ", loopday, ". Skipping. Error: ", e$message), call. = FALSE)
        return(NULL)
      }
    )
    if (!is.null(probs_processed_loop) && nrow(probs_processed_loop) > 0) {
      all_plot_data_list[[length(all_plot_data_list) + 1]] <- probs_processed_loop
    }
  }
  cli::cli_progress_done()

  if (length(all_plot_data_list) == 0) {
    warning("No data successfully processed to generate the faceted plot.")
    return(ggplot() +
      theme_void() +
      annotate("text", x = 0.5, y = 0.5, label = "No data to display"))
  }

  combined_plot_data <- dplyr::bind_rows(all_plot_data_list)

  my_colors <- if (col_palette == "AG") {
    c("State0" = "#fb8500", "State1" = "#ffb703", "State2" = "#8ecae6", "State3" = "#219ebc")
  } else {
    c("State0" = "#f75c46", "State1" = "#ffa037", "State2" = "#33c5e8", "State3" = "#004a73")
  }

  unique_states_in_data <- unique(combined_plot_data$state_name)
  missing_from_palette <- setdiff(unique_states_in_data, names(my_colors))
  if (length(missing_from_palette) > 0) {
    cli::cli_alert_warning(paste("States found in data not in palette:", paste(missing_from_palette, collapse = ", "), ". Assigning default colors."))
    default_colors <- if (length(missing_from_palette) <= 12) RColorBrewer::brewer.pal(max(3, length(missing_from_palette)), "Set3")[1:length(missing_from_palette)] else grDevices::rainbow(length(missing_from_palette))
    names(default_colors) <- missing_from_palette
    my_colors <- c(my_colors, default_colors)
  }

  combined_plot_data$State <- as.numeric(combined_plot_data$State)
  y_axis_labels_present <- sort(intersect(unique_states_in_data, names(my_colors)))
  numeric_part_for_labels <- suppressWarnings(as.numeric(gsub("State", "", y_axis_labels_present)))
  valid_numeric_part <- !is.na(numeric_part_for_labels)
  y_axis_breaks <- numeric_part_for_labels[valid_numeric_part] / 3
  y_axis_labels_filtered <- y_axis_labels_present[valid_numeric_part]
  min_y_lim <- if (length(y_axis_breaks) > 0 && any(!is.na(y_axis_breaks))) min(0, min(y_axis_breaks, na.rm = TRUE)) else 0
  max_y_lim <- if (length(y_axis_breaks) > 0 && any(!is.na(y_axis_breaks))) max(1, max(y_axis_breaks, na.rm = TRUE)) else 1

  # Define the custom labeller function for facet strips
  day_labeller <- function(labels) {
    # 'labels' is a data.frame with columns named after the faceting variables (ID, day)
    if ("day" %in% names(labels)) {
      labels$day <- paste("Day:", as.character(labels$day))
    }
    # Example: If you also wanted to format ID:
    # if ("ID" %in% names(labels)) {
    #   labels$ID <- paste("Animal:", as.character(labels$ID))
    # }
    return(labels)
  }

  p_faceted <- ggplot(combined_plot_data, aes(x = (timestamp / 60), y = State / 3)) +
    geom_line(color = "black", linewidth = 0.5, alpha = 0.1) +
    geom_point(aes(color = state_name), size = 1.5, alpha = 1, stroke = 0.5, shape = 124) +
    scale_color_manual(values = my_colors, name = "State name") +
    scale_x_continuous(breaks = seq(0, 24, by = 6)) +
    scale_y_continuous(
      breaks = if (length(y_axis_breaks) > 0 && !all(is.na(y_axis_breaks))) y_axis_breaks else ggplot2::waiver(),
      labels = if (length(y_axis_labels_filtered) > 0 && !all(is.na(y_axis_breaks))) y_axis_labels_filtered else ggplot2::waiver()
    ) +
    coord_cartesian(xlim = c(0, 24), ylim = c(min_y_lim, max_y_lim), clip = "off") +
    guides(color = guide_legend(override.aes = list(shape = 18, alpha = 1, size = 3))) +
    theme_minimal(base_size = 9) +
    theme(
      axis.text = element_text(size = rel(0.8), color = "black"),
      axis.text.x = element_text(margin = margin(t = 5, unit = "pt")),
      axis.title = element_text(size = rel(1), face = "bold", color = "black"),
      axis.title.x = element_text(margin = margin(t = 15, r = 0, b = 0, l = 0)),
      axis.title.y = element_text(margin = margin(r = 10, l = 0, t = 0, b = 0)),
      panel.grid = element_blank(),
      legend.position = "bottom",
      legend.text = element_text(size = rel(0.8)),
      legend.title = element_text(size = rel(0.9)),
      strip.text = element_text(size = rel(0.65), face = "bold", margin = margin(0.1, 0.1, 0.1, 0.1, "lines")),
      panel.spacing = unit(1, "lines"),
      aspect.ratio = 0.3
    ) +
    xlab("Time (hours)") +
    ylab("Inferred State") +
    facet_wrap(~ ID + day,
      scales = "fixed",
      strip.position = "top",
      labeller = day_labeller, axes = "all"
    ) # Apply the custom labeller

  annotation_y_pos <- min_y_lim - 0.1 * (max_y_lim - min_y_lim)

  p_faceted <- p_faceted +
    annotate("segment", x = 0.0, xend = 24.01, y = annotation_y_pos, yend = annotation_y_pos, linewidth = 1.5, color = "black") +
    annotate("segment", x = 0.01, xend = (24.01 - 12.01), y = annotation_y_pos, yend = annotation_y_pos, linewidth = 1.2, color = "white")

  return(p_faceted)
}
