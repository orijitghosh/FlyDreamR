# FlyDreamR ![](https://img.shields.io/badge/R-%3E%3D%204.0-276DC3)

![FlyDreamR logo](articles/FlyDreamR_logo.png)

> **Infer sleep/wake states from locomotor activity data using hidden
> Markov models (HMMs).**

[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![License:
GPL-3](https://img.shields.io/badge/License-GPL--3-blue.svg)](https://orijitghosh.github.io/FlyDreamR/LICENSE)
[![Repo status](https://img.shields.io/badge/status-active-success)](#)
[![Issues](https://img.shields.io/github/issues/orijitghosh/FlyDreamR.svg)](https://github.com/orijitghosh/FlyDreamR/issues)

**FlyDreamR** fits an iterative 4-state hidden Markov model to
*Drosophila* Activity Monitor (DAM) activity counts to classify each
minute of recording as sleep or wake. It covers the full pipeline:
loading raw monitor files, linking them to metadata, running the HMM
(serially or in parallel), and producing summary plots and metrics.

For detailed guides and walkthroughs, visit
<https://orijitghosh.github.io/FlyDreamR/>.

------------------------------------------------------------------------

## What it does

**Data preparation**
([`HMMDataPrep()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md)):
the first step in the pipeline. Reads raw DAM monitor files, links them
to your metadata, and returns a `behavr` table with day, light/dark
phase, and normalized activity calculated and ready for HMM fitting.

**Traditional sleep analysis**
([`calcTradSleep()`](https://orijitghosh.github.io/FlyDreamR/reference/calcTradSleep.md)):
define sleep as immobility of 5–60 minutes; returns bout counts, bout
lengths, activity index, brief awakenings, and day/phase summaries.

**HMM-based state inference**: fits a per-fly, per-day HMM with
configurable emission distributions and Viterbi decoding. Use
[`HMMbehavr()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
for serial fitting or
[`HMMbehavrFast()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavrFast.md)
for parallel fitting across CPU cores.

**Visualization**: heatmap hypnograms
([`HMMplot()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMplot.md)),
faceted group profiles
([`HMMFacetedPlot()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMFacetedPlot.md)),
and single-fly daily profiles
([`HMMSinglePlot()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMSinglePlot.md)).

**Shiny GUI**: a point-and-click interface for users who prefer not to
work in R directly.

------------------------------------------------------------------------

## Installation

``` r
install.packages(c('devtools', 'remotes'), repos = 'https://cloud.r-project.org')
remotes::install_github('orijitghosh/FlyDreamR', upgrade = 'never')
```

------------------------------------------------------------------------

## Data preparation: metadata file

You need a CSV file that maps each monitor channel to a fly’s
experimental conditions. One row per fly.

| Column | Description | Example |
|:---|:---|:---|
| `file` | Raw DAM monitor filename, including extension | `Monitor1.txt` |
| `start_datetime` | Experiment start (`YYYY-MM-DD HH:MM:SS`) | `2025-02-12 06:04:00` |
| `stop_datetime` | Experiment end (`YYYY-MM-DD HH:MM:SS`) | `2025-02-15 09:00:00` |
| `region_id` | Channel number on the DAM monitor (1–32) | `1` |
| `genotype` | Genotype or treatment group label | `CantonS` |
| `replicate` | Replicate identifier (won’t affect calculations if absent) | `1` |
| `sex` | Sex identifier (won’t affect calculations if absent) | `Female` |

The first five columns are required; `replicate` and `sex` are optional.

------------------------------------------------------------------------

## Common issues

**HMM fitting is slow:** Use
[`HMMbehavrFast()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavrFast.md)
and set `n_cores` to one less than your total CPU core count.

**Fitting has been running for more than 15 minutes:** If you’re already
using multiple cores, the most likely cause is dead flies in your data —
the algorithm can get stuck on flat activity traces. Check your data for
flies that stopped moving partway through the experiment.

**Plots look different from the tutorial:** Make sure you have the
latest versions of `ggplot2` and `patchwork` installed, as their layout
logic has changed across versions.

**Heatmap hypnograms show greyed-out days:** This means the HMM did not
converge for those days. Try rerunning with a higher iteration limit. If
many days are greyed out for the same fly, it probably died during the
experiment.

------------------------------------------------------------------------

## Citation

If you use FlyDreamR in your research, please cite:

> Ghosh, Arijit, and Susan T. Harbison. “Inferring the genetic basis of
> sleep states in *Drosophila melanogaster* using hidden Markov models.”
> *bioRxiv* (2026): 2026-01.

------------------------------------------------------------------------

## Contributing

Bug reports and pull requests are welcome. Please use the [GitHub Issues
page](https://github.com/orijitghosh/FlyDreamR/issues).

------------------------------------------------------------------------

## Contact

**Author:** Arijit Ghosh. For bugs and feature requests, open an issue
at <https://github.com/orijitghosh/FlyDreamR/issues>.

------------------------------------------------------------------------

## License

Released under the [GNU General Public License v3
(GPL-3)](https://orijitghosh.github.io/FlyDreamR/LICENSE).
