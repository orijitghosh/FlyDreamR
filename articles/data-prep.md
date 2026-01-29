# Getting data into FlyDreamR

This vignette covers the **input files** FlyDreamR expects and the
standard workflow to convert DAM outputs into a `behavr`-style table
that downstream functions can consume.

## DAM files and metadata

A typical DAM experiment produces:

- A **master file** or a **metadata file** (experiment-level setup +
  sample sheet)
- One or more **monitor files** (time series activity counts)

## Metadata File Format

The most critical step in data preparation is creating a **metadata CSV
file**. This file maps the raw monitor files (channels 1–32) to your
specific experimental conditions (Genotype, Sex, etc.) and defines the
exact start and stop times for the experiment.

The file must contain the following columns:

| Column Header        | Description                                                      | Example               |
|:---------------------|:-----------------------------------------------------------------|:----------------------|
| **`file`**           | The full filename of the DAM monitor file (including extension). | `Monitor1.txt`        |
| **`start_datetime`** | Experiment start timestamp (`YYYY-MM-DD HH:MM:SS`).              | `2025-02-12 06:04:00` |
| **`stop_datetime`**  | Experiment end timestamp (`YYYY-MM-DD HH:MM:SS`).                | `2025-02-15 09:00:00` |
| **`region_id`**      | The channel number (1–32) on the monitor.                        | `1`                   |
| **`genotype`**       | Experimental genotype or condition identifier.                   | `CantonS`             |
| **`replicate`**      | Replicate number (not mandatory).                                | `1`                   |
| **`sex`**            | Sex identifier (not mandatory).                                  | `Female`              |

### Example Metadata

You can create this file in Excel or a text editor. Here is an example
of what the contents should look like:

``` csv
file,start_datetime,stop_datetime,region_id,genotype,replicate
Monitor1.txt,2025-02-12 06:04:00,2025-02-15 09:00:00,1,CantonS,1
Monitor1.txt,2025-02-12 06:04:00,2025-02-15 09:00:00,2,w1118,1
Monitor2.txt,2025-02-12 06:04:00,2025-02-15 09:00:00,1,iso31,2
```

FlyDreamR converts the master file into a metadata CSV, then uses that
metadata to load/bind monitor data for analysis. Most of you will create
a **Metadata** file, and not have the **Master** file, so you may move
to Step 2 directly.

## 1) Convert a master file to FlyDreamR metadata

Use
[`convMasterToMeta()`](https://orijitghosh.github.io/FlyDreamR/reference/convMasterToMeta.md)
for a single master file, or
[`convMasterToMetaBatch()`](https://orijitghosh.github.io/FlyDreamR/reference/convMasterToMetaBatch.md)
to combine multiple master files into one metadata table.

``` r
# Single master file -> metadata CSV
metafile <- convMasterToMeta(
  metafile = "master1.txt",
  startDT  = "2025-02-12 06:04:00",
  endDT    = "2025-02-17 06:04:00"
)

# Multiple master files -> merged metadata CSV
metafileBatch <- convMasterToMetaBatch(
  c("master1.txt", "master2.txt"),
  startDT = "2025-02-12 06:04:00",
  endDT   = "2025-02-17 06:04:00"
)
```

## 2) Load/bind monitor data for analysis

Use
[`HMMDataPrep()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md)
to load the monitor file(s) associated with a metadata CSV and generate
a cleaned dataset. Demo dataset has been provided.

``` r
# Load demo data
meta_file <- system.file("extdata", "Metadata_Monitor1.csv", package = "FlyDreamR")
data_dir <- system.file("extdata", package = "FlyDreamR")
dt <- HMMDataPrep(
  metafile_path = meta_file,
  result_dir    = data_dir,
  ldcyc         = 12,
  day_range     = c(1, 2)
)

dt
```

The resulting table can be passed into:

- [`calcTradSleep()`](https://orijitghosh.github.io/FlyDreamR/reference/calcTradSleep.md)
  for traditional sleep metrics
- [`HMMbehavr()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavr.md)
  /
  [`HMMbehavrFast()`](https://orijitghosh.github.io/FlyDreamR/reference/HMMbehavrFast.md)
  for HMM fitting
