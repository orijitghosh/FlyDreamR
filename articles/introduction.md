# Analyzing Sleep States with FlyDreamR

`FlyDreamR` is an R package for analyzing *Drosophila* Activity Monitor
(DAM) data, with workflows for:

- Preparing DAM master/monitor files for downstream analyses
- Traditional sleep metrics (sleep time, bout statistics, activity
  indices, brief awakenings)
- Hidden Markov Models (HMMs) to infer discrete behavioral states and
  visualize state dynamics
- An optional Shiny app for interactive analysis

This vignette gives a short roadmap and points you to the more focused
vignettes included with the package.

## What to read next

- **Getting data into FlyDreamR**:
  [`vignette("data-prep", package = "FlyDreamR")`](https://orijitghosh.github.io/FlyDreamR/articles/data-prep.md)
- **Traditional sleep analyses**:
  [`vignette("traditional-sleep", package = "FlyDreamR")`](https://orijitghosh.github.io/FlyDreamR/articles/traditional-sleep.md)
- **HMM fitting and visualization**:
  [`vignette("hmm-workflow", package = "FlyDreamR")`](https://orijitghosh.github.io/FlyDreamR/articles/hmm-workflow.md)
- **Running the Shiny app**:
  [`vignette("shiny-app", package = "FlyDreamR")`](https://orijitghosh.github.io/FlyDreamR/articles/shiny-app.md)

## Installation (typical options)

From GitHub (recommended)

``` r
# Install from GitHub (devtools or remotes)
install.packages(c('devtools','remotes'), repos='https://cloud.r-project.org')
remotes::install_github('orijitghosh/FlyDreamR', upgrade = 'never')
```

Then load the package:

``` r
library(FlyDreamR)
```

## Getting help

- Check documentation:
  [`?HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
- View examples: `example(HMMplot)`

## Citation

If you use FlyDreamR in your research, please cite:

    Ghosh A, Harbison ST. Inferring the genetic basis of sleep states in Drosophila melanogaster using hidden Markov models. bioRxiv. 2026: 2026.2001.2014.699526.
