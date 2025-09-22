---
editor_options: 
  markdown: 
    wrap: 72
---

# FlyDreamR <img src="https://img.shields.io/badge/R-%3E%3D%204.0-276DC3" align="right"/>

![](/FlyDreamR_logo.png){style="float:right;" width="200"}

> **Run the Ghosh–Harbison Hidden Markov Model on Activity Counts to
> Infer Sleep/Wake States**

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![License:
MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Repo status](https://img.shields.io/badge/status-active-success)](#)
[![Issues](https://img.shields.io/github/issues/orijitghosh/FlyDreamR.svg)](https://github.com/orijitghosh/FlyDreamR/issues)

`FlyDreamR` implements the **Ghosh–Harbison Hidden Markov Model (HMM)**
to infer *sleep* and *wake* states from *Drosophila* Activity Monitor
(DAM) **activity counts**. It wraps the full workflow — **metadata → DAM
loading → cleaning & feature engineering → HMM inference (serial or
parallel) → plotting → summary metrics** — on top of the excellent
`behavr`/`damr` ecosystem.

------------------------------------------------------------------------

## ✨ Highlights

-   **End-to-end pipeline**: from metadata to publication-ready figures.
-   **Robust inference** with a configurable HMM (`depmixS4`) and
    Viterbi decoding.
-   **Parallel execution** via `HMMbehavrFast()` for big cohorts.
-   **Plotting helpers**: single-individual, faceted, and compact time
    series.
-   **Traditional sleep metrics** (`calcTradSleep()`): bout
    counts/lengths, activity index, brief awakenings, day/phase
    summaries.
-   **Works with `behavr` tables** and `damr::load_dam()` streams.
-   **MIT-licensed** and friendly to scripting + pipelines.

------------------------------------------------------------------------

## 📦 Installation

\`\`\`r \# install from GitHub (devtools or remotes)
install.packages(c('devtools','remotes'),
repos='<https://cloud.r-project.org>')
remotes::install_github('orijitghosh/FlyDreamR', upgrade = 'never')
