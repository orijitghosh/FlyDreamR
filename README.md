# FlyDreamR <img src="https://img.shields.io/badge/R-%3E%3D%204.0-276DC3" align="right"/>

<img src="man/figures/FlyDreamR_logo.png" align="right" width="120"/>

> **Infer sleep/wake states from locomotor activity data using hidden Markov models (HMMs).**

[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html) [![License: GPL-3](https://img.shields.io/badge/License-GPL--3-blue.svg)](LICENSE) [![Repo status](https://img.shields.io/badge/status-active-success)](#) [![Issues](https://img.shields.io/github/issues/orijitghosh/FlyDreamR.svg)](https://github.com/orijitghosh/FlyDreamR/issues)

**FlyDreamR** fits an iterative hidden Markov model to *Drosophila* Activity Monitor (DAM) activity counts. The default is four states; users can also fit three or five activity-ordered states. It covers loading raw monitor files, linking metadata, fitting serially or in parallel, and producing plots and summaries.

For detailed guides and walkthroughs, visit <https://orijitghosh.github.io/FlyDreamR/>.

------------------------------------------------------------------------

## What it does

**Data preparation** (`HMMDataPrep()`): the first step in the pipeline. Reads raw DAM monitor files, links them to your metadata, and returns a `behavr` table with day, light/dark phase, and normalized activity calculated and ready for HMM fitting. Set `removeDeadAnimals = TRUE` to remove the day of suspected death and later days.

**Traditional sleep analysis** (`calcTradSleep()`): define sleep as immobility of 5–60 minutes; returns bout counts, bout lengths, activity index, brief awakenings, and day/phase summaries.

**HMM-based state inference**: fits a per-fly, per-day Gaussian HMM with Viterbi decoding. Use `HMMbehavr()` for serial fitting or `HMMbehavrFast()` for parallel fitting across CPU cores. Both accept `n_states = 3`, `4`, or `5` and return a `QualityReport` with failed fly-days and reasons. Biological state names in the documentation apply to the four-state default.

**Visualization**: heatmap hypnograms (`HMMplot()`), faceted group profiles (`HMMFacetedPlot()`), and single-fly daily profiles (`HMMSinglePlot()`).

**Shiny GUI**: a point-and-click interface for users who prefer not to work in R directly.

------------------------------------------------------------------------

## Installation

``` r
install.packages('remotes', repos = 'https://cloud.r-project.org')
remotes::install_github('orijitghosh/FlyDreamR', upgrade = 'never')
```

------------------------------------------------------------------------

## Data preparation: metadata file

You need a CSV file that maps each monitor channel to a fly's experimental conditions. One row per fly.

| Column | Description | Example |
|:-----------------------|:-----------------------|:-----------------------|
| `file` | Raw DAM monitor filename, including extension | `Monitor1.txt` |
| `start_datetime` | Experiment start (`YYYY-MM-DD HH:MM:SS`) | `2025-02-12 06:04:00` |
| `stop_datetime` | Experiment end (`YYYY-MM-DD HH:MM:SS`) | `2025-02-15 09:00:00` |
| `region_id` | Channel number on the DAM monitor (1–32) | `1` |
| `genotype` | Genotype or treatment group label | `CantonS` |
| `replicate` | Replicate identifier (won't affect calculations if absent) | `1` |
| `sex` | Sex identifier (won't affect calculations if absent) | `Female` |

The first five columns are required; `replicate` and `sex` are optional.

------------------------------------------------------------------------

## Common issues

**HMM fitting is slow:** Use `HMMbehavrFast()` and set `n_cores` to one less than your total CPU core count.

**Fitting has been running for more than 15 minutes:** Check for flat activity traces. Use `removeDeadAnimals = TRUE` in `HMMDataPrep()` to exclude the suspected death day and later days, then review the `QualityReport` for any remaining fit failures.

**Plots look different from the tutorial:** Make sure you have the latest versions of `ggplot2` and `patchwork` installed, as their layout logic has changed across versions.

**Heatmap hypnograms show greyed-out days:** Check `QualityReport` for the affected fly-days and reasons. A higher iteration limit may help if no valid solution was found.

------------------------------------------------------------------------

## Citation

If you use FlyDreamR in your research, please cite:

> Ghosh, Arijit, and Susan T. Harbison. "Inferring the genetic basis of sleep states in *Drosophila melanogaster* using hidden Markov models." *bioRxiv* (2026): 2026-01.

------------------------------------------------------------------------

## Contributing

Bug reports and pull requests are welcome. Please use the [GitHub Issues page](https://github.com/orijitghosh/FlyDreamR/issues).

------------------------------------------------------------------------

## Contact

**Author:** Arijit Ghosh. For bugs and feature requests, open an issue at <https://github.com/orijitghosh/FlyDreamR/issues>.

------------------------------------------------------------------------

## License

Released under the [GNU General Public License v3 (GPL-3)](LICENSE).
