# zzz.R - Package startup routines

# Helper function to generate the startup message for FlyDreamR
# This function is kept internal to this file or could be defined within .onLoad/.onAttach
# if not needed elsewhere.
#' @keywords internal
# file: R/flydreamr_animation.R
flydreamr_animation <- function() {
  pkg_name <- "FlyDreamR"
  pkg_version <- utils::packageVersion(pkg_name)
  # frames <- list(
  #   "\n[+] ...",
  #   "\n[+] Activating sleep-wake sensors...",
  #   "\n[+] Loading locomotor activity profiles........30%",
  #   "\n[+] Loading locomotor activity profiles........60%",
  #   "\n[+] Loading locomotor activity profiles.......100% ✓",
  #   "\n[+] Calibrating Hidden Markov Models...........15%",
  #   "\n[+] Calibrating Hidden Markov Models...........50%",
  #   "\n[+] Calibrating Hidden Markov Models..........100% ✓",
  #   "\n[+] Decoding sleep states......................25%",
  #   "\n[+] Decoding sleep states......................55%",
  #   "\n[+] Decoding sleep states......................85%",
  #   "\n[+] Decoding sleep states.....................100% ✓",
  #   "\n[+] Engaging dream sequence generator..........40%",
  #   "\n[+] Engaging dream sequence generator..........80%",
  #   "\n[+] Engaging dream sequence generator.........100% ✓",
  #   "\n         -=[ 🌙 FlyDreamR Loaded 🌙 ]=-",
  #   "\n         -=[ 🌙 FlyDreamR Loaded 🌙 ]=-",
  #   "\n         -=[ 🌙 FlyDreamR Loaded 🌙 ]=-",
  #   "\n         Preparing for analysis in 3...",
  #   "\n              Preparing for analysis in 2...",
  #   "\n                   Preparing for analysis in 1...",
  #   "\n                        zZzZzZz..."
  # )
  #
  # for (frame in frames) {
  #   cat("\014") # Clear console
  #   cat(frame, "\n")
  #   Sys.sleep(0.3)
  # }

  # Big ASCII Art at end
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

  # cat("\014") # Final clear
  cat(sprintf(ascii_art, pkg_version), "\n")
  # cat("\nType 'citation(pkg_name)' for citing this R package in publications.")
  cat(paste0("Type citation(", "\"", pkg_name, "\"", ") for citing this R package in publications."))
  # packageStartupMessage("\n✨ FlyDreamR online! Enjoy your journey with HMMs! ✨")
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












# .FlyDreamRStartupMessage <- function() {
#   # Package name is specific to this message function
#   pkg_name <- "FlyDreamR"
#   pkg_version <- utils::packageVersion(pkg_name)
#
#   # ASCII Art for the startup message
#   # Using a raw string literal (r"{...}") for easier handling of special characters.
#   # A placeholder %s is used for the version, to be filled by sprintf.
#   ascii_art_template <- r"{//////////////////////////////////////////////////////////////////
# //  _____  _         ____                                ____   //
# // |  ___|| | _   _ |  _ \  _ __  ___   __ _  _ __ ___  |  _ \  //
# // | |_   | || | | || | | || '__|/ _ \ / _` || '_ ` _ \ | |_) | //
# // |  _|  | || |_| || |_| || |  |  __/| (_| || | | | | ||  _ <  //
# // |_|    |_| \__, ||____/ |_|   \___| \__,_||_| |_| |_||_| \_\ //
# //            |___/                                             //
# ////////////////////////////////////////////////////////////////// version %s}"
#
#   # Line 1: ASCII art with dynamic version
#   line1 <- sprintf(ascii_art_template, pkg_version)
#
#   # Line 2: Citation information
#   # The original included a leading "\n". If packageStartupMessage(c(L1, L2))
#   # already puts L2 on a new line, this \n creates an additional blank line.
#   # Preserving original behavior:
#   line2 <- paste0("\nType 'citation(\"", pkg_name, "\")' for citing this R package in publications.")
#   # If an extra blank line is not desired, use:
#   # line2 <- paste0("Type 'citation(\"", pkg_name, "\")' for citing this R package in publications.")
#
#   return(c(line1, line2)) # Returns a character vector
# }
#
# # .onLoad is called when the package is loaded.
# # For startup messages, .onAttach is generally preferred as it runs when
# # the package is attached to the search path (e.g., via library()).
# # However, sticking to the original .onLoad structure for this refactor.
# .onAttach <- function(libname, pkgname) {
#   # Generate the standard startup message using the helper function
#   startup_msg_vector <- .FlyDreamRStartupMessage()
#
#   # For non-interactive sessions, provide a simpler message.
#   # This replaces the ASCII art (first element of startup_msg_vector)
#   # but will keep the citation information (second element) if that's intended.
#   if (!interactive()) {
#     startup_msg_vector[1] <- paste0(
#       "Package '", pkgname, "' version ",
#       utils::packageVersion(pkgname), " loaded."
#     )
#   }
#
#   # Display the startup message
#   # packageStartupMessage can handle a character vector, printing each element on a new line.
#   packageStartupMessage(startup_msg_vector)
#
#   # The commented-out unlockBinding is generally not needed for standard package behavior.
#   # If it was for a specific, advanced purpose, it would require careful consideration.
#   # # unlockBinding("FlyDreamR", asNamespace("FlyDreamR"))
#
#   # .onLoad should return invisible()
#   invisible()
# }
#
# # Recommendation for future consideration:
# # For package startup messages, .onAttach is often more appropriate:
# #
# # .onAttach <- function(libname, pkgname) {
# #   # (Similar logic as above to generate and display startup_msg_vector)
# #   # ...
# #   # packageStartupMessage(startup_msg_vector)
# #   # invisible()
# # }
# #
# # If .onLoad has other essential tasks (e.g., DLL loading, options setup),
# # those should remain in .onLoad, and the message part can move to .onAttach.
