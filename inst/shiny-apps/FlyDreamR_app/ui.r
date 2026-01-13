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

# --- Load Required Libraries ---
library(shiny)
library(bslib)
library(shinydashboard)
library(shinycssloaders)
library(shinyalert)
library(shinyWidgets)
library(shinyhelper)
library(ggplot2)
source("helpers.R")

# --- UI Definition ---
navbarPage(
  "FlyDreamR",
  id = "tabs",
  collapsible = TRUE,
  fluid = TRUE,
  position = "static-top",
  theme = bslib::bs_theme(
    bg = "#e5e5e5",
    fg = "#0d0c0c",
    primary = "#dd2020",
    base_font = font_google("Press Start 2P"),
    code_font = font_google("Press Start 2P"),
    heading_font = font_google("Press Start 2P"),
    "font-size-base" = "1rem",
    "enable-rounded" = FALSE
  ) %>%
    bs_add_rules(
      list(
        sass::sass_file("nes.css"),
        sass::sass_file("style.css"),
        "body { background-color: $body-bg; }"
      )
    ),
  
  # ===================================================================
  # 1. DATA INPUT TAB
  # ===================================================================
  tabPanel(
    "Data input",
    icon = icon("table"),
    sidebarLayout(
      sidebarPanel(
        width = 3,
        fileInput(
          "data",
          "Choose Monitor Files",
          multiple = TRUE,
          accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv")
        ),
        helper(
          fileInput(
            "meta",
            "Choose Metadata File",
            multiple = FALSE,
            accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv")
          ),
          type = "inline",
          title = "Metadata file",
          content = c(
            "Your Metadata file should be a comma separated file and have these following <b>six</b> columns:",
            "<i>file</i>, <i>start_datetime</i>, <i>stop_datetime</i>, <i>region_id</i>, <i>genotype</i>, <i>replicate</i>"
          )
        ),
        helper(
          numericInput("ldperiod", "LD cycle period", 24, 0, 24),
          type = "inline", title = "LD cycle period",
          content = "This value will be used to determine the T-cycle, subsequently affecting sleep quantification."
        ),
        helper(
          numericInput("light", "Duration of light in hours", 12, 0, 24),
          type = "inline", title = "Duration of light in hours",
          content = "This value determines day/night sleep. The light phase starts from your <i>start_datetime</i> in the metadata."
        ),
        helper(
          numericInput("start", "Starting day", 1, 1, 30),
          type = "inline", title = "Starting day",
          content = "Subset your data. Starting day 1 is the first full day. <i>Leave out transition days</i>."
        ),
        helper(
          numericInput("end", "Ending day", 3, 1, 30),
          type = "inline", title = "Ending day",
          content = "Subset your data. For an 8-day experiment, the last day is day 7."
        ),
        helper(
          numericInput("itr", "Number of iterations", 100, 100, 1000, 50),
          type = "inline", title = "Number of iterations",
          content = "Number of iterations for the HMM algorithm."
        ),
        helper(
          numericInput("nCrs", "Number of CPU cores to use", 4, 1, 64, 1),
          type = "inline", title = "Number of CPU cores to use",
          content = "Number of CPU cores for parallel processing. Use cores in multiples of your animal groups for efficiency."
        ),
        helper(
          withBusyIndicatorUI(
            actionBttn(
              inputId = "cal",
              label = "Start calculations!",
              style = "minimal",
              color = "primary",
              icon = icon("calculator")
            )
          ),
          type = "inline",
          title = "Start Calculations",
          content = "Pressing this button will curate data and run all HMM analyses."
        )
      ), # end sidebarPanel
      mainPanel(
        width = 9,
        withSpinner(
          DT::dataTableOutput("contents"),
          image = "sleepyfly1.gif", image.width = 640.5, image.height = 360
        ),
        fluidRow(
          valueBoxOutput("nID"),
          valueBoxOutput("nGeno"),
          valueBoxOutput("nDays")
        )
      ) # end mainPanel
    ) # end sidebarLayout
  ), # end tabPanel "Data Input"
  
  # ===================================================================
  # 2. SLEEP PROFILES TAB
  # ===================================================================
  tabPanel(
    "Sleep Profiles",
    icon = icon("chart-area"),
    navlistPanel(
      widths = c(3, 9),
      tabPanel(
        helper(
          "All sleep profiles",
          type = "inline",
          title = "Aggregated Sleep Profiles",
          content = "All sleep profiles for all individuals for the chosen days will be shown here."
        ),
        splitLayout(
          numericInput("alletho_height", "height", 500, 100, 10000, 20),
          numericInput("alletho_width", "width", 1500, 500, 10000, 50),
          actionBttn(
            inputId = "plotalletho",
            label = "Plot",
            style = "minimal",
            color = "primary",
            icon = icon("forward")
          )
        ),
        tags$hr(),
        withSpinner(
          plotOutput("alletho"),
          image = "sleepyfly2.gif", image.width = 640.5, image.height = 360
        )
      ),
      tabPanel(
        helper(
          "All individual profiles",
          type = "inline",
          title = "Individual Diagnostic Profiles",
          content = "All diagnostic sleep profiles for each individual for the chosen days will be shown."
        ),
        splitLayout(
          numericInput("allethoind_height", "height", 1200, 500, 10000, 20),
          numericInput("allethoind_width", "width", 2000, 500, 10000, 50),
          actionBttn(
            inputId = "plotallethoind",
            label = "Plot",
            style = "minimal",
            color = "primary",
            icon = icon("forward")
          )
        ),
        tags$hr(),
        withSpinner(
          plotOutput("allethoind"),
          image = "sleepyfly2.gif", image.width = 640.5, image.height = 360
        )
      ),
      tabPanel(
        helper(
          "Download data",
          type = "inline",
          title = "Download Processed Data",
          content = "All sleep data will be available for download as a <b>.csv</b> file."
        ),
        downloadBttn(
          outputId = "downloadData_tmspntTbl",
          label = "Download time spent data",
          style = "minimal",
          color = "primary"
        ),
        downloadBttn(
          outputId = "downloadData_prfTbl",
          label = "Download individual sleep profiles",
          style = "minimal",
          color = "primary"
        ),
        tags$hr(),
        withSpinner(
          DT::dataTableOutput("tmspntTbl"),
          image = "sleepyfly3.gif", image.width = 640.5, image.height = 360
        )
      ) # end tabPanel "Download data"
    ) # end navlistPanel
  ), # end tabPanel "Sleep Profiles"
  
  # ===================================================================
  # FOOTER
  # ===================================================================
  footer = tags$footer(
    "Theme from NES.css",
    style = "
      position: fixed;
      text-align: center;
      bottom: 0;
      left: 0;
      width: 100%;
      height: 45px;
      padding: 10px;
      color: #0d0c0c;
      background-color: #e5e5e5;
      border-top: 4px solid #0d0c0c;
      z-index: 1000;
    "
  )
) # end navbarPage