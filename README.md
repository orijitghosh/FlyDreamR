# FlyDreamR <img src="https://img.shields.io/badge/R-%3E%3D%204.0-276DC3" align="right"/>

<img src="/FlyDreamR_logo.png" alt="FlyDreamR logo" width="200" align="right"/>

> **Run the Ghosh–Harbison hidden Markov model on Activity Counts to Infer Sleep/Wake States**

[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html) [![License: GPL-3](https://img.shields.io/badge/License-GPL--3-blue.svg)](LICENSE) [![Repo status](https://img.shields.io/badge/status-active-success)](#) [![Issues](https://img.shields.io/github/issues/orijitghosh/FlyDreamR.svg)](https://github.com/orijitghosh/FlyDreamR/issues)

`FlyDreamR` implements the **Ghosh–Harbison hidden Markov model (HMM)** framework to infer *sleep* and *wake* states from *Drosophila* Activity Monitor (DAM) **activity counts**. It wraps the full workflow: **metadata → DAM loading → cleaning & feature engineering → HMM inference (serial or parallel) → plotting → summary metrics**.

------------------------------------------------------------------------

## ✨ Highlights

-   **End-to-end pipeline**: from metadata to publication-ready figures.
-   **Dual analysis modes**: Traditional sleep metrics AND advanced HMM-based state inference.
-   **Traditional sleep metrics** (`calcTradSleep()`): Define sleep as you wish, for 5 minutes to 60 minutes of immobility, bout counts/lengths, activity index, brief awakenings, day/phase summaries.
-   **Robust inference** with a configurable HMM and decoding.
-   **Parallel execution** via `HMMbehavrFast()` for big data.
-   **Rich visualization suite**: Heatmap hypnograms, faceted profiles, and individual profiles, per day.
-   **Interactive Shiny GUI** for users who prefer point-and-click analysis.

------------------------------------------------------------------------

## 📦 Installation

### From GitHub (recommended)

``` r
# Install from GitHub (devtools or remotes)
install.packages(c('devtools','remotes'), repos='https://cloud.r-project.org')
remotes::install_github('orijitghosh/FlyDreamR', upgrade = 'never')

# Pin to a specific release
remotes::install_github('orijitghosh/FlyDreamR@v1.0.0', upgrade = 'never')
```

### From source (local installation)

``` r
# Install additional packages for initial installation and post processing
install.packages(c("devtools", "ggplot2", "ggetho", "magrittr", "patchwork"))

# Create a temporary directory and extract the package source code
d <- tempdir()
untar("FlyDreamR_1.0.0.tar.gz", compressed="gzip", exdir=d)

# Build the package from source
devtools::install(file.path(d, "FlyDreamR"), dependencies=TRUE, 
                  repos="https://cloud.r-project.org/")
```

------------------------------------------------------------------------

## 🚀 Quick Start

### 1. Prepare Your Data

Convert your master file(s) to metadata format compatible with FlyDreamR:

``` r
library(FlyDreamR)

# Single master file (master.txt)
metafile <- convMasterToMeta(
  metafile = "master.txt", 
  startDT = "2025-02-12 06:04:00", 
  endDT = "2025-02-17 06:04:00"
)

# Multiple master files (batch processing)
metafileBatch <- convMasterToMetaBatch(
  c("master1.txt", "master2.txt"), 
  startDT = "2025-02-12 06:04:00", 
  endDT = "2025-02-17 06:04:00"
)
```

### 2. Load and Prepare DAM Data

``` r
# Prepare DAM data for analysis
dt_test <- HMMDataPrep(
  metafile_path = "Metadata_Monitor1.csv", 
  result_dir = getwd(), # Set directory to where Monitor files are
  ldcyc = 12,           # Light:dark cycle (hours)
  day_range = c(1, 2)   # Days to analyze
)
```

------------------------------------------------------------------------

## 📊 Analysis Workflows

### Traditional Sleep Analysis and Visualization

Calculate classical sleep metrics with customizable immobility thresholds:

``` r
# 5-minute immobility definition of sleep
dt_test_trad <- HMMDataPrep(
  metafile_path = "Metadata_Monitor1.csv", 
  result_dir = getwd(), 
  ldcyc = 12, 
  day_range = c(1, 2), 
  min_time_immobile = c(behavr::mins(5), behavr::mins(1440))
)

tradSleep <- calcTradSleep(dt_test_trad)

# 30-minute immobility definition of sleep
dt_test_trad <- HMMDataPrep(
  metafile_path = "Metadata_Monitor1.csv", 
  result_dir = getwd(), 
  ldcyc = 12, 
  day_range = c(1, 2), 
  min_time_immobile = c(behavr::mins(30), behavr::mins(1440))
)

tradSleep <- calcTradSleep(dt_test_trad)

# 60-minute immobility definition of sleep
dt_test_trad <- HMMDataPrep(
  metafile_path = "Metadata_Monitor1.csv", 
  result_dir = getwd(), 
  ldcyc = 12, 
  day_range = c(1, 2), 
  min_time_immobile = c(behavr::mins(60), behavr::mins(1440))
)

tradSleep <- calcTradSleep(dt_test_trad)

# Results include 7 data frames:
# - sleep_summary_whole_day
# - sleep_summary_phase
# - bout_summary_whole_day
# - bout_summary_phase
# - activity_index_whole_day
# - activity_index_phase
# - brief_awakenings_data

library(ggplot2)
library(ggetho)

# Somnograms (sleep/wake tiles)
ggetho(dt_test_trad, aes(x = t, z = asleep)) +
  stat_bar_tile_etho()

# Sleep profiles averaged by genotype
ggetho(dt_test_trad, aes(x = t, y = asleep, color = genotype)) +
  stat_pop_etho() +
  facet_grid(genotype ~ .) +
  stat_ld_annotations()

# Time-wrapped profiles (24-hour average)
ggetho(dt_test_trad, aes(x = t, y = asleep, color = genotype), 
       time_wrap = behavr::hours(24)) +
  stat_pop_etho() +
  facet_grid(genotype ~ .) +
  stat_ld_annotations()
```

### HMM-Based Sleep/Wake Inference

Fit Hidden Markov Models to infer sleep states:

``` r
# Single-threaded version
res <- HMMbehavr(behavtbl = dt_test, it = 100, ldcyc = 12)

# Parallel version (faster for large datasets)
resprl <- HMMbehavrFast(
  behavtbl = dt_test, 
  it = 100, 
  ldcyc = 12, 
  n_cores = 4
)
```

------------------------------------------------------------------------

## 📈 Visualization

FlyDreamR provides multiple plotting functions for different visualization needs:

### HMM Hypnograms

``` r
# Heatmap hypnograms
HMMplot(res)

# Use different color palettes
HMMplot(res, color_palette = "AG")

# Custom colors
HMMplot(res, color_palette = "user", 
        user_colors = c("State0" = "#FF0060", 
                       "State1" = "#F6FA70", 
                       "State2" = "#00DFA2", 
                       "State3" = "#0079FF"))

# Faceted individual hypnograms
HMMFacetedPlot(res)

# Save individual hypnograms to drive
HMMSinglePlot(res)
```

### Summary Statistics Plots

``` r
# Time spent sleeping (traditional analysis)
ggplot(tradSleep$sleep_summary_phase, 
       aes(x = genotype, y = time_spent_sleeping, fill = genotype)) +
  geom_boxplot(width = 0.35, outliers = F) +
  geom_label(aes(label = after_stat(sprintf("%.1f", y))),
             size = 3, color = "white",
             stat = "summary", fun = "mean", 
             alpha = 0.8, vjust = -0.75, hjust = -0.1, 
             show.legend = F) +
  facet_grid(phase ~ day, scales = "free_y") +
  scale_fill_manual(values = c("#E76254", "#F5A354", "#4A86A8", "#1E466E")) +
  labs(x = "Genotype", y = "Time spent sleeping (min)") +
  theme_minimal()

# Time spent in HMM states
ggplot(res$TimeSpentInEachState, 
       aes(x = state_name, y = time_spent, fill = state_name)) +
  geom_boxplot(width = 0.35, outliers = F) +
  facet_grid(day ~ phase, scales = "free_y") +
  scale_fill_manual(values = c("#E76254", "#F5A354", "#4A86A8", "#1E466E")) +
  theme_minimal()
```

------------------------------------------------------------------------

## 🖥️ Interactive Shiny GUI

For users who prefer a graphical interface, FlyDreamR includes a Shiny app:

``` r
# Launch the Shiny App (will install required packages if needed)
shiny::runApp("path/to/Shiny-FlyDreamR_1.0.0/")
```

The GUI allows you to: 1. Upload and convert master files interactively. 2. Configure analysis parameters via dropdown menus. 3. Run both traditional and HMM analyses. 4. Generate and download plots. 5. Export results as CSV files.

------------------------------------------------------------------------

## 📚 Key Functions Reference

### Data Preparation

-   `convMasterToMetaBatch()` - Batch convert multiple master files
-   `HMMDataPrep()` - Load and prepare DAM data for analysis

### Analysis

-   `calcTradSleep()` - Calculate traditional sleep metrics
-   `HMMbehavr()` - Fit HMMs (single-threaded)
-   `HMMbehavrFast()` - Fit HMMs (parallel processing)

### Visualization

-   `HMMplot()` - Create heatmap hypnograms
-   `HMMFacetedPlot()` - Generate faceted individual hypnograms
-   `HMMSinglePlot()` - Save individual hypnograms to files

------------------------------------------------------------------------

## 🔬 Output Data Structures

### Traditional Sleep Analysis (`calcTradSleep()`)

Returns a list with 7 data frames: 1. **sleep_summary_whole_day**: 24-hour sleep summaries. 2. **sleep_summary_phase**: Day/night phase summaries. 3. **bout_summary_whole_day**: Bout metrics for 24 hours. 4. **bout_summary_phase**: Bout metrics by phase. 5. **activity_index_whole_day**: Waking activity per minute (24h). 6. **activity_index_phase**: Waking activity by phase. 7. **brief_awakenings_data**: Brief awakening statistics. All durations are in minutes.

### HMM Analysis (`HMMbehavr()` / `HMMbehavrFast()`)

Returns a list with 2 data frames: 1. **TimeSpentInEachState**: Summary of time in each HMM state 2. **VITERBIDecodedProfile**: Raw Viterbi-decoded state sequences.

------------------------------------------------------------------------

## 💡 Tips and Best Practices

1.  **Performance**: Use `HMMbehavrFast()` with multiple cores for large datasets.
2.  **Sleep definition**: Experiment with different `min_time_immobile` thresholds (5, 10, 30, 60 minutes).
3.  **Visualization**: Combine plots using `patchwork` for publication figures.
4.  **Data quality**: Check for dead flies or tracking issues before analysis.
5.  **Reproducibility**: Always specify `startDT` and `endDT` explicitly in metadata conversion, and `set.seed()`.
6.  **Help pages**: Check the help menu for each function for details regarding input and output data structures, and all function parameters.

------------------------------------------------------------------------

## 🐛 Troubleshooting

### Common Issues

**Problem**: HMM fitting is slow.\
**Solution**: Use `HMMbehavrFast()` with `n_cores` set to your CPU core count - 1.

**Problem**: Plots look different from tutorial.\
**Solution**: Ensure you have the same versions of `ggplot2` and `patchwork` installed.

**Problem**: Heatmap hypnograms show greyed out days.\
**Solution**: The HMMs did not find a suitable solution for those days, rerun with higher number of iterations.

------------------------------------------------------------------------

## 📖 Citation

If you use FlyDreamR in your research, please cite:

```         
Ghosh, A. & Harbison, S.T. (2025). FlyDreamR: Hidden Markov Model-based 
sleep/wake inference from Drosophila activity data. GitHub repository.
```

------------------------------------------------------------------------

## 🤝 Contributing

Issues and pull requests are welcome! Please visit the [GitHub Issues page](https://github.com/orijitghosh/FlyDreamR/issues) to report bugs or request features.

------------------------------------------------------------------------

## 📧 Contact

For questions or support, please contact: - **Author**: Arijit Ghosh - **Issues**: <https://github.com/orijitghosh/FlyDreamR/issues>

------------------------------------------------------------------------

## 📄 License

This project is released under the [GNU General Public License, version 3 (GPL-3)](LICENSE).

------------------------------------------------------------------------
