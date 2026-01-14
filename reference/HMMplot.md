# Plot HMM Inferred Sleep States as Tile Heatmap

Creates a tile-based heatmap visualization of Hidden Markov Model
inferred behavioral states. Each individual is represented as a
horizontal row, with time on the x-axis and states shown as colored
tiles. Days are displayed as separate facets.

This visualization provides a compact overview of state patterns across
many individuals, making it easy to identify population-level trends and
individual variability in sleep/wake architecture.

## Usage

``` r
HMMplot(hmm_inference_list, color_palette = "default", user_colors = NULL)
```

## Arguments

- hmm_inference_list:

  A list, typically the output from
  [`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
  or
  [`HMMbehavrFast`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavrFast.md).
  The second element must be a data frame (`VITERBIDecodedProfile`) with
  columns: `timestamp`, `ID`, `state_name`, and `day`.

- color_palette:

  Character string specifying which color palette to use. Options:

  `"default"`

  :   Standard FlyDreamR colors (recommended)

  `"AG"`

  :   Alternative palette with warmer tones

  `"user"`

  :   Custom user-defined colors (requires `user_colors`)

  Default: `"default"`.

- user_colors:

  A named character vector specifying custom colors for each state.
  **Only used when `color_palette = "user"`**. Must include all state
  names found in the data. Format:
  `c("State0" = "#RRGGBB", "State1" = "#RRGGBB", ...)`

  If `color_palette = "user"` but this parameter is `NULL` or
  incomplete, an error will be raised.

## Value

A `ggplot2` object showing:

- **X-axis**: Time in hours (converted from minutes)

- **Y-axis**: Individual IDs (discrete)

- **Tiles**: Colored by state at each time point

- **Facets**: Separate panels for each day

- **Aspect ratio**: Dynamically calculated based on number of
  individuals

The returned object can be customized using standard `ggplot2` syntax.

## Details

### Color Palettes

All palettes follow the same principle: warm colors = wake, cool colors
= sleep

**"default" palette:**

- State0: \#f75c46 (coral, active wake)

- State1: \#ffa037 (orange, quiet wake)

- State2: \#33c5e8 (cyan, light sleep)

- State3: \#004a73 (navy, deep sleep)

**"AG" palette:**

- State0: \#fb8500

- State1: \#ffb703

- State2: \#8ecae6

- State3: \#219ebc

### When to Use This Plot

Use `HMMplot` when you want to:

- Compare many individuals simultaneously

- Identify population-level patterns (e.g., siesta in midday)

- Screen for outlier individuals

- Create compact publication figures

For detailed examination of individual state transitions, consider
[`HMMFacetedPlot`](https://orijitghosh.github.io/FlyDreamR/reference/HMMFacetedPlot.md)
instead.

## See also

[`HMMFacetedPlot`](https://orijitghosh.github.io/FlyDreamR/reference/HMMFacetedPlot.md)
for detailed multi-panel visualization
[`HMMSinglePlot`](https://orijitghosh.github.io/FlyDreamR/reference/HMMSinglePlot.md)
for saving individual plots
[`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
for generating input data

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage with default palette
hmm_results <- HMMbehavr(processed_data)
p <- HMMplot(hmm_results)
print(p)

# Try alternative palette
p_ag <- HMMplot(hmm_results, color_palette = "AG")

# Use custom colors (e.g., for colorblind-friendly palette)
custom_colors <- c(
  "State0" = "#D55E00",  # vermillion
  "State1" = "#E69F00",  # orange
  "State2" = "#56B4E9",  # sky blue
  "State3" = "#0072B2"   # blue
)
p_custom <- HMMplot(
  hmm_results,
  color_palette = "user",
  user_colors = custom_colors
)

# Save high-resolution figure
ggsave("hmm_states_overview.pdf", p,
       width = 10, height = 6, dpi = 300)

# Further customize
library(ggplot2)
p +
  labs(title = "Sleep/Wake States Across Population",
       subtitle = "Wildtype controls, LD 12:12") +
  theme(legend.position = "right")
} # }
```
