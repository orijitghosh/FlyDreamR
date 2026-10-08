# Running the FlyDreamR Shiny app

FlyDreamR can be used entirely from the console, but it also ships with
a Shiny app for interactive analysis.

## Launch the app

``` r

##Launch the interactive interface
runFlyDreamRApp()
```

## Notes

- On **Data input**, select 3, 4, or 5 HMM states and optionally remove
  the suspected death day and later days before fitting.
- The **Download data** panel shows the `QualityReport` and offers a CSV
  download. Review failed fly-days before interpreting results.
- The first launch may install additional packages (depending on how the
  app is configured).
- For intramural/shared use, the app can also be deployed to a Shiny
  Server / Posit Connect environment.
