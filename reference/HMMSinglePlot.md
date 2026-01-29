# Save Individual HMM State Plots to Disk

Generates and saves individual plots of HMM-inferred sleep states to PNG
files. Creates one plot per individual per day, organized in a directory
structure by genotype. Each plot shows the time-series of state
assignments with a light/dark phase annotation.

**Note:** This function is designed for batch processing and
automatically saves plots to disk. It does not return plots for
interactive viewing. For interactive plotting, use
[`HMMplot`](https://orijitghosh.github.io/FlyDreamR/reference/HMMplot.md)
or
[`HMMFacetedPlot`](https://orijitghosh.github.io/FlyDreamR/reference/HMMFacetedPlot.md).

## Usage

``` r
HMMSinglePlot(HMMinferList, col_palette = "default")
```

## Arguments

- HMMinferList:

  A list, typically the output from
  [`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md).
  The second element (`HMMinferList[[2]]`) must be a data frame with the
  `VITERBIDecodedProfile` containing: `ID`, `day`, `timestamp`,
  `state_name`, and `genotype`.

- col_palette:

  Character string specifying the color palette. Options:

  `"default"`

  :   Standard FlyDreamR colors

  `"AG"`

  :   Alternative palette

  Default: `"default"`.

## Value

`NULL`. This function is called for its side effect of saving plot files
to disk. It does not return plot objects.

## Details

### File Organization

Plots are saved with the following structure:

    ./profiles_all/
      └── [Genotype]/
          ├── [ID]_day1_4states.png
          ├── [ID]_day2_4states.png
          └── ...

\## File Naming Each file is named: `[ID]_day[N]_4states.png`

- ID is sanitized (timestamps and pipe characters removed)

- Day number is appended

- Suffix "\_4states" indicates 4-state HMM

### Directory Creation

The function automatically creates necessary directories:

- Base directory: `./profiles_all/`

- Subdirectories for each unique genotype

### Error Handling

- If state separation fails for an individual-day, that plot is skipped
  silently (wrapped in `tryCatch`)

- If directory creation fails, file save is skipped

- Progress is printed to console for each file

### Performance

For large datasets:

- 32 individuals × 3 days = 96 PNG files

- Approximate time: 30-60 seconds

- Disk space: ~100-200 KB per plot

## Note

This function is most useful for:

- Creating archival records of individual results

- Manual inspection of individual flies

- Sharing results with collaborators

- Supplementary materials for publications

For interactive analysis or presentation figures, consider using
[`HMMplot`](https://orijitghosh.github.io/FlyDreamR/reference/HMMplot.md)
or
[`HMMFacetedPlot`](https://orijitghosh.github.io/FlyDreamR/reference/HMMFacetedPlot.md)
instead, which return ggplot objects that can be customized and viewed
interactively.

## See also

[`HMMplot`](https://orijitghosh.github.io/FlyDreamR/reference/HMMplot.md)
for interactive tile plot
[`HMMFacetedPlot`](https://orijitghosh.github.io/FlyDreamR/reference/HMMFacetedPlot.md)
for interactive faceted plot
[`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
for generating input data

## Examples

``` r
if (FALSE) { # \dontrun{
# Generate HMM results
hmm_results <- HMMbehavr(processed_data)

# Save all plots with default colors
HMMSinglePlot(hmm_results)

# Save with alternative palette
HMMSinglePlot(hmm_results, col_palette = "AG")

# Check output directory structure
list.dirs("./profiles_all", recursive = TRUE)

# List all generated files
list.files("./profiles_all",
           pattern = "\\.png$",
           recursive = TRUE)
} # }
```
