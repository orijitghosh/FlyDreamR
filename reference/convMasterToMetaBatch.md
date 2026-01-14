# Batch Convert Multiple Master Files to FlyDreamR Metadata Format

Processes multiple DAM master files in batch, converting each to the
metadata format required by FlyDreamR. This is a convenient wrapper
around
[`convMasterToMeta`](https://orijitghosh.github.io/FlyDreamR/reference/convMasterToMeta.md)
that handles multiple files with the same start/end times.

The function validates each master file against its corresponding
monitor file, generates individual metadata CSV files, and returns a
combined metadata table for all processed files.

## Usage

``` r
convMasterToMetaBatch(
  metafiles,
  startDT = "2024-04-11 06:00:00",
  endDT = "2024-04-16 06:00:00",
  output_dir = "."
)
```

## Arguments

- metafiles:

  Character vector containing full paths to all master files to process.
  Can be generated using
  [`Sys.glob()`](https://rdrr.io/r/base/Sys.glob.html) or
  [`list.files()`](https://rdrr.io/r/base/list.files.html). No default
  value.

- startDT:

  Character string. Expected experimental start date-time **applied to
  all files**. Format: `"YYYY-MM-DD HH:MM:SS"`. Default:
  `"2024-04-11 06:00:00"`.

- endDT:

  Character string. Expected experimental end date-time **applied to all
  files**. Format: `"YYYY-MM-DD HH:MM:SS"`. Default:
  `"2024-04-16 06:00:00"`.

- output_dir:

  Character string. Directory where all metadata CSV files will be
  saved. Defaults to current working directory (`"."`). Created if it
  doesn't exist.

## Value

A single `data.frame` combining metadata from all successfully processed
master files. Contains the same columns as individual metadata files
(see
[`convMasterToMeta`](https://orijitghosh.github.io/FlyDreamR/reference/convMasterToMeta.md)
for column details).

Individual CSV files are also written to `output_dir`, one per master
file processed.

If a file fails to process, it is skipped with a warning message, and
processing continues with remaining files.

## Details

### Batch Processing Workflow

For each master file, the function:

1.  Calls
    [`convMasterToMeta`](https://orijitghosh.github.io/FlyDreamR/reference/convMasterToMeta.md)
    with provided parameters

2.  Validates start/end times against the monitor file

3.  Saves individual metadata CSV

4.  Collects metadata for combining

5.  Handles errors gracefully (skips failed files)

### Error Handling

- Each file is wrapped in `tryCatch`

- Failed files generate a warning but don't stop processing

- Successfully processed files are combined in the final output

- Summary statistics printed at completion

### Use Cases

Use batch processing when you have:

- Multiple monitor files from the same experiment (same timing)

- Multiple replicates run simultaneously

- Multiple blocks in a large-scale screen

**Important**: All files must share the same start/end times. If your
master files have different timings, process them separately using
[`convMasterToMeta`](https://orijitghosh.github.io/FlyDreamR/reference/convMasterToMeta.md).

### Performance

Processing speed depends on:

- Number of files

- Size of monitor files (for validation)

- I/O speed

Typical: 1-2 seconds per file.

## Master File Format

Each master file should follow the same format as described in
[`convMasterToMeta`](https://orijitghosh.github.io/FlyDreamR/reference/convMasterToMeta.md):

- Tab-delimited text file

- No header row

- 8 columns: Monitor, Channel, Line, Sex, Treatment, Rep, Block,
  SetupCode

- Only rows with SetupCode = 1 are processed

## See also

[`convMasterToMeta`](https://orijitghosh.github.io/FlyDreamR/reference/convMasterToMeta.md)
for single file processing and format details
[`HMMDataPrep`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md)
for using the generated metadata
[`Sys.glob`](https://rdrr.io/r/base/Sys.glob.html) for finding files
with wildcards

## Examples

``` r
if (FALSE) { # \dontrun{
# Find all master files in a directory
master_files <- Sys.glob("experiment_data/master*.txt")

# Process all with same start/end times
all_metadata <- convMasterToMetaBatch(
  metafiles = master_files,
  startDT = "2024-01-15 09:00:00",
  endDT = "2024-01-20 09:00:00",
  output_dir = "processed_metadata"
)

# View combined results
print(all_metadata)
table(all_metadata$genotype)

# Alternatively, specify files explicitly
master_files <- c(
  "data/master53.txt",
  "data/master54.txt",
  "data/master55.txt"
)
metadata <- convMasterToMetaBatch(master_files)

# Use list.files() with pattern matching
master_files <- list.files(
  path = "raw_data",
  pattern = "^master.*\\.txt$",
  full.names = TRUE
)
metadata <- convMasterToMetaBatch(
  metafiles = master_files,
  output_dir = "metadata"
)
} # }
```
