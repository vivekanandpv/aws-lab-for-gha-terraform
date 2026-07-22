#!/usr/bin/env bash
set -euo pipefail

CSV_FILE="${1:-students.csv}"
OUTPUT_FILE="${2:-students.auto.tfvars}"
[[ -f "$CSV_FILE" ]] || { echo "ERROR: $CSV_FILE not found." >&2; exit 1; }

{
  echo 'students = {'
  while IFS=, read -r student_id github_username; do
    student_id="${student_id//$'\r'/}"
    [[ "$student_id" == "student_id" || -z "$student_id" ]] && continue
    if [[ ! "$student_id" =~ ^student(0[1-9]|[12][0-9]|30)$ ]]; then
      echo "ERROR: invalid student ID: $student_id" >&2
      exit 1
    fi
    number=$((10#${student_id#student}))
    port=$((8100 + number))
    cat <<HCL
  $student_id = {
    github_repository = "${student_id}-training-app"
    port              = $port
  }
HCL
  done < "$CSV_FILE"
  echo '}'
} > "$OUTPUT_FILE"

echo "Created $OUTPUT_FILE"
