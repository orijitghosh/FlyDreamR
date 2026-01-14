# Convert Master File to FlyDreamR Metadata Format

Converts a DAM (Drosophila Activity Monitor) master file into the
metadata format required by FlyDreamR. The function reads the master
file, validates the start and end times against the corresponding
monitor file's light sensor data, and generates a properly formatted
metadata CSV file.

The validation process checks that:

- The provided start time matches the first "lights-ON" event on the
  specified start date

- The provided end time matches the "lights-OFF" event closest to the
  specified end time on that date

## Usage

``` r
convMasterToMeta(
  metafile,
  startDT = "2024-04-11 06:00:00",
  endDT = "2024-04-16 06:00:00",
  output_dir = "."
)
```

## Arguments

- metafile:

  Character string. Full path to the input master file. No default
  value - must be specified.

  **Example**: `"path/to/master53.txt"`

- startDT:

  Character string. Expected experimental start date and time in format
  `"YYYY-MM-DD HH:MM:SS"`.

  Default: `"2024-04-11 06:00:00"`.

  This should correspond to a lights-ON event in the monitor file. The
  function will validate this by checking the monitor file's light
  sensor data and warn if there's a mismatch.

- endDT:

  Character string. Expected experimental end date and time in format
  `"YYYY-MM-DD HH:MM:SS"`.

  Default: `"2024-04-16 06:00:00"`.

  This should correspond to a lights-OFF event in the monitor file. The
  function will find the lights-OFF event on the specified date closest
  to this time.

- output_dir:

  Character string. Directory path for saving the output metadata CSV
  file.

  Default: `"."` (current working directory).

  The directory will be created automatically if it doesn't exist.

## Value

Invisibly returns a `data.frame` containing the formatted metadata
(identical to the CSV file content). The function also writes a CSV file
to disk.

**Output filename format**: `Metadata_Block[X]Rep[Y]Monitor[Z].csv`

For example: `Metadata_Block1Rep1Monitor53.csv`

**The output CSV contains 6 columns**:

- `file`:

  Monitor filename (e.g., "Monitor53.txt"). This should exist in the
  same directory as the master file.

- `start_datetime`:

  Experiment start date and time (from `startDT`)

- `stop_datetime`:

  Experiment end date and time (from `endDT`)

- `region_id`:

  Channel number within the monitor (1-32)

- `genotype`:

  Combined identifier in format "Line_Sex" (e.g., "w1118_F", "mutant_M")

- `replicate`:

  Combined identifier in format "BlockXRepY" (e.g., "Block1Rep1",
  "Block2Rep3")

## Details

### Validation Process

The function performs several validation steps:

1.  **Read master file**: Loads and validates structure (8 columns,
    tab-delimited)

2.  **Filter rows**: Keeps only rows with `SetupCode = 1`

3.  **Locate monitor file**: Assumes monitor file (e.g.,
    "Monitor53.txt") is in the same directory as the master file

4.  **Parse light sensor data**: Reads the monitor file's 10th column
    (light sensor status)

5.  **Find lights-ON event**: Identifies the first 0→1 transition on the
    start date

6.  **Find lights-OFF event**: Identifies the lights-OFF event (row
    before change==1) on the end date closest to the specified time

7.  **Compare times**: Issues color-coded warnings if provided times
    don't match actual transitions

8.  **Generate metadata**: Creates properly formatted output regardless
    of validation results

9.  **Save CSV**: Writes to disk with automatic filename generation

### Light Sensor Validation

The validation uses the monitor file's light sensor column (column 10):

- **Value 0**: Lights OFF (dark)

- **Value 1**: Lights ON (light)

- **Transition 0→1**: Lights turning ON (dawn)

- **Row before transition 1→0**: Lights turning OFF (dusk)

This validation helps catch common errors like:

- Wrong start date (off by one day)

- Incorrect time (using 18:00 instead of 06:00)

- Daylight saving time issues

- Monitor clock drift

### Error Handling

The function will:

- **Stop with error** if: - Master file doesn't exist or can't be read -
  Master file doesn't have exactly 8 columns - No rows with SetupCode =
  1 found

- **Issue warning** if: - Monitor file not found (validation skipped,
  metadata still generated) - Start/end times don't match monitor file
  transitions - Multiple unique monitor files implied by master data

- **Continue processing** even if validation fails

### File Location Assumptions

The function assumes:

- Monitor files (e.g., "Monitor53.txt") are in the **same directory** as
  the master file

- Monitor filename matches the pattern "MonitorN.txt" where N is the
  monitor number from the master file

If your files are organized differently, you may need to adjust file
paths.

## Note

**Common Issues:**

1.  **"Start date-time does not match" warning**:

    - Check that your startDT corresponds to lights turning ON

    - Verify the date is correct (not off by one day)

    - Confirm time zone matches your incubator settings

2.  **"Monitor file not found" warning**:

    - Ensure MonitorN.txt is in the same directory as master file

    - Check the monitor number in your master file is correct

3.  **"No rows with SetupCode = 1"**:

    - Verify your master file has some rows with SetupCode = 1

    - Check for tab-delimited format (not spaces)

## Master File Format

The master file must be a **tab-delimited text file without a header
row**. It must contain exactly 8 columns in the following order:

1.  **Monitor**: Monitor number (integer)

2.  **Channel**: Channel number within the monitor (integer, 1-32
    typically)

3.  **Line**: Genotype or line identifier (character)

4.  **Sex**: Sex of the individual (character, e.g., "M" or "F")

5.  **Treatment**: Experimental treatment (character)

6.  **Rep**: Replicate number (integer)

7.  **Block**: Block number for experimental design (integer)

8.  **SetupCode**: Inclusion flag (integer; use `1` to include the
    channel in output, any other value to exclude)

Only rows with `SetupCode = 1` will be included in the output metadata.

## Example Master File

    53  1   w1118   F   control   1   1   1
    53  2   w1118   F   control   1   1   1
    53  3   mutant  M   drug      1   1   1
    53  4   mutant  M   drug      1   1   0

The 4th row would be excluded (SetupCode = 0).

## See also

[`convMasterToMetaBatch`](https://orijitghosh.github.io/FlyDreamR/reference/convMasterToMetaBatch.md)
for processing multiple master files at once
[`HMMDataPrep`](https://orijitghosh.github.io/FlyDreamR/reference/HMMDataPrep.md)
for using the generated metadata to load DAM data

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage with default start/end times
metadata <- convMasterToMeta(
  metafile = "path/to/master53.txt"
)
# Output: Metadata_Block1Rep1Monitor53.csv (in current directory)

# Specify custom start/end times and output directory
metadata <- convMasterToMeta(
  metafile = "experiment_data/master53.txt",
  startDT = "2024-01-15 09:00:00",  # Lights ON at 9 AM
  endDT = "2024-01-20 09:00:00",    # Lights OFF at 9 AM (5 days later)
  output_dir = "processed_metadata"
)
# Output: processed_metadata/Metadata_Block1Rep1Monitor53.csv

# Process master file with validation
metadata <- convMasterToMeta(
  metafile = "raw_data/master54.txt",
  startDT = "2024-02-01 06:00:00",
  endDT = "2024-02-06 18:00:00"     # Ends at dusk instead of dawn
)
# Function will validate times against Monitor54.txt

# Inspect the returned metadata
print(metadata)
str(metadata)
head(metadata)

# Check what files were referenced
unique(metadata$file)

# See genotype combinations
table(metadata$genotype)
} # }
```
