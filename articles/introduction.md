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

If you have a source tarball (e.g., `FlyDreamR_1.0.0.tar.gz`), you can
install from source:

``` r
install.packages(c("devtools", "ggplot2", "ggetho", "magrittr", "patchwork"))

d <- tempdir()
untar("FlyDreamR_1.0.0.tar.gz", compressed = "gzip", exdir = d)
devtools::install(file.path(d, "FlyDreamR"),
                  dependencies = TRUE,
                  repos = "https://cloud.r-project.org/")
```

Then load the package:

``` r
library(FlyDreamR)
```

## Getting help

- Check documentation:
  [`?HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
- View examples: `example(HMMplot)`
- Report issues / request features: add your preferred tracker link in
  `DESCRIPTION` (e.g., `URL` / `BugReports`)

## Citation

If you use FlyDreamR in your research, please cite:

    Ghosh, A. & Harbison, S.T. (2026). Inferring the genetic basis of sleep states in Drosophila melanogaster using Hidden Markov models. GitHub repository.
