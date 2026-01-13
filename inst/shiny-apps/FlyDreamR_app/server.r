# ---- Dependency bootstrap ----
cran_pkgs <- c(
  "shiny","bslib","shinydashboard","shinycssloaders","shinyalert", "DT",
  "shinyWidgets","shinyhelper","ggplot2","colourpicker","data.table",
  "damr","sleepr","behavr","dplyr","depmixS4","progress","slider","reshape2"
)

# If you have non-CRAN packages, put them here as "pkg" = "owner/repo"
github_pkgs <- c(
  # "FlyDreamR" = "orijitghosh/FlyDreamR"   # <-- fill in the correct repo if this is on GitHub
)

ensure_installed <- function() {
  # use a stable CRAN mirror or Posit Package Manager if your org has one
  if (is.na(getOption("repos")["CRAN"]) || getOption("repos")["CRAN"] == "@CRAN@") {
    options(repos = c(CRAN = "https://cloud.r-project.org"))
  }
  missing_cran <- setdiff(cran_pkgs, rownames(installed.packages()))
  if (length(missing_cran)) install.packages(missing_cran)

  if (length(github_pkgs)) {
    if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
    for (pkg in names(github_pkgs)) {
      if (!requireNamespace(pkg, quietly = TRUE)) remotes::install_github(github_pkgs[[pkg]])
    }
  }

  # load everything (quietly)
  suppressPackageStartupMessages(
    lapply(c(cran_pkgs, names(github_pkgs)), require, character.only = TRUE)
  )
}

ensure_installed()
# ---- end bootstrap ----

library(FlyDreamR)
library(shiny)
library(bslib)
library(shinydashboard)
library(shinycssloaders)
library(shinyalert)
library(shinyWidgets)
library(shinyhelper)
library(data.table)
library(damr)
library(sleepr)
library(behavr)
library(dplyr)
library(depmixS4)
library(progress)
library(slider)
library(reshape2)
library(ggplot2)
source("helpers.R")

shinyServer(function(input, output, session) {
  shinyalert(
    title = "FlyDreamR!",
    text = "<b>This app requires a metadata file for your DAMs. Contact <i>arijitghosh2009@gmail.com</i> for bugs,
    suggestions, troubleshooting and customizations.</b>",
    closeOnEsc = TRUE,
    closeOnClickOutside = FALSE,
    html = TRUE,
    showConfirmButton = TRUE,
    showCancelButton = FALSE,
    confirmButtonText = "Understood!",
    confirmButtonCol = "#AEDEF4",
    timer = 0,
    imageUrl = "./FlyDreamR_logo.png",
    imageWidth = 200,
    imageHeight = 200,
    animation = TRUE,
    size = "s"
  )

  session$onSessionEnded(stopApp)
  observe_helpers(withMathJax = TRUE)

  # Create a reactiveValues object to store calculation results
  # This acts as a container for data that will be generated when the button is pressed.
  results <- reactiveValues(
    dt_curated = NULL,
    res1 = NULL
  )

  # Observer for displaying the uploaded metadata file
  # This block only runs when the metadata file is uploaded and its only job is to display the table.
  observe({
    req(input$meta)
    metadata <- read.csv(input$meta$datapath)
    output$contents <- DT::renderDataTable(
      na.omit(metadata),
      filter = list(position = "top", clear = FALSE, plain = TRUE)
    )
  })

  # All calculations are now inside a single observeEvent
  # This block is ONLY triggered when the user clicks the 'cal' button.
  observeEvent(input$cal, {
    req(input$meta, input$data) # Ensure files are present before calculating

    withBusyIndicatorServer("cal", {
      # File processing moved inside this button observer
      metadata <- read.csv(input$meta$datapath)
      metadata <- na.omit(metadata)

      fixUploadedFilesNames <- function(x) {
        if (is.null(x)) {
          return()
        }
        oldNames <- x$datapath
        newNames <- file.path(dirname(x$datapath), x$name)
        file.rename(from = oldNames, to = newNames)
        x$datapath <- newNames
        x
      }

      file.copy(fixUploadedFilesNames(input$data)$datapath, ".", recursive = TRUE, overwrite = TRUE)
      metadata_proc <- link_dam_metadata(metadata, result_dir = ".")

      # Heavy calculations
      dt_curated_calc <- HMMDataPrep(
        metafile_path = input$meta$datapath,
        result_dir = ".", ldcyc = input$light, day_range = c(input$start, input$end)
      )
      res1_calc <- HMMbehavrFast(
        behavtbl = dt_curated_calc, it = input$itr,
        n_cores = input$nCrs, ldcyc = input$light
      )

      # Store the results in our reactiveValues object
      results$dt_curated <- dt_curated_calc
      results$res1 <- res1_calc
    })
  })

  # All outputs now depend on the 'results' object
  # They will only render/update AFTER the calculations are done and 'results' is populated.

  # Value Boxes
  output$nID <- renderValueBox({
    req(results$dt_curated) # Require results$dt_curated to exist
    valueBox(
      length(unique(results$dt_curated$id)), "Individuals",
      icon = icon("user", lib = "glyphicon"),
      color = "yellow", width = 2
    )
  })

  output$nGeno <- renderValueBox({
    req(results$dt_curated) # Require results$dt_curated to exist
    valueBox(
      length(unique(results$dt_curated$genotype)), "Genotypes",
      icon = icon("barcode", lib = "glyphicon"),
      color = "red", width = 2
    )
  })

  output$nDays <- renderValueBox({
    req(results$dt_curated) # Require results$dt_curated to exist
    valueBox(
      length(unique(results$dt_curated$day)), "Days",
      icon = icon("calendar", lib = "glyphicon"),
      color = "blue", width = 2
    )
  })

  # Plots
  observeEvent(input$plotalletho, {
    req(results$res1) # Require results$res1 to exist
    output$alletho <- renderPlot({
      HMMplot(results$res1)
    },
    res = 120,
    width = input$alletho_width,
    height = input$alletho_height
    )
  })

  observeEvent(input$plotallethoind, {
    req(results$res1) # Require results$res1 to exist
    output$allethoind <- renderPlot({
      HMMFacetedPlot(results$res1)
    },
    res = 120,
    width = input$allethoind_width,
    height = input$allethoind_height
    )
  })

  # Data Tables for Download Tab
  output$tmspntTbl <- DT::renderDataTable({
    req(results$res1) # Require results$res1 to exist
    results$res1$TimeSpentInEachState
  }, filter = list(position = "top", clear = FALSE, plain = TRUE))

  output$prfTbl <- DT::renderDataTable({
    req(results$res1) # Require results$res1 to exist
    results$res1$VITERBIDecodedProfile
  }, filter = list(position = "top", clear = FALSE, plain = TRUE))

  # Download Handlers
  output$downloadData_tmspntTbl <- downloadHandler(
    filename = function() {
      paste("TimeSpentInEachState.csv", sep = "")
    },
    content = function(file) {
      req(results$res1) # Require results$res1 to exist
      write.csv(results$res1$TimeSpentInEachState, file, row.names = FALSE)
    }
  )

  output$downloadData_prfTbl <- downloadHandler(
    filename = function() {
      paste("HMM-inferredSleepProfiles.csv", sep = "")
    },
    content = function(file) {
      req(results$res1) # Require results$res1 to exist
      write.csv(results$res1$VITERBIDecodedProfile, file, row.names = FALSE)
    }
  )
})
