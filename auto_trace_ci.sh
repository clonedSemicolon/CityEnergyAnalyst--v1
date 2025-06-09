#!/bin/bash

WORKFLOW_FILE=".github/workflows/main.yml"
TMP_FILE="main_with_strace.yml"
STRACE_DIR="strace_logs"

mkdir -p "$STRACE_DIR"

echo "Processing: $WORKFLOW_FILE"

# Ensure yq is available (used to parse/modify YAML)
if ! command -v yq &> /dev/null; then
  echo "⚠️  'yq' is required (https://github.com/mikefarah/yq)"
  exit 1
fi

# Backup original
cp "$WORKFLOW_FILE" "${WORKFLOW_FILE}.bak"

# Prepare output
cp "$WORKFLOW_FILE" "$TMP_FILE"

# Insert strace logging into each run step
yq eval '
  (.jobs[] | .steps[] | select(has("run"))).run = 
    "mkdir -p strace_logs && strace -tt -f -o strace_logs/\(.name | gsub(\" \"; \"_\")).log bash -c \"\(.run | gsub("\""; "\\\""))\""
' "$WORKFLOW_FILE" > "$TMP_FILE"

# Append upload-artifact step at the end of each job
yq eval '
  .jobs *= with_entries(
    .value.steps += [{
      name: "Upload strace logs",
      uses: "actions/upload-artifact@v4",
      with: {
        name: "strace_logs",
        path: "strace_logs/"
      }
    }]
  )
' "$TMP_FILE" > "$WORKFLOW_FILE"

rm "$TMP_FILE"

echo "✅ Strace steps added and artifacts upload enabled."
echo "📦 Backup saved at: ${WORKFLOW_FILE}.bak"
