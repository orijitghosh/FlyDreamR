hmm_state_colors <- function(states, palette = "default", n_states = NULL) {
  if (is.null(n_states)) {
    n_states <- max(as.integer(sub("State", "", states)), na.rm = TRUE) + 1L
  }
  anchors <- if (palette == "AG") {
    c("#fb8500", "#ffb703", "#8ecae6", "#219ebc")
  } else {
    c("#f75c46", "#ffa037", "#33c5e8", "#004a73")
  }
  colors <- if (n_states == 4L) anchors else grDevices::colorRampPalette(anchors)(n_states)
  names(colors) <- paste0("State", seq_len(n_states) - 1L)
  colors
}
