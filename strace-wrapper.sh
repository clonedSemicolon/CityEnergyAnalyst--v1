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

# Step 3: Capture commands to run
if [ "$#" -eq 0 ]; then
    echo "❗ [strace-wrapper] No commands provided to trace. Exiting."
    exit 1
fi

COMMAND="$*"

# Step 4: Run the given commands under strace
echo "🔵 [strace-wrapper] Running commands under strace..."
strace -ff -o ${LOG_DIR}/strace bash -c "$COMMAND"

# Step 5: Merge strace logs
if compgen -G "${LOG_DIR}/strace.*" > /dev/null; then
    echo "🔵 [strace-wrapper] Merging strace logs..."
    cat ${LOG_DIR}/strace.* > "$MERGED_LOG"
else
    echo "⚠️ [strace-wrapper] No strace logs found to merge."
    exit 1
fi

# Step 6: Upload artifact (only inside GitHub Actions)
if [ -n "${GITHUB_ACTIONS:-}" ]; then
  echo "🔵 [strace-wrapper] Uploading artifact..."
  mkdir -p artifact_upload
  cp "$MERGED_LOG" artifact_upload/
else
  echo "⚠️ [strace-wrapper] Not running inside GitHub Actions. Skipping artifact upload."
fi

echo "✅ [strace-wrapper] Done!"
