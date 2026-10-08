# Infer Sleep States Using Hidden Markov Model

Applies a Hidden Markov Model (HMM) to behavioral activity data to infer
discrete sleep/wake states. States are ordered by activity level, with
State0 representing the highest activity. Four states remain the
default.

The function fits an HMM with Gaussian emission distributions for
normalized activity levels. Multiple iterations are performed for each
individual and day to ensure robust state inference, with the most
frequently inferred state at each time point selected as the final
classification.

## Usage

``` r
HMMbehavr(behavtbl, it = 100, ldcyc = NULL, n_states = 4L)
```

## Arguments

- behavtbl:

  A `behavr` table (data.frame/data.table) containing behavioral data.
  Must include columns: `id`, `day`, `normact` (normalized activity),
  `genotype`, and `t` (time in seconds). Additional metadata columns
  (e.g., `sex`, `treatment`) will be automatically included in output
  summaries. Typically the output from
  [`HMMDataPrep`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md).

- it:

  Integer specifying the number of HMM fitting iterations per individual
  per day. Must be \>= 100 (enforced). Higher values increase robustness
  but require more computation time. Default: 100.

  Each iteration fits an HMM with random initialization. The final state
  assignment at each time point is determined by majority vote across
  all iterations, providing a measure of classification confidence.

- ldcyc:

  Numeric value specifying the light phase duration in hours (e.g., 12
  for LD 12:12). If `NULL` (default), assumes a 12-hour light phase.
  Used to assign "light" and "dark" phase labels to time points.

- n_states:

  Number of states to fit: 3, 4, or 5. Default: 4.

## Value

A list containing three data frames:

- `TimeSpentInEachState`:

  Summary of time (in minutes) spent in each state, grouped by:

  - `ID`: Individual identifier

  - `Genotype`: Genotype

  - `day`: Day number

  - `phase`: Light or dark phase

  - `state_name`: Activity-ordered state label (State0 to State2,
    State3, or State4, depending on the fitted state count)

  - `time_spent`: Minutes in that state

  - Additional metadata columns (e.g., `sex`, `treatment`)

  All state-phase combinations are present (filled with 0 if not
  observed).

- `VITERBIDecodedProfile`:

  Time-series of inferred states with columns:

  - `timestamp`: Time point index (1 to total time points)

  - `state`: Raw HMM state label

  - `state_name`: Activity-ordered state label (State0 to State2,
    State3, or State4, depending on the fitted state count)

  - `phase`: Light or dark

  - `ID`, `Genotype`, `day`: Grouping variables

  - Additional metadata columns (e.g., `sex`, `treatment`)

- `QualityReport`:

  One row per attempted individual and day, with the requested state
  count, valid fits, status, and reason.

## Details

### State Interpretation

States are ordered by mean activity level:

- **State0**: Highest activity (active wake)

- **State1**: Moderate activity (quiet wake)

- **State2**: Low activity (light sleep)

- **State3**: Lowest activity (deep sleep)

These biological labels apply to the default four-state model. With
three or five states, labels indicate activity order only.

### Failed Cases

The function tracks cases where HMM fitting fails or produces invalid
results:

- No valid solution after maximum iterations

- Single-state dominance (\>99% of time in one state) - indicates
  insufficient behavioral variability

Failed cases are recorded in `QualityReport` and excluded from state
summaries. Unexpected top-level errors stop the call.

### Performance Notes

- Progress bar shows overall fitting progress

- For large datasets, consider using
  [`HMMbehavrFast`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavrFast.md)
  for parallel processing

- Typical runtime: ~1-2 seconds per individual-day with it=100

## References

Ghosh, A., & Harbison, S. T. (2024). Hidden Markov models reveal
heterogeneity in sleep states. (Add actual reference when published)

## See also

[`HMMbehavrFast`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavrFast.md)
for parallel implementation
[`HMMDataPrep`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md)
for preparing input data
[`HMMplot`](https://orijitghosh.github.io/FlyDreamR/reference/HMMplot.md)
for visualizing results
[`HMMFacetedPlot`](https://orijitghosh.github.io/FlyDreamR/reference/HMMFacetedPlot.md)
for multi-individual visualization

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage with default parameters
hmm_results <- HMMbehavr(behavtbl = processed_data)

# Custom light cycle and more iterations
hmm_results <- HMMbehavr(
  behavtbl = processed_data,
  it = 200,           # More robust inference
  ldcyc = 16          # LD 16:8 cycle
)

# Access results with additional metadata
time_in_states <- hmm_results$TimeSpentInEachState
state_profile <- hmm_results$VITERBIDecodedProfile

# Summarize sleep by sex and genotype
library(dplyr)
sleep_summary <- time_in_states %>%
  filter(state_name %in% c("State2", "State3")) %>%
  group_by(Genotype, sex, day, phase) %>%
  summarise(total_sleep_min = sum(time_spent))
} # }
```
