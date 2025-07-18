#!/bin/bash
# add_strace_to_actions.sh
# Instrument GitHub Actions workflow with strace logging.
# Usage: ./add_strace_to_actions.sh <workflow-file>
# Default workflow file is .github/workflows/main.yml

set -euo pipefail

WORKFLOW="${1:-.github/workflows/main.yml}"
BACKUP="${WORKFLOW}.bak"

if [ ! -f "$WORKFLOW" ]; then
    echo "Workflow file $WORKFLOW not found" >&2
    exit 1
fi

cp "$WORKFLOW" "$BACKUP"

TMP="$(mktemp)"

while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*run:[[:space:]]*(.*) ]]; then
        cmd="${BASH_REMATCH[1]}"
        sanitized=$(echo "$cmd" | sed 's/"/\\"/g')
        rand=$(openssl rand -hex 4)
        echo "${line/run:/run: mkdir -p strace_logs \&\& strace -tt -f -o strace_logs/step_${rand}.log bash -c \"$sanitized\"}" >> "$TMP"
    else
        echo "$line" >> "$TMP"
    fi
done < "$WORKFLOW"

cat <<'UPLOAD' >> "$TMP"
      - name: Upload strace logs
        uses: actions/upload-artifact@v4
        with:
          name: strace_logs
          path: strace_logs/
UPLOAD

mv "$TMP" "$WORKFLOW"

echo "Strace instrumentation added to $WORKFLOW"
echo "Original file backed up to $BACKUP"