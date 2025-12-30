#' Plot HMM Inferred Sleep States as Tile Heatmap
#'
#' @description
#' Creates a tile-based heatmap visualization of Hidden Markov Model inferred
#' behavioral states. Each individual is represented as a horizontal row, with
#' time on the x-axis and states shown as colored tiles. Days are displayed as
#' separate facets.
#'
#' This visualization provides a compact overview of state patterns across many
#' individuals, making it easy to identify population-level trends and individual
#' variability in sleep/wake architecture.
#'
#' @param hmm_inference_list A list, typically the output from \code{\link{HMMbehavr}}
#'   or \code{\link{HMMbehavrFast}}. The second element must be a data frame
#'   (\code{VITERBIDecodedProfile}) with columns: \code{timestamp}, \code{ID},
#'   \code{state_name}, and \code{day}.
#' @param color_palette Character string specifying which color palette to use.
#'   Options:
#'   \describe{
#'     \item{\code{"default"}}{Standard FlyDreamR colors (recommended)}
#'     \item{\code{"AG"}}{Alternative palette with warmer tones}
#'     \item{\code{"user"}}{Custom user-defined colors (requires \code{user_colors})}
#'   }
#'   Default: \code{"default"}.
#' @param user_colors A named character vector specifying custom colors for each
#'   state. **Only used when \code{color_palette = "user"}**. Must include all
#'   state names found in the data. Format:
#'   \code{c("State0" = "#RRGGBB", "State1" = "#RRGGBB", ...)}
#'
#'   If \code{color_palette = "user"} but this parameter is \code{NULL} or
#'   incomplete, an error will be raised.
#'
#' @return A \code{ggplot2} object showing:
#'   \itemize{
#'     \item **X-axis**: Time in hours (converted from minutes)
#'     \item **Y-axis**: Individual IDs (discrete)
#'     \item **Tiles**: Colored by state at each time point
#'     \item **Facets**: Separate panels for each day
#'     \item **Aspect ratio**: Dynamically calculated based on number of individuals
#'   }
#'
#'   The returned object can be customized using standard \code{ggplot2} syntax.
#'
#' @details
#' ## Color Palettes
#' All palettes follow the same principle: warm colors = wake, cool colors = sleep
#'
#' **"default" palette:**
#' \itemize{
#'   \item State0: #f75c46 (coral, active wake)
#'   \item State1: #ffa037 (orange, quiet wake)
#'   \item State2: #33c5e8 (cyan, light sleep)
#'   \item State3: #004a73 (navy, deep sleep)
#' }
#'
#' **"AG" palette:**
#' \itemize{
#'   \item State0: #fb8500
#'   \item State1: #ffb703
#'   \item State2: #8ecae6
#'   \item State3: #219ebc
#' }
#'
#' ## When to Use This Plot
#' Use \code{HMMplot} when you want to:
#' \itemize{
#'   \item Compare many individuals simultaneously
#'   \item Identify population-level patterns (e.g., siesta in midday)
#'   \item Screen for outlier individuals
#'   \item Create compact publication figures
#' }
#'
#' For detailed examination of individual state transitions, consider
#' \code{\link{HMMFacetedPlot}} instead.
#'
#' @examples
#' \dontrun{
#' # Basic usage with default palette
#' hmm_results <- HMMbehavr(processed_data)
#' p <- HMMplot(hmm_results)
#' print(p)
#'
#' # Try alternative palette
#' p_ag <- HMMplot(hmm_results, color_palette = "AG")
#'
#' # Use custom colors (e.g., for colorblind-friendly palette)
#' custom_colors <- c(
#'   "State0" = "#D55E00",  # vermillion
#'   "State1" = "#E69F00",  # orange
#'   "State2" = "#56B4E9",  # sky blue
#'   "State3" = "#0072B2"   # blue
#' )
#' p_custom <- HMMplot(
#'   hmm_results,
#'   color_palette = "user",
#'   user_colors = custom_colors
#' )
#'
#' # Save high-resolution figure
#' ggsave("hmm_states_overview.pdf", p,
#'        width = 10, height = 6, dpi = 300)
#'
#' # Further customize
#' library(ggplot2)
#' p +
#'   labs(title = "Sleep/Wake States Across Population",
#'        subtitle = "Wildtype controls, LD 12:12") +
#'   theme(legend.position = "right")
#' }
#'
#' @seealso
#' \code{\link{HMMFacetedPlot}} for detailed multi-panel visualization
#' \code{\link{HMMSinglePlot}} for saving individual plots
#' \code{\link{HMMbehavr}} for generating input data
#'
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
