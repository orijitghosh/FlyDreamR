# Create Faceted Plot of HMM Inferred States

Generates a multi-panel visualization of Hidden Markov Model inferred
behavioral states across multiple individuals and days. Each panel shows
the time-series of state assignments for one individual on one day, with
states color-coded by activity level.

This visualization is ideal for examining state dynamics across
experimental conditions, comparing individuals, or assessing day-to-day
consistency in sleep/wake patterns.

## Usage

``` r
HMMFacetedPlot(HMMinferList, col_palette = "default")
```

## Arguments

- HMMinferList:

  A list, typically the output from
  [`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
  or
  [`HMMbehavrFast`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavrFast.md).
  The second element (`HMMinferList[[2]]`) must be a data frame
  containing the `VITERBIDecodedProfile` with columns:

  - `ID`: Individual identifier

  - `day`: Day number

  - `timestamp`: Time point index (1 to 1440 for minute resolution)

  - `state_name`: State label (State0, State1, State2, State3)

  - `genotype`: Genotype identifier

- col_palette:

  Character string specifying the color palette. Options:

  `"default"`

  :   Standard FlyDreamR colors (red-orange for wake, blue for sleep)

  `"AG"`

  :   Alternative warm/cool palette

  Default: `"default"`.

## Value

A `ggplot2` object displaying a faceted plot with:

- **X-axis**: Time in hours (0-24)

- **Y-axis**: State names (State0 through State3)

- **Facets**: One panel per individual-day combination, arranged in a
  grid. Facet labels show ID and "Day: N"

- **Colors**: States colored by activity level (warm = active, cool =
  sleep)

- **Light/Dark annotation**: Black bar at bottom with white overlay
  indicating light phase

The plot can be further customized using standard `ggplot2` functions or
saved using [`ggsave()`](https://rdrr.io/pkg/ggplot2/man/ggsave.html).

## Details

### Color Palettes

**Default palette:**

- State0 (active wake): \#f75c46 (coral red)

- State1 (quiet wake): \#ffa037 (orange)

- State2 (light sleep): \#33c5e8 (light blue)

- State3 (deep sleep): \#004a73 (dark blue)

**AG palette:**

- State0: \#fb8500 (bright orange)

- State1: \#ffb703 (yellow-orange)

- State2: \#8ecae6 (sky blue)

- State3: \#219ebc (ocean blue)

### Faceting

Panels are arranged using `facet_wrap(~ ID + day)` with:

- Custom labeller adding "Day: " prefix to day numbers

- Shared axes across all panels

- Strip text showing individual ID and day

### Performance

For large datasets (many individuals/days), plot generation may take
several seconds. Progress is shown via a progress bar during data
preparation.

## See also

[`HMMplot`](https://orijitghosh.github.io/FlyDreamR/reference/HMMplot.md)
for tile-based visualization
[`HMMSinglePlot`](https://orijitghosh.github.io/FlyDreamR/reference/HMMSinglePlot.md)
for individual plots saved to files
[`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
for generating input data

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage with default colors
hmm_results <- HMMbehavr(processed_data)
plot <- HMMFacetedPlot(hmm_results)
print(plot)

# Use alternative color palette
plot_ag <- HMMFacetedPlot(hmm_results, col_palette = "AG")

# Save to file
ggsave("hmm_states_faceted.png", plot,
       width = 12, height = 8, dpi = 300)

# Further customize with ggplot2
library(ggplot2)
plot +
  theme(strip.text = element_text(size = 8)) +
  labs(title = "HMM Inferred States Across Individuals")

# Focus on specific genotype
results_filtered <- hmm_results
results_filtered[[2]] <- results_filtered[[2]] %>%
  filter(genotype == "wildtype")
plot_wt <- HMMFacetedPlot(results_filtered)
} # }
```
