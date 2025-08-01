#!/bin/bash
# Grand permission to use GCP
# Usage: ./grant_permission.sh <PROJECT_ID> <USER_EMAIL>

set -e

PROJECT_ID="$1"
USER_EMAIL="$2"

# If USER_EMAIL doesn't contain "@", treat it as a username and append "@google.com"
if [[ "$USER_EMAIL" != *"@"* ]]; then
  echo "Input doesn't look like an email. Appending @google.com..."
  USER_EMAIL="${USER_EMAIL}@google.com"
fi

if [[ -z "$PROJECT_ID" || -z "$USER_EMAIL" ]]; then
  echo "Usage: $0 <PROJECT_ID> <USER_EMAIL>"
  exit 1
fi

echo "Granting permissions to $USER_EMAIL in project $PROJECT_ID..."

# 1. SSH to VM and TPU VMs
echo "→ Granting SSH access to VM and TPU..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$USER_EMAIL" \
  --role="roles/compute.instanceAdmin.v1"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$USER_EMAIL" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$USER_EMAIL" \
  --role="roles/tpu.admin"

# 2. Publish Pub/Sub events
echo "→ Granting Pub/Sub Publisher role..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$USER_EMAIL" \
  --role="roles/pubsub.publisher"

# 3. Read Spanner and use Spanner Studio
echo "→ Granting Spanner read access and studio usage..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$USER_EMAIL" \
  --role="roles/spanner.viewer"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$USER_EMAIL" \
  --role="roles/spanner.databaseReader"

echo "All permissions granted successfully."
