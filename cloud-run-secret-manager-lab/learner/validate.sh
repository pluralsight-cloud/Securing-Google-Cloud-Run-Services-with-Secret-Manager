
#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."
source learner/lab-vars.sh

echo "Validating Cloud Run security configuration..."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

gcloud run services describe "$SERVICE" \
  --region="$REGION" \
  --project="$PROJECT_ID" \
  --format=json > "$TMP_DIR/service.json"

python3 - "$TMP_DIR/service.json" > "$TMP_DIR/revision-name" <<'PY'
import json
import sys

with open(sys.argv[1]) as f:
    service = json.load(f)

status = service.get("status", {})
created = status.get("latestCreatedRevisionName")
ready = status.get("latestReadyRevisionName")

if not created or not ready or created != ready:
    sys.exit("FAIL: Latest Cloud Run revision is not ready")

traffic = status.get("traffic", [])

if not any(
    item.get("revisionName") == ready
    and item.get("percent") == 100
    for item in traffic
):
    sys.exit("FAIL: Latest ready revision is not serving 100% of traffic")

print(ready)
PY

READY_REVISION="$(cat "$TMP_DIR/revision-name")"

echo "PASS: Latest revision is ready and serving traffic"

gcloud run revisions describe "$READY_REVISION" \
  --region="$REGION" \
  --project="$PROJECT_ID" \
  --format=json > "$TMP_DIR/revision.json"

python3 - "$TMP_DIR/revision.json" \
  "$SERVICE_ACCOUNT_EMAIL" "$SECRET" "$DEMO_TOKEN" <<'PY'
import json
import sys

path, expected_sa, secret, token = sys.argv[1:]

with open(path) as f:
    revision = json.load(f)

spec = revision.get("spec", {})

if spec.get("serviceAccountName") != expected_sa:
    sys.exit("FAIL: Incorrect workload identity")

print("PASS: Correct workload identity")

containers = spec.get("containers", [])

if not containers:
    sys.exit("FAIL: No application container found")

env = containers[0].get("env", [])

matches = [
    item for item in env
    if item.get("name") == "NOTIFY_TOKEN"
]

if len(matches) != 1:
    sys.exit("FAIL: NOTIFY_TOKEN is missing or duplicated")

entry = matches[0]

if "value" in entry:
    sys.exit("FAIL: NOTIFY_TOKEN contains a plaintext value")

reference = entry.get("valueFrom", {}).get("secretKeyRef", {})

if (
    reference.get("name") != secret
    or str(reference.get("key")) != "1"
):
    sys.exit("FAIL: Incorrect Secret Manager reference")

print("PASS: Secret Manager version 1 reference")
print("PASS: No plaintext NOTIFY_TOKEN configuration")

if token in json.dumps(revision):
    sys.exit("FAIL: Synthetic token found in serving revision")

print("PASS: Token absent from serving revision configuration")
PY

if grep -R -F -q "$DEMO_TOKEN" app/; then
    echo "FAIL: Synthetic token found in application source"
    exit 1
fi

echo "PASS: Token absent from application source"

SERVICE_URL="$(gcloud run services describe "$SERVICE" \
  --region="$REGION" \
  --project="$PROJECT_ID" \
  --format='value(status.url)')"

RESPONSE="$(curl -fsS \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  "$SERVICE_URL")"

python3 - "$RESPONSE" <<'PY'
import json
import sys

response = json.loads(sys.argv[1])

if response.get("status") != "ok":
    sys.exit("FAIL: Application status is not OK")

if response.get("notification") != "configured":
    sys.exit("FAIL: Notification token is not configured")

print("PASS: Application responds successfully")
PY

echo "ALL LAB VALIDATIONS PASSED"
