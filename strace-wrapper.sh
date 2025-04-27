#!/bin/bash
set -euo pipefail

# Usage: ./strace_run.sh <step-name> <command...>

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <step-name> <command...>"
    exit 1
fi

STEP_NAME="$1"
shift
COMMAND="$@"

LOG_DIR="strace_output"
MERGED_DIR="artifact_upload"
mkdir -p "$LOG_DIR" "$MERGED_DIR"

echo "🔵 [strace-run] Tracing step: $STEP_NAME"
strace -ff -o "${LOG_DIR}/strace_${STEP_NAME}" bash -c "$COMMAND"

# Merge individual logs for this step
cat ${LOG_DIR}/strace_${STEP_NAME}.* > "${MERGED_DIR}/${STEP_NAME}_strace.log"
