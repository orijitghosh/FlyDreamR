#' @title Plot Inferred Sleep States from HMM
#' @description This function visualizes the sleep state flags inferred by a Hidden Markov Model (HMM) applied to behavioral data.
#' @param hmm_inference_list A list, typically the output of the \code{HMMbehavr} function. It is expected to contain a data frame at the second position (`[[2]]`) with columns like `timestamp`, `ID`, `state_name`, and `day`.
#' @param color_palette Name of the desired color palette. Available options are `"default"`, `"AG"`, and `"user"`. Defaults to `"default"`.
#' @param user_colors A named character vector specifying the colors for each state (e.g., \code{c("State0" = "red", "State1" = "blue")}).
#'   This parameter is only used when \code{color_palette = "user"}. If `"user"` is selected and this parameter is not provided or is incorrectly formatted, an error will be thrown.
#' @return A \code{ggplot2} object representing the plot of inferred sleep states.
#' @examples
#' # Assuming 'res1' is the output of HMMbehavr
#' library(ggplot2)
#'
#' # Using default palette
#' plot_default <- HMMplot(hmm_inference_list = res1)
#' print(plot_default)
#'
#' # Using AG palette
#' plot_AG <- HMMplot(hmm_inference_list = res1, color_palette = "AG")
#' print(plot_AG)
#'
#' # Using a custom user-defined palette
#' user_palette <- c("State0" = "lightgreen", "State1" = "darkgreen", "State2" = "lightblue", "State3" = "darkblue")
#' plot_user <- HMMplot(hmm_inference_list = res1, color_palette = "user", user_colors = user_palette)
#' print(plot_user)
#' @export
HMMplot <- function(hmm_inference_list, color_palette = "default", user_colors = NULL) {
  # Validate input parameters
  if (!is.list(hmm_inference_list) || length(hmm_inference_list) < 2 || !is.data.frame(hmm_inference_list[[2]])) {
    stop("Error: 'hmm_inference_list' must be a list with at least two elements, and the second element must be a data frame.")
  }
  if (!color_palette %in% c("default", "AG", "user")) {
    stop("Error: 'color_palette' must be either 'default', 'AG', or 'user'.")
  }

  # Extract the data frame containing state information
  state_data <- hmm_inference_list[[2]]
  state_names <- unique(state_data$state_name)

  # Define default color palettes
  default_colors <- c(
    "State0" = "#f75c46",
    "State1" = "#ffa037",
    "State2" = "#33c5e8",
    "State3" = "#004a73"
  )

  AG_colors <- c(
    "State0" = "#fb8500",
    "State1" = "#ffb703",
    "State2" = "#8ecae6",
    "State3" = "#219ebc"
  )

  # Select the color palette based on the input
  selected_colors <- switch(color_palette,
    "default" = default_colors,
    "AG" = AG_colors,
    "user" = {
      if (is.null(user_colors) || !is.character(user_colors) || is.null(names(user_colors)) ||
        !all(state_names %in% names(user_colors))) {
        stop(paste0(
          "Error: When 'color_palette' is set to 'user', 'user_colors' must be a named character vector ",
          "containing colors for all state names (e.g., c('State0' = 'red', 'State1' = 'blue')). ",
          "Current state names found: ", paste(state_names, collapse = ", ")
        ))
      }
      user_colors
    }
  )

  # Define a small ratio for visual spacing between individuals
  display_ratio <- 0.02

  # Calculate the aspect ratio to make the plot visually appealing
  aspect_ratio <- display_ratio * length(unique(state_data$ID)) * length(unique(state_data$day))

  # Create the ggplot object
  plot <- ggplot2::ggplot(
    state_data,
    ggplot2::aes(
      x = timestamp / 60, # Convert timestamp to minutes for the x-axis
      y = ID,
      fill = state_name,
      color = state_name
    )
  ) +
    ggplot2::geom_tile() + # Use tiles to represent the states over time
    ggplot2::scale_y_discrete(expand = c(0, 0)) + # Remove extra space on the y-axis
    ggplot2::scale_x_continuous(
      expand = c(0, 0), # Remove extra space on the x-axis
      breaks = scales::pretty_breaks(6), # Set reasonable breaks for the x-axis
      name = "Time (Hours)" # Label the x-axis
    ) +
    ggplot2::scale_fill_manual(
      values = selected_colors,
      breaks = names(selected_colors), # Ensure breaks match the state names
      name = "State" # Label the fill legend
    ) +
    ggplot2::scale_color_manual(
      values = selected_colors,
      breaks = names(selected_colors), # Ensure breaks match the state names
      name = "State", # Label the color legend (can be redundant but kept for consistency)
      guide = "none" # Remove the color legend as it's the same as fill
    ) +
    ggplot2::facet_wrap(~day, nrow = 1) + # Separate the plot by day
    ggplot2::xlab("Time (Hours)") + # Redundant label, already set in scale_x_continuous
    ggplot2::theme(aspect.ratio = aspect_ratio) # Apply the calculated aspect ratio

  return(plot)
}
