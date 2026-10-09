# FlyDreamR 1.0.0

## Data preparation and HMM analysis

-   Added optional suspected dead-fly removal in `HMMDataPrep()`.
-   Added 3- and 5-state HMM fitting alongside the four-state default.
-   Added a per-fly-day `QualityReport` and clearer fit errors in console and Shiny workflows.

## New Features

-   Added parallelized HMM fitting with `HMMbehavrFast()`
-   Implemented comprehensive traditional sleep analysis with `calcTradSleep()`
-   Created interactive Shiny app for GUI-based analysis
-   Added multiple visualization functions: `HMMplot()`, `HMMFacetedPlot()`, `HMMSinglePlot()`
-   The `FlyDreamR` preprint is now [online](https://www.biorxiv.org/content/10.64898/2026.01.14.699526v1)

## Bug Fixes

-   Fixed metadata conversion for multiple monitor files

## Documentation

-   Added comprehensive vignettes for all analysis types
-   Improved function documentation with examples

## AI use disclosure

The FlyDreamR logo and animated fruit-fly GIFs were created with generative AI. AI tools also assisted with creating the Shiny app from the package. The package authors remain responsible for the software and its scientific content.

# FlyDreamR 0.1.2

-   Initial release
-   Basic HMM functionality
-   Traditional sleep metrics

# FlyDreamR 0.1.1

-   Development version
