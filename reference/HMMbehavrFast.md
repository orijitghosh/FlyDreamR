# Parallel Hidden Markov Model for Sleep State Inference

Parallelized wrapper for
[`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
that processes multiple individuals simultaneously using multiple CPU
cores. This function provides significant speed improvements for large
datasets while maintaining identical output to the serial version.

Each individual's data is processed independently in parallel, making
this approach ideal for experiments with many animals. The function
automatically handles cluster setup and cleanup.

## Usage

``` r
HMMbehavrFast(behavtbl, it = 100, n_cores = 4, ldcyc = NULL)
```

## Arguments

- behavtbl:

  A `behavr` table containing behavioral data for multiple individuals.
  See
  [`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
  for required columns.

- it:

  Integer (\>= 100) specifying the number of HMM fitting iterations per
  individual per day. Default: 100. See
  [`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
  for details.

- n_cores:

  Integer specifying the number of CPU cores to use for parallel
  processing. Default: 4.

  **Recommendations:**

  - Leave 1-2 cores free for system operations

  - On HPC: request cores matching this parameter

  - Typical desktop: use 2-4 cores

  - Check available cores:
    [`parallel::detectCores()`](https://rdrr.io/r/parallel/detectCores.html)

- ldcyc:

  Numeric specifying light phase duration in hours. If `NULL` (default),
  assumes 12-hour light phase. See
  [`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
  for details.

## Value

A list containing two data frames with combined results from all
individuals:

- `TimeSpentInEachState`:

  Time spent in each state for all individuals

- `VITERBIDecodedProfile`:

  HMM-inferred state profiles for all individuals

See
[`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
for detailed description of output structure.

## Details

### Parallelization Strategy

The function:

1.  Splits data by individual ID

2.  Creates a parallel cluster with `n_cores` workers

3.  Distributes individuals across workers

4.  Each worker runs
    [`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
    independently

5.  Combines results after all workers complete

6.  Automatically cleans up cluster

### Performance Considerations

- **Speedup**: Near-linear with number of cores (e.g., 4x faster with 4
  cores)

- **Memory**: Each worker needs enough RAM for one individual's data

- **Overhead**: Setup time ~1-2 seconds; only beneficial for \>5-10
  individuals

- **Progress**: No progress bar (runs silently in parallel)

### Timing Comparison

For 32 individuals, 3 days each, it=100:

- Serial (`HMMbehavr`): ~160 seconds

- 4 cores (`HMMbehavrFast`): ~45 seconds

- 8 cores: ~25 seconds

### Error Handling

If any individual fails to process, that individual returns `NULL` and
is excluded from the final results. Other individuals continue
processing normally.

## See also

[`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
for serial implementation and detailed HMM description
[`HMMDataPrep`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md)
for preparing input data
[`makeCluster`](https://rdrr.io/r/parallel/makeCluster.html) for details
on parallel backends

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic parallel processing with 4 cores
hmm_results <- HMMbehavrFast(
  behavtbl = processed_data,
  n_cores = 4
)

# Use more cores for large dataset
hmm_results <- HMMbehavrFast(
  behavtbl = processed_data,
  it = 200,
  n_cores = 8,
  ldcyc = 12
)

# Check available cores first
available_cores <- parallel::detectCores()
use_cores <- max(1, available_cores - 2)  # Leave 2 for system

hmm_results <- HMMbehavrFast(
  behavtbl = processed_data,
  n_cores = use_cores
)

# Results structure identical to HMMbehavr
time_in_states <- hmm_results$TimeSpentInEachState
state_profile <- hmm_results$VITERBIDecodedProfile
} # }
```
