#!/bin/bash

# === Usage ===
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 JOB_REFERENCE RUN_TYPE"
  exit 1
fi

JOB_REFERENCE="$1"
RUN_TYPE="$2"

echo "Querying records for JobReference='$JOB_REFERENCE' and RunType='$RUN_TYPE'..."

# Define the SQL query in a readable, multiline variable
read -r -d '' SQL_QUERY << EOM
SELECT
    JobReference,
    Model,
    Status,
    Device,
    RecordId,
    TensorParallelSize,
    MaxNumSeqs,
    MaxNumBatchedTokens,
    MaxModelLen
FROM
    RunRecord
WHERE
    JobReference='$JOB_REFERENCE' AND RunType='$RUN_TYPE';
EOM

# Fetch records from Spanner using the SQL variable
RECORDS_JSON=$(gcloud spanner databases execute-sql "$GCP_DATABASE_ID" \
  --instance="$GCP_INSTANCE_ID" \
  --project="$GCP_PROJECT_ID" \
  --sql="$SQL_QUERY" \
  --format=json)

# Check if any records were found
RECORD_COUNT=$(echo "$RECORDS_JSON" | jq '.rows | length')

if [ "$RECORD_COUNT" -eq 0 ]; then
  echo "No matching records found for JobReference LIKE '$JOB_REFERENCE%'."
  exit 0
fi

echo "Found $RECORD_COUNT matching records. Generating JSON output:"
echo ""

# Process the Spanner output into a final JSON array using a single jq command
echo "$RECORDS_JSON" | jq --arg GCS_BUCKET "$GCS_BUCKET" '
  .rows | map(
    # For each row array, create a JSON object
    {
      "JobReference": .[0],
      "Model": .[1] | split("/")[-1], # Get just the model name from path
      "Status": .[2],
      "Device": .[3],
      "RecordId": .[4],
      "TensorParallelSize": .[5],
      "MaxNumSeqs": .[6],
      "MaxNumBatchedTokens": .[7],
      "MaxModelLen": .[8],
      "Profile": "gs://\($GCS_BUCKET)/job_logs/\(.[4])/static_profile",
      "upload_command": "c2x --gcs_path=gs://\($GCS_BUCKET)/job_logs/\(.[4])/static_profile"
    }
  )
'