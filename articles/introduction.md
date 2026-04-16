# Analyzing Sleep States with FlyDreamR

The standard way to measure sleep in *Drosophila*, calling any
five-minute stretch of immobility “sleep”, flattens what is almost
certainly a richer biological signal. **FlyDreamR** fits a hidden Markov
model to your DAM activity data to recover that signal, classifying each
minute of recording into distinct sleep and wake states rather than
applying a single arbitrary threshold.

This vignette is a quick roadmap. If you want to get straight to
analysis, pick the vignette that matches your goal.

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
