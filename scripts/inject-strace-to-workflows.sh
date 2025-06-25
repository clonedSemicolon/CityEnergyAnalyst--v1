#!/bin/bash

echo "🔍 Searching for workflows in .github/workflows/"

for file in $(find .github/workflows -name '*.yml'); do
  echo "📄 Checking $file"

  has_trigger=$(yq e '
    (.on.push.branches[] == "main" or .on.push.branches[] == "master") or
    (.on.pull_request.branches[] == "main" or .on.pull_request.branches[] == "master")
  ' "$file")

  if [[ "$has_trigger" != "true" ]]; then
    echo "⛔ Skipping $file (no push/merge to main/master)"
    continue
  fi

  echo "✅ $file is eligible. Injecting strace wrapper..."

  job_keys=$(yq e '.jobs | keys | .[]' "$file")
  for job in $job_keys; do
    step_count=$(yq e ".jobs.$job.steps | length" "$file")

    for ((i=0; i<$step_count; i++)); do
      run_command=$(yq e ".jobs.$job.steps[$i].run" "$file")
      if [[ "$run_command" != "null" ]]; then
        # Wrap existing command in strace
        new_command="mkdir -p strace_logs && strace -tt -f -o strace_logs/${job}_step${i}.log bash -c \"${run_command//\"/\\\"}\""
        yq -i ".jobs.$job.steps[$i].run = \"$new_command\"" "$file"
        echo "⚙️  Injected strace in $job -> step[$i]"
      fi
    done

    # Ensure upload-artifact step is added
    yq -i "
      .jobs.$job.steps += [{
        name: \"Upload strace logs\",
        uses: \"actions/upload-artifact@v4\",
        with: {
          name: \"strace_logs\",
          path: \"strace_logs/\"
        }
      }]
    " "$file"
    echo "📦 Upload step added to $job"
  done
done
