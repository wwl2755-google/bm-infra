#!/bin/bash

# A script to repeat and optionally shuffle data rows of a CSV file.
# This version supports in-place modification (input file can be the same as the output file).

# --- Usage and Argument Validation ---
if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <input_csv> <output_csv> <repetitions> [shuffle]"
  echo "  input_csv:    The path to the source CSV file."
  echo "  output_csv:   The path to the destination CSV file."
  echo "  repetitions:  The number of times to repeat the data rows."
  echo "  shuffle:      (Optional) Set to 'True' to shuffle the repeated data rows."
  exit 1
fi

# --- Assign Arguments to Variables ---
INPUT_FILE="$1"
OUTPUT_FILE="$2"
REPETITIONS="$3"
SHOULD_SHUFFLE=false
# Check for the optional shuffle argument, case-insensitively
if [[ "${4,,}" == "true" ]]; then
  SHOULD_SHUFFLE=true
fi

# --- Validate Inputs ---
if ! [[ "$REPETITIONS" =~ ^[0-9]+$ ]] || [ "$REPETITIONS" -lt 1 ]; then
    echo "❌ Error: Repetitions must be a positive integer."
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Error: Input file not found at '$INPUT_FILE'"
    exit 1
fi

# --- Main Logic ---

# Create temporary files that will be cleaned up automatically on script exit.
# A final output temp file is used to buffer the result, allowing for safe in-place editing.
BODY_TMP=$(mktemp)
REPEATED_BODY_TMP=$(mktemp)
FINAL_OUTPUT_TMP=$(mktemp)
trap 'rm -f "$BODY_TMP" "$REPEATED_BODY_TMP" "$FINAL_OUTPUT_TMP"' EXIT

echo "➡️ Step 1: Reading and buffering input file..."
# Read header and body from the source file BEFORE any writing to the destination.
# Write the header to the final temporary output file.
head -n 1 "$INPUT_FILE" > "$FINAL_OUTPUT_TMP"
# Write the body to its own temporary file.
tail -n +2 "$INPUT_FILE" > "$BODY_TMP"

# Check if there are any data rows to process
if [ ! -s "$BODY_TMP" ]; then
    echo "⚠️ Warning: No data rows found in the input file. Output will only contain the header."
    # If no body, the header is already in the temp file. We just need to move it.
    mv "$FINAL_OUTPUT_TMP" "$OUTPUT_FILE"
    echo "✅ Done."
    exit 0
fi

echo "🔄 Step 2: Repeating data $REPETITIONS time(s)..."
# Loop and append the buffered body content to a second temporary file
for (( i=0; i < REPETITIONS; i++ )); do
  cat "$BODY_TMP" >> "$REPEATED_BODY_TMP"
done

echo "➡️ Step 3: Assembling final content in memory..."
# Process and append the repeated data to the final temporary output file
if [ "$SHOULD_SHUFFLE" = true ]; then
  echo "🔀 Shuffling and appending data..."
  shuf "$REPEATED_BODY_TMP" >> "$FINAL_OUTPUT_TMP"
else
  echo "➡️ Appending data without shuffling..."
  cat "$REPEATED_BODY_TMP" >> "$FINAL_OUTPUT_TMP"
fi

echo "💾 Step 4: Atomically writing to destination file..."
# Atomically move the fully-formed temporary file to the final destination.
# This is safe even if INPUT_FILE and OUTPUT_FILE are the same.
mv "$FINAL_OUTPUT_TMP" "$OUTPUT_FILE"

echo "✅ Done. Output written to $OUTPUT_FILE"
