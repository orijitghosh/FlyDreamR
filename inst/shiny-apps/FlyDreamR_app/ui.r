# ---- Dependency bootstrap ----
cran_pkgs <- c(
  "shiny","bslib","shinydashboard","shinycssloaders","shinyalert", "DT",
  "shinyWidgets","shinyhelper","ggplot2","colourpicker","data.table",
  "damr","sleepr","behavr","dplyr","depmixS4","progress","slider","reshape2"
)

ensure_installed <- function() {
  # use a stable CRAN mirror or Posit Package Manager if your org has one
  if (is.na(getOption("repos")["CRAN"]) || getOption("repos")["CRAN"] == "@CRAN@") {
    options(repos = c(CRAN = "https://cloud.r-project.org"))
  }
  missing_cran <- setdiff(cran_pkgs, rownames(installed.packages()))
  if (length(missing_cran)) install.packages(missing_cran)

  # load everything (quietly)
  suppressPackageStartupMessages(
    lapply(c(cran_pkgs), require, character.only = TRUE)
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
  title = tags$span(class = "brand-name", "FlyDreamR"),
  id = "tabs",
  collapsible = TRUE,
  fluid = TRUE,
  position = "static-top",
  theme = bslib::bs_theme(
    bg = "#f7fafb",
    fg = "#1b2a33",
    primary = "#176f78",
    base_font = font_google("IBM Plex Sans"),
    code_font = font_google("IBM Plex Mono"),
    heading_font = font_google("IBM Plex Sans"),
    "font-size-base" = "1rem",
    "enable-rounded" = TRUE
  ),
  header = tags$head(includeCSS("style.css")),

  # ===================================================================
  # 1. DATA INPUT TAB
  # ===================================================================
  tabPanel(
    "Data input",
    icon = icon("table"),
    div(
      class = "page-intro landing-intro",
      div(
        class = "page-intro-copy",
        tags$h1("Prepare your analysis"),
        tags$p("Upload monitor and metadata files, choose the experiment settings, then run the model.")
      ),
      tags$img(
        class = "intro-logo",
        src = "FlyDreamR_logo.png",
        alt = "FlyDreamR logo showing a sleeping fruit fly and sleep-state symbols"
      )
    ),
    sidebarLayout(
      sidebarPanel(
        width = 4,
        class = "settings-panel",
        tags$h2("Analysis settings"),
        tags$h3("Files"),
        fileInput(
          "data",
          "Monitor files",
          multiple = TRUE,
          accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv")
        ),
        helper(
          fileInput(
            "meta",
            "Metadata file",
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
        tags$p(class = "field-note", "A metadata file is required for DAM monitor data."),
        tags$h3("Experiment"),
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
        checkboxInput("remove_dead", "Remove suspected death day and later days", FALSE),
        tags$h3("Model"),
        selectInput("n_states", "Number of HMM states", choices = c(3, 4, 5), selected = 4),
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
        div(class = "run-analysis-help",
          helper(
            withBusyIndicatorUI(
              actionBttn(
                inputId = "cal",
                label = "Run analysis",
                style = "minimal",
                color = "primary",
                icon = icon("calculator")
              )
            ),
            type = "inline",
            title = "Start Calculations",
            content = "Pressing this button will curate data and run all HMM analyses."
          )
        )
      ), # end sidebarPanel
      mainPanel(
        width = 8,
        class = "data-panel",
        div(
          class = "section-heading",
          tags$h2("Data preview"),
          tags$p("Check the uploaded records before reviewing the analysis results.")
        ),
        uiOutput("preview_ui"),
        conditionalPanel(
          condition = "input.cal > 0",
          tags$h3(class = "summary-heading", "Analysis summary"),
          fluidRow(class = "summary-grid",
            valueBoxOutput("nID"),
            valueBoxOutput("nGeno"),
            valueBoxOutput("nDays")
          )
        )
      ) # end mainPanel
    ) # end sidebarLayout
  ), # end tabPanel "Data Input"

  # ===================================================================
  # 2. SLEEP PROFILES TAB
  # ===================================================================
  tabPanel(
    "Sleep profiles",
    icon = icon("chart-area"),
    div(
      class = "page-intro profiles-intro",
      div(
        class = "page-intro-copy",
        tags$h1("Explore sleep profiles"),
        tags$p("Review the model output, inspect individual profiles, and download the processed data.")
      )
    ),
    tabsetPanel(
      type = "tabs",
      tabPanel(
        helper(
          "All sleep profiles",
          type = "inline",
          title = "Aggregated Sleep Profiles",
          content = "All sleep profiles for all individuals for the chosen days will be shown here."
        ),
        div(class = "plot-toolbar", splitLayout(
          numericInput("alletho_height", "Height", 500, 100, 10000, 20),
          numericInput("alletho_width", "Width", 1500, 500, 10000, 50),
          actionButton(
            inputId = "plotalletho",
            label = "Generate plot",
            class = "btn-primary",
            icon = icon("chart-line")
          )
        )),
        conditionalPanel(
          condition = "!input.plotalletho",
          div(class = "empty-state",
              tags$img(src = "sleepyfly2.gif", alt = "Animated pixel-art fruit fly"),
              tags$h3("No plot generated yet"),
              tags$p("Run the analysis on Data input, then generate this plot."))
        ),
        conditionalPanel(
          condition = "input.plotalletho",
          div(class = "plot-result",
            withSpinner(
              plotOutput("alletho"),
              image = "sleepyfly2.gif", image.width = 320, image.height = 180
            )
          )
        )
      ),
      tabPanel(
        helper(
          "All individual profiles",
          type = "inline",
          title = "Individual Diagnostic Profiles",
          content = "All diagnostic sleep profiles for each individual for the chosen days will be shown."
        ),
        div(class = "plot-toolbar", splitLayout(
          numericInput("allethoind_height", "Height", 1200, 500, 10000, 20),
          numericInput("allethoind_width", "Width", 2000, 500, 10000, 50),
          actionButton(
            inputId = "plotallethoind",
            label = "Generate plot",
            class = "btn-primary",
            icon = icon("chart-line")
          )
        )),
        conditionalPanel(
          condition = "!input.plotallethoind",
          div(class = "empty-state",
              tags$img(src = "sleepyfly2.gif", alt = "Animated pixel-art fruit fly"),
              tags$h3("No plot generated yet"),
              tags$p("Run the analysis on Data input, then generate this plot."))
        ),
        conditionalPanel(
          condition = "input.plotallethoind",
          div(class = "plot-result",
            withSpinner(
              plotOutput("allethoind"),
              image = "sleepyfly2.gif", image.width = 320, image.height = 180
            )
          )
        )
      ),
      tabPanel(
        helper(
          "Download data",
          type = "inline",
          title = "Download Processed Data",
          content = "All sleep data will be available for download as a <b>.csv</b> file."
        ),
        div(class = "download-actions",
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
          downloadBttn(
            outputId = "downloadQuality",
            label = "Download QualityReport",
            style = "minimal",
            color = "primary"
          )
        ),
        conditionalPanel(
          condition = "!input.cal",
          div(class = "empty-state",
              tags$img(src = "sleepyfly3.gif", alt = "Animated pixel-art fruit fly"),
              tags$h3("No processed data yet"),
              tags$p("Run the analysis to view and download processed data."))
        ),
        conditionalPanel(
          condition = "input.cal",
          withSpinner(
            DT::dataTableOutput("tmspntTbl"),
            image = "sleepyfly3.gif", image.width = 320, image.height = 180
          )
        ),
        DT::dataTableOutput("qualityTbl")
      ) # end tabPanel "Download data"
    ) # end tabsetPanel
  ), # end tabPanel "Sleep Profiles"

  # ===================================================================
  # FOOTER
  # ===================================================================
  footer = tags$footer(
    "FlyDreamR · Sleep and behavioral-state analysis · ",
    tags$a(href = "mailto:arijitghosh2009@gmail.com", "Contact"),
    class = "app-footer"
  )
) # end navbarPage
