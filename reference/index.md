# Package index

## Metadata & Data Import

Convert raw master files into the metadata format required to link
experimental conditions with monitor files.

- [`convMasterToMeta()`](https://orijitghosh.github.io/FlyDreamR/reference/convMasterToMeta.md)
  : Convert Master File to FlyDreamR Metadata Format
- [`convMasterToMetaBatch()`](https://orijitghosh.github.io/FlyDreamR/reference/convMasterToMetaBatch.md)
  : Batch Convert Multiple Master Files to FlyDreamR Metadata Format

## Data Preparation

Load DAM activity data, link it with metadata, and calculate normalized
activity, day number, and light/dark phase.

- [`HMMDataPrep()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md)
  : Prepare DAM Activity Data for HMM Analysis

## HMM Analysis

Fit hidden Markov models to infer sleep and wake states from activity
counts, serially or in parallel.

- [`HMMbehavr()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
  : Infer Sleep States Using Hidden Markov Model
- [`HMMbehavrFast()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavrFast.md)
  : Parallel Hidden Markov Model for Sleep State Inference

## Visualization

Plot inferred states as heatmap hypnograms, faceted group profiles, or
individual daily profiles.

- [`HMMplot()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMplot.md)
  : Plot HMM Inferred Sleep States as Tile Heatmap
- [`HMMFacetedPlot()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMFacetedPlot.md)
  : Create Faceted Plot of HMM Inferred States
- [`HMMSinglePlot()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMSinglePlot.md)
  : Save Individual HMM State Plots to Disk

## Traditional Sleep Metrics

Calculate standard immobility-based sleep metrics for comparison with
HMM results.

- [`calcTradSleep()`](https://orijitghosh.github.io/FlyDreamR/reference/calcTradSleep.md)
  : Calculate Comprehensive Sleep Metrics from Activity Data

## Shiny App

Launch the interactive GUI for point-and-click analysis.

- [`runFlyDreamRApp()`](https://orijitghosh.github.io/FlyDreamR/reference/runFlyDreamRApp.md)
  : Launch the FlyDreamR Shiny App
