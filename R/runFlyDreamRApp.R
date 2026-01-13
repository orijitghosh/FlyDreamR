#' Launch the FlyDreamR Shiny App
#'
#' Opens the interactive graphical user interface for analyzing sleep data.
#'
#' @export
runFlyDreamRApp <- function() {
  appDir <- system.file("shiny-apps", "FlyDreamR_app", package = "FlyDreamR")
  if (appDir == "") {
    stop("Could not find example directory. Try re-installing `FlyDreamR`.", call. = FALSE)
  }

  shiny::runApp(appDir, display.mode = "normal")
}
