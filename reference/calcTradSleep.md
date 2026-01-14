# Calculate Comprehensive Sleep Metrics from Activity Data

Processes activity data to calculate traditional sleep metrics including
sleep duration, activity index during wakefulness, brief awakenings, and
detailed sleep bout characteristics. This function implements standard
sleep analysis metrics commonly used in Drosophila sleep research.

A "brief awakening" is defined as a single time point of movement that
is immediately preceded and followed by immobility, potentially
indicating fragmented or shallow sleep.

## Usage

``` r
calcTradSleep(dt_test)
```

## Arguments

- dt_test:

  A `data.table` containing activity and sleep state data, typically the
  output from
  [`HMMDataPrep`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md).
  Must contain the following columns:

  - `id`: Unique identifier for each individual

  - `moving`: Logical indicator of movement

  - `asleep`: Logical indicator of sleep state

  - `activity`: Numeric activity count

  - `phase`: Factor with levels "Light" and "Dark"

  - `day`: Integer day number

  - `genotype`: Character or factor indicating genotype

  - `replicate`: Character or factor indicating replicate ID

## Value

A named list containing seven `data.table` objects with sleep metrics
(all time values in **minutes**):

- `brief_awakenings_data`:

  Original data with added `brief_awakenings` column (logical)

- `sleep_summary_phase`:

  Total sleep time per phase (Light/Dark) and day for each individual

- `sleep_summary_whole_day`:

  Total sleep time per day for each individual

- `activity_index_phase`:

  Mean activity during wakefulness per phase and day (total activity /
  time awake)

- `activity_index_whole_day`:

  Mean activity during wakefulness per day

- `bout_summary_day`:

  Detailed sleep bout metrics per day including:

  - `latency`: Time to first sleep bout (minutes from day start)

  - `first_bout_length`: Duration of first sleep bout

  - `latency_to_longest_bout`: Time to longest bout

  - `length_longest_bout`: Duration of longest bout

  - `n_bouts`: Number of sleep bouts

  - `mean_bout_length`: Average bout duration

  - `total_bout_length`: Total sleep time from bouts

- `bout_summary_phase`:

  Sleep bout metrics per phase and day

## Details

The function calculates metrics separately for light and dark phases
based on the `phase` column. Sleep bouts are identified using
[`bout_analysis`](https://rdrr.io/pkg/sleepr/man/bout_analysis.html)
from the `sleepr` package.

Activity index provides a measure of movement intensity during wake
periods, which can indicate arousal threshold or sleep depth.

## See also

[`HMMDataPrep`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md)
for preparing input data
[`bout_analysis`](https://rdrr.io/pkg/sleepr/man/bout_analysis.html) for
bout detection algorithm

## Examples

``` r
if (FALSE) { # \dontrun{
# Assume 'processed_data' is output from HMMDataPrep()
sleep_metrics <- calcTradSleep(processed_data)

# Access individual metric tables
daily_bouts <- sleep_metrics$bout_summary_day
phase_sleep <- sleep_metrics$sleep_summary_phase

# View brief awakening data
head(sleep_metrics$brief_awakenings_data)

# Summary statistics
summary(sleep_metrics$sleep_summary_whole_day$time_spent_sleeping)
} # }
```
