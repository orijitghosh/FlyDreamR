# FlyDreamR <img src="https://img.shields.io/badge/R-%3E%3D%204.0-276DC3" align="right"/>

<img src="vignettes/FlyDreamR_logo.png" alt="FlyDreamR logo" width="200" align="right"/>

> **Infer Sleep/Wake States from locomotor activity data using hidden Markov models (HMMs).**

[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html) [![License: GPL-3](https://img.shields.io/badge/License-GPL--3-blue.svg)](LICENSE) [![Repo status](https://img.shields.io/badge/status-active-success)](#) [![Issues](https://img.shields.io/github/issues/orijitghosh/FlyDreamR.svg)](https://github.com/orijitghosh/FlyDreamR/issues)

**FlyDreamR** implements an iterative **hidden Markov model (HMM)** framework to infer *sleep* and *wake* states from *Drosophila* Activity Monitor (DAM) **activity counts**. It streamlines the entire analysis pipeline:

-   **Data Loading:** Import raw DAM monitor files and link them with experimental metadata.
-   **Pre-processing:** Clean data and engineer features for HMM analysis.
-   **Inference:** Infer sleep states using serial or parallel processing.
-   **Analysis:** Generate publication-ready visualizations and sleep metrics.

For detailed guides and walk through, visit <https://orijitghosh.github.io/FlyDreamR/>.

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
```

------------------------------------------------------------------------

### 📝 Data Preparation: Metadata File

To link your raw monitor files with experimental conditions, you must create a **Metadata CSV file**. This file maps each specific monitor file and channel to the corresponding fly's genotype and experiment timing.

-   **Format:** `.csv` (Comma Separated Values)
-   **Rows:** One row per fly (channel).

#### Required Columns

| Column Header        | Description                                                                                         | Example               |
|:---------------------|:----------------------------------------------------------------------------------------------------|:----------------------|
| **`file`**           | The full filename of the raw DAM monitor file, including the extension.                             | `Monitor1.txt`        |
| **`start_datetime`** | The exact date and time the experiment started (Format: `YYYY-MM-DD HH:MM:SS`).                     | `2025-02-12 06:04:00` |
| **`stop_datetime`**  | The exact date and time the experiment ended.                                                       | `2025-02-15 09:00:00` |
| **`region_id`**      | The specific channel number (1–32) on the DAM monitor for this fly.                                 | `1`                   |
| **`genotype`**       | The experimental genotype identifier or treatment group.                                            | `CantonS`             |
| **`replicate`**      | The replicate identifier. (Note: If you do not have replicates, that does not affect calculations). | `1`                   |
| **`sex`**            | The sex identifier. (Note: If you do not have different sexes, that does not affect calculations).  | `Female`              |

------------------------------------------------------------------------

## 💡 Common Issues

-   **Problem: HMM fitting is slow**

    **Solution:** Use `HMMbehavrFast()` with `n_cores` set to your CPU core count minus 1 to enable parallel processing.

-   **Problem: Plots look different from the tutorial**

    **Solution:** Ensure you have the latest versions of `ggplot2` and `patchwork` installed, as layout logic can vary between versions.

-   **Problem: Heatmap hypnograms show greyed out days**

    **Solution:** This indicates the HMM did not find a suitable solution for those days. Rerun the analysis with a higher number of iterations. If many days are greyed out, check if the fly died during experiment.

------------------------------------------------------------------------

## 📖 Citation

If you use FlyDreamR in your research, please cite:

```         
Ghosh A, Harbison ST. Inferring the genetic basis of sleep states in Drosophila melanogaster using hidden Markov models. bioRxiv. 2026: 2026.2001.2014.699526.
```

------------------------------------------------------------------------

## 🤝 Contributing

Issues and pull requests are welcome! Please visit the [GitHub Issues page](https://github.com/orijitghosh/FlyDreamR/issues) to report bugs or request features.

------------------------------------------------------------------------

## 📧 Contact

For questions or support, please contact the **Author**: Arijit Ghosh, and **Issues** can be documented at <https://github.com/orijitghosh/FlyDreamR/issues>.

------------------------------------------------------------------------

## 📄 License

This project is released under the [GNU General Public License, version 3 (GPL-3)](LICENSE).

------------------------------------------------------------------------
