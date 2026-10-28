
#!/usr/bin/env bash

export PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"

export PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" \
  --format='value(projectNumber)')"

export REGION="us-east1"
export SERVICE="order-notifier"
export SECRET="order-notifier-token"
export REPOSITORY="lab-images"

# Existing Compute Engine default service account.
export DEFAULT_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

# Use the same supplied identity throughout the lab.
export SERVICE_ACCOUNT_EMAIL="$DEFAULT_SA"

export IMAGE_URL="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${SERVICE}:1.0"

# Synthetic token used only for the insecure initial configuration.
export DEMO_TOKEN="demo-notify-token-7f3a9c"

echo "Project: $PROJECT_ID"
echo "Project number: $PROJECT_NUMBER"
echo "Region: $REGION"
echo "Service: $SERVICE"
echo "Default service account: $DEFAULT_SA"
echo "Workload identity: $SERVICE_ACCOUNT_EMAIL"
