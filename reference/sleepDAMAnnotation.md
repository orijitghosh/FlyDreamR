# Annotate Sleep Bouts in DAM Activity Data

Internal function that annotates sleep bouts based on immobility
duration. Used automatically by
[`HMMDataPrep`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md)
via [`damr::load_dam`](https://rdrr.io/pkg/damr/man/load_dam.html).

This function is a modified version of
[`sleepr::sleep_dam_annotation`](https://rdrr.io/pkg/sleepr/man/sleep_annotation.html)
tailored for the FlyDreamR workflow. It identifies periods of immobility
(activity = 0) and classifies them as sleep if they meet the duration
criteria.

## Usage

``` r
sleepDAMAnnotation(
  data,
  min_time_immobile = c(behavr::mins(5), behavr::mins(1440))
)
```

## Arguments

- data:

  A `data.table` containing activity data for one or more animals. Must
  include columns:

  - `activity`: Numeric activity counts (beam crossings)

  - `t`: Time in seconds

  If the data.table has a key (typically `id`), processing is done
  separately for each individual.

- min_time_immobile:

  A numeric vector of length 2 specifying the minimum and maximum
  duration (in seconds) for an immobility bout to be classified as
  sleep. Format: `c(min_duration, max_duration)`.

  **Default**: `c(behavr::mins(5), behavr::mins(1440))`

  - Minimum: 5 minutes (300 seconds) - standard Drosophila sleep
    definition

  - Maximum: 1440 minutes (86400 seconds, 24 hours) - effectively
    unlimited

  **Common alternatives:**

  - `c(behavr::mins(1), behavr::mins(1440))`: 1-minute threshold

  - `c(behavr::mins(10), behavr::mins(1440))`: 10-minute threshold

## Value

The input `data.table` with two new logical columns:

- `moving`:

  `TRUE` if activity \> 0, `FALSE` otherwise

- `asleep`:

  `TRUE` if the time point is part of an immobility bout meeting the
  duration criteria, `FALSE` otherwise

## Details

### Sleep Definition

Sleep is defined using the standard Drosophila behavioral criterion:
**Immobility lasting at least 5 minutes**

### Processing by Individual

If `data` has a key set (e.g., `id`), the function automatically
processes each individual separately. This ensures that bouts don't span
across different animals.

### Integration with FlyDreamR

This function is called internally by
[`damr::load_dam`](https://rdrr.io/pkg/damr/man/load_dam.html) when
invoked from
[`HMMDataPrep`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md).
Users can customize the threshold by passing `min_time_immobile` to
`HMMDataPrep` via the `...` argument.

## References

Hendricks, J. C., Finn, S. M., Panckeri, K. A., Chavkin, J., Williams,
J. A., Sehgal, A., & Pack, A. I. (2000). Rest in Drosophila is a
sleep-like state. Neuron, 25(1), 129-138.

## See also

[`HMMDataPrep`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md)
for using this function via the standard workflow
[`bout_analysis`](https://rdrr.io/pkg/sleepr/man/bout_analysis.html) for
bout detection algorithm
[`sleep_dam_annotation`](https://rdrr.io/pkg/sleepr/man/sleep_annotation.html)
for the original function

## Examples

``` r
if (FALSE) { # \dontrun{
# This function is typically not called directly by users
# Instead, customize it through HMMDataPrep:

# Use 10-minute sleep threshold
data <- HMMDataPrep(
  metafile_path = "metadata.csv",
  min_time_immobile = c(behavr::mins(10), behavr::mins(1440))
)

# Use 1-minute threshold (very sensitive)
data <- HMMDataPrep(
  metafile_path = "metadata.csv",
  min_time_immobile = c(behavr::mins(1), behavr::mins(1440))
)

# If calling directly (advanced use):
library(data.table)
dt <- data.table(
  t = 1:1000,
  activity = sample(0:10, 1000, replace = TRUE)
)
dt_annotated <- sleepDAMAnnotation(dt)
head(dt_annotated)
} # }
```
