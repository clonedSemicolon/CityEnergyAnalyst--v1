#!/bin/bash

WORKFLOW=".github/workflows/main.yml"
BACKUP=".github/workflows/main.yml.bak"

echo "📄 Processing $WORKFLOW"

if ! command -v yq &>/dev/null; then
    echo "❌ yq is not installed. Install it first."
    exit 1
fi

# Backup the original workflow file
cp "$WORKFLOW" "$BACKUP"

# Use a temp output file
TMP="main.strace.yml"
> "$TMP"

# Iterate through the YAML and rewrite run: steps
while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*run:[[:space:]]*(.*) ]]; then
        original_command="${BASH_REMATCH[1]}"
        # Sanitize the command
        sanitized=$(echo "$original_command" | sed 's/"/\\"/g')
        echo "${line/run:/run: mkdir -p strace_logs \&\& strace -tt -f -o strace_logs/step_${RANDOM}.log bash -c \"$sanitized\"}" >> "$TMP"
    else
        echo "$line" >> "$TMP"
    fi
done < "$WORKFLOW"

# Add a final step to upload all strace logs
cat <<EOF >> "$TMP"

      - name: Upload strace logs
        uses: actions/upload-artifact@v4
        with:
          name: strace_logs
          path: strace_logs/
EOF

# Replace the old workflow with the modified one
mv "$TMP" "$WORKFLOW"

echo "✅ Strace added to all 'run' steps and artifact upload appended."
echo "📦 Backup saved at $BACKUP"