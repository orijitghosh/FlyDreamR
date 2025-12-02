# zzz.R - Package startup routines

# Helper function to generate the startup message for FlyDreamR
# This function is kept internal to this file or could be defined within .onLoad/.onAttach
# if not needed elsewhere.
#' @keywords internal
flydreamr_animation <- function() {
  pkg_name <- "FlyDreamR"
  pkg_version <- utils::packageVersion(pkg_name)
  ascii_art <- r"{
//////////////////////////////////////////////////////////////////
//  _____  _         ____                                ____   //
// |  ___|| | _   _ |  _ \  _ __  ___   __ _  _ __ ___  |  _ \  //
// | |_   | || | | || | | || '__|/ _ \ / _` || '_ ` _ \ | |_) | //
// |  _|  | || |_| || |_| || |  |  __/| (_| || | | | | ||  _ <  //
// |_|    |_| \__, ||____/ |_|   \___| \__,_||_| |_| |_||_| \_\ //
//            |___/                                             //
////////////////////////////////////////////////////////////////// version %s
}"
  cat(sprintf(ascii_art, pkg_version), "\n")
  cat(paste0("Type citation(", "\"", pkg_name, "\"", ") for citing this R package in publications."))
  tagline <- "\nInferring sleep, one fly at a time..."
  packageStartupMessage(cli::col_silver(cli::style_bold(tagline)))
  packageStartupMessage(cli::col_silver(cli::rule()))
  invisible(NULL)
}

.onAttach <- function(libname, pkgname) {
  if (interactive()) {
    flydreamr_animation()
  } else {
    packageStartupMessage(sprintf(
      "Package '%s' version %s loaded.",
      pkgname, utils::packageVersion(pkgname)
    ))
  }
  invisible(NULL)
}
