# Package index

## Metadata & Data Import

Functions to convert raw master files into the metadata format required
to link experimental conditions with monitor files.

- [`convMasterToMeta()`](https://orijitghosh.github.io/FlyDreamR/reference/convMasterToMeta.md)
  : Convert Master File to FlyDreamR Metadata Format
- [`convMasterToMetaBatch()`](https://orijitghosh.github.io/FlyDreamR/reference/convMasterToMetaBatch.md)
  : Batch Convert Multiple Master Files to FlyDreamR Metadata Format

## Data Preparation

Functions to load DAM activity data, link it with metadata, and
calculate normalized activity and phases.

- [`HMMDataPrep()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md)
  : Prepare DAM Activity Data for HMM Analysis

## HMM Analysis

The core functions for running Hidden Markov Models to infer sleep/wake
states.

- [`HMMbehavr()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
  : Infer Sleep States Using Hidden Markov Model
- [`HMMbehavrFast()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavrFast.md)
  : Parallel Hidden Markov Model for Sleep State Inference

## Visualization

Tools for visualizing inferred states using heatmaps, faceted plots, or
individual profiles.

- [`HMMplot()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMplot.md)
  : Plot HMM Inferred Sleep States as Tile Heatmap
- [`HMMFacetedPlot()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMFacetedPlot.md)
  : Create Faceted Plot of HMM Inferred States
- [`HMMSinglePlot()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMSinglePlot.md)
  : Save Individual HMM State Plots to Disk

## Traditional Metrics

Functions to calculate standard sleep metrics (immobility bouts) for
comparison with HMM results.

- [`calcTradSleep()`](https://orijitghosh.github.io/FlyDreamR/reference/calcTradSleep.md)
  : Calculate Comprehensive Sleep Metrics from Activity Data

## Interactive Analysis

Functions to launch the graphical user interface (Shiny App).

- [`runFlyDreamRApp()`](https://orijitghosh.github.io/FlyDreamR/reference/runFlyDreamRApp.md)
  : Launch the FlyDreamR Shiny App
