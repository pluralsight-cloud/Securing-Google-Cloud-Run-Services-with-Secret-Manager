
#!/usr/bin/env bash

# Retrieve the active Google Cloud project.
export PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"

# Retrieve the project number.
export PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" \
  --format='value(projectNumber)')"

# Lab resource configuration.
export REGION="us-east1"
export SERVICE="order-notifier"
export SECRET="order-notifier-token"
export REPOSITORY="lab-images"

# Initial deployment identity.
export DEFAULT_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

# Dedicated workload identity supplied by the lab template.
export SERVICE_ACCOUNT_EMAIL="order-notifier-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Artifact Registry container image.
export IMAGE_URL="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${SERVICE}:1.0"

# Synthetic token used only for the insecure initial deployment.
export DEMO_TOKEN="demo-notify-token-7f3a9c"

# Display the active lab configuration.
echo "Project: $PROJECT_ID"
echo "Project number: $PROJECT_NUMBER"
echo "Region: $REGION"
echo "Service: $SERVICE"
echo "Default service account: $DEFAULT_SA"
echo "Dedicated workload identity: $SERVICE_ACCOUNT_EMAIL"
