#!/usr/bin/env bash
set -euo pipefail

ORG="${ORG:?Set ORG, for example: export ORG=caelus-gha-training}"
TEMPLATE_REPO="${TEMPLATE_REPO:-springboot-training-template}"
CSV_FILE="${1:-students.csv}"

command -v gh >/dev/null || { echo "ERROR: GitHub CLI (gh) is not installed." >&2; exit 1; }
[[ -f "$CSV_FILE" ]] || { echo "ERROR: $CSV_FILE not found." >&2; exit 1; }
gh auth status >/dev/null

echo "Checking template repository: $ORG/$TEMPLATE_REPO"
gh repo view "$ORG/$TEMPLATE_REPO" >/dev/null

while IFS=, read -r student_id github_username; do
  student_id="${student_id//$'\r'/}"
  github_username="${github_username//$'\r'/}"
  [[ "$student_id" == "student_id" || -z "$student_id" ]] && continue

  if [[ ! "$student_id" =~ ^student(0[1-9]|[12][0-9]|30)$ ]]; then
    echo "ERROR: invalid student ID: $student_id" >&2
    exit 1
  fi
  if [[ -z "$github_username" || "$github_username" == replace-me-* ]]; then
    echo "ERROR: missing real GitHub username for $student_id" >&2
    exit 1
  fi

  repo="${student_id}-training-app"
  full_repo="$ORG/$repo"

  if gh repo view "$full_repo" >/dev/null 2>&1; then
    echo "Repository already exists: $full_repo"
  else
    echo "Creating $full_repo from $ORG/$TEMPLATE_REPO"
    gh repo create "$full_repo" \
      --private \
      --template "$ORG/$TEMPLATE_REPO" \
      --description "GitHub Actions deployment lab for $student_id" \
      --disable-issues \
      --disable-wiki
  fi

  echo "Inviting $github_username to $full_repo with Write access"
  gh api --method PUT \
    -H "Accept: application/vnd.github+json" \
    "/repos/$ORG/$repo/collaborators/$github_username" \
    -f permission=push >/dev/null

done < "$CSV_FILE"

echo "Done. Learners must accept their GitHub invitations."
