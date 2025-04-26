#!/bin/bash
set -euo pipefail

# Variables
LOG_DIR="strace_output"
MERGED_LOG="combined_strace.log"

# Step 1: Install strace if missing
echo "🔵 [strace-wrapper] Installing strace..."
sudo apt-get update -qq
sudo apt-get install -y -qq strace coreutils gzip

# Step 2: Prepare log directory
echo "🔵 [strace-wrapper] Preparing strace output directory..."
mkdir -p "$LOG_DIR"

# Step 3: Override bash to run under strace
echo "🔵 [strace-wrapper] Setting up strace shell override..."
echo 'defaults:
  run:
    shell: bash --noprofile --norc -eo pipefail -c "mkdir -p strace_output && strace -ff -o strace_output/strace bash -eo pipefail -c '\''$0'\''"
' > strace-shell-override.yml

# Step 4: After job finishes, merge and upload logs
function merge_and_upload_logs {
    echo "🔵 [strace-wrapper] Merging strace logs..."
    cat ${LOG_DIR}/strace.* > "$MERGED_LOG"

    echo "🔵 [strace-wrapper] Uploading artifact..."
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
      gh extension install actions/upload-artifact
      gh run upload-artifact "$MERGED_LOG" --name "strace_log_${GITHUB_JOB}"
    else
      echo "Not running inside GitHub Actions. Skipping artifact upload."
    fi
}

trap merge_and_upload_logs EXIT

# Step 5: Done
echo "✅ [strace-wrapper] Setup complete. Proceeding with job execution..."
