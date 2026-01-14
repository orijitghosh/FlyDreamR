# Prepare DAM Activity Data for HMM Analysis

Processes Drosophila Activity Monitor (DAM) data by loading raw monitor
files, linking them with metadata, calculating derived features (day,
phase, normalized activity), and filtering by date range. The output is
a `behavr` table ready for Hidden Markov Model analysis.

This is typically the first step in the FlyDreamR workflow, converting
raw DAM files into a standardized format suitable for
[`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md).

## Usage

``` r
HMMDataPrep(
  metafile_path,
  result_dir = getwd(),
  ldcyc = 12,
  day_range = c(1, 2),
  ...
)
```

## Arguments

- metafile_path:

  Character string. Full path to the metadata CSV file. Must contain
  technical columns: `file`, `start_datetime`, `stop_datetime`,
  `region_id`. Any additional columns (e.g., `genotype`, `replicate`,
  `sex`) will be preserved and merged into the final dataset.

- result_dir:

  Character string. Directory path containing the raw DAM monitor files.
  Defaults to current working directory.

- ldcyc:

  Numeric. Duration of the light phase in hours within a 24-hour cycle.
  For example, use 12 for LD 12:12, or 16 for LD 16:8. Default: 12. Used
  to assign time points to "Light" or "Dark" phases.

- day_range:

  Numeric vector of length 2. Specifies `c(start_day, end_day)` to
  retain for analysis (inclusive). Days are numbered starting from 1.

  - Use `c(1, 3)` to keep days 1, 2, and 3

  - Use `c(2, 2)` to keep only day 2

  - Use `c(1, 5)` to keep days 1 through 5

  Default: `c(1, 2)` (first two days).

- ...:

  Additional arguments passed to
  [`sleepDAMAnnotation`](https://orijitghosh.github.io/FlyDreamR/reference/sleepDAMAnnotation.md).
  Most commonly used:

  `min_time_immobile`

  :   A vector of length 2 specifying the minimum and maximum duration
      (in seconds) for an immobility bout to be considered sleep.
      Default: `c(behavr::mins(5), behavr::mins(1440))`. For example,
      use `c(behavr::mins(10), behavr::mins(1440))` to require 10
      minutes of immobility.

## Value

A `behavr` table (class `behavr` and `data.table`) containing processed
activity data with both original metadata columns and newly calculated
columns:

**Metadata columns** (from input):

- `id`: Unique identifier for each individual, required

- `genotype`: Genotype/line identifier, optional

- `replicate`: Replicate identifier, optional

- `sex`: Sex identifier, optional

**Activity columns** (from DAM files):

- `t`: Time in seconds from experiment start

- `activity`: Raw activity count (beam crossings)

- `asleep`: Logical, sleep state annotation

**Calculated columns** (added by this function):

- `moving`: Logical, `TRUE` if activity \> 0

- `day`: Integer day number (1, 2, 3, ...)

- `phase`: Factor with levels "Light" and "Dark"

- `normact`: Normalized activity as percentage of daily total (0-100)

## Details

### Metadata File Format\*\*

The `metadata_file` must be a CSV with one row per fly (channel) and the
following columns:

- `file`:

  Full filename of the raw monitor file (e.g., "Monitor1.txt").

- `start_datetime`:

  Experiment start timestamp ("YYYY-MM-DD HH:MM:SS").

- `stop_datetime`:

  Experiment end timestamp ("YYYY-MM-DD HH:MM:SS").

- `region_id`:

  Channel number (1-32) on the DAM monitor.

- `genotype`:

  Experimental genotype identifier.

- `replicate`:

  Replicate number/value. This is optional.

- `sex`:

  Sex identifier. This is optional.

### Activity Normalization

`normact` represents activity as a percentage of total daily activity:
`normact = (activity / sum(daily_activity)) * 100`

This normalization accounts for individual differences in baseline
activity levels and is used by the HMM fitting process.

### Error Handling

The function will stop with an error if:

- Metadata file doesn't exist or can't be read

- DAM files referenced in metadata are missing

- No data remains after day filtering

- Required columns are missing from loaded data

## See also

[`convMasterToMeta`](https://orijitghosh.github.io/FlyDreamR/reference/convMasterToMeta.md)
for generating metadata files
[`HMMbehavr`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
for running HMM analysis on prepared data
[`sleepDAMAnnotation`](https://orijitghosh.github.io/FlyDreamR/reference/sleepDAMAnnotation.md)
for sleep annotation details
[`load_dam`](https://rdrr.io/pkg/damr/man/load_dam.html) for DAM file
loading

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage with default parameters
processed_data <- HMMDataPrep(
  metafile_path = "metadata/Metadata_Monitor1.csv"
)

# Specify DAM file directory and custom day range
processed_data <- HMMDataPrep(
  metafile_path = "metadata/experiment1_metadata.csv",
  result_dir = "raw_dam_files/",
  day_range = c(2, 4)  # Analyze days 2-4 only
)

# Custom light cycle (LD 16:8) and longer immobility threshold
processed_data <- HMMDataPrep(
  metafile_path = "metadata/experiment2_metadata.csv",
  ldcyc = 16,  # 16 hours of light
  min_time_immobile = c(behavr::mins(10), behavr::mins(1440))  # 10 min threshold
)

# Inspect the output
print(head(processed_data))
summary(processed_data$normact)
table(processed_data$phase, processed_data$day)

# Check data coverage
unique(processed_data$id)  # List all individuals
range(processed_data$day)  # Day range in data
} # }
```
