# HMM fitting and visualization

This vignette walks through the Hidden Markov Model (HMM) workflow in
FlyDreamR, including fitting and plotting.

## Fit an HMM

After preparing your dataset with
[`HMMDataPrep()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md),
you can fit an HMM using:

- [`HMMbehavr()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
  (single-threaded)
- [`HMMbehavrFast()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavrFast.md)
  (parallel; faster on multi-core machines)

``` r
# Load demo data
meta_file <- system.file("extdata", "Metadata_Monitor1.csv", package = "FlyDreamR")
data_dir <- system.file("extdata", package = "FlyDreamR")
dt <- HMMDataPrep(
  metafile_path = meta_file,
  result_dir    = data_dir,
  ldcyc         = 12,
  day_range     = c(1, 2)
)

# Serial
res <- HMMbehavr(behavtbl = dt, it = 100, ldcyc = 12)

# Parallel
res_prl <- HMMbehavrFast(behavtbl = dt, it = 100, ldcyc = 12, n_cores = 4)
```

## Plot HMM state profiles

FlyDreamR provides convenient plotting helpers:

- [`HMMplot()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMplot.md)
  for heatmap hypnograms
- [`HMMFacetedPlot()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMFacetedPlot.md)
  to facet individual hypnograms
- [`HMMSinglePlot()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMSinglePlot.md)
  to save individual hypnograms to disk

``` r
# Heatmap hypnograms
HMMplot(res)

# Use a different built-in palette
HMMplot(res, color_palette = "AG")

# Compare serial vs parallel fits
library(patchwork)
HMMplot(res, color_palette = "AG") / HMMplot(res_prl, color_palette = "AG")

# User-defined colors
HMMplot(
  res,
  color_palette = "user",
  user_colors = c(
    "State0" = "#FF0060",
    "State1" = "#F6FA70",
    "State2" = "#00DFA2",
    "State3" = "#0079FF"
  )
)

# Faceted + save-to-disk helpers
HMMFacetedPlot(res)
HMMSinglePlot(res)
```

## Summarize time spent in each state

The HMM results typically include:

- `TimeSpentInEachState` (summaries)
- `VITERBIDecodedProfile` (decoded state sequences)

You can visualize time spent per state with `ggplot2`:

``` r
ggplot2::ggplot(res$TimeSpentInEachState,
                ggplot2::aes(x = state_name, y = time_spent, fill = state_name)) +
  ggplot2::geom_boxplot(width = 0.35, outliers = FALSE) +
  ggplot2::facet_grid(day ~ phase, scales = "free_y") +
  ggplot2::theme_minimal()
```
