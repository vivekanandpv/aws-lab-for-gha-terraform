#!/usr/bin/env bash
set -euo pipefail

ORG="${ORG:?Set ORG, for example: export ORG=caelus-gha-training}"

command -v gh >/dev/null || { echo "ERROR: GitHub CLI (gh) is not installed." >&2; exit 1; }
command -v terraform >/dev/null || { echo "ERROR: terraform is not installed." >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq is not installed." >&2; exit 1; }
gh auth status >/dev/null

CONFIG_JSON="$(terraform output -json student_configuration)"
AWS_REGION="$(terraform output -raw aws_region)"

jq -c 'to_entries[]' <<< "$CONFIG_JSON" | while read -r entry; do
  student_id="$(jq -r '.key' <<< "$entry")"
  repo="$(jq -r '.value.github_repository' <<< "$entry")"
  role_arn="$(jq -r '.value.role_arn' <<< "$entry")"
  ecr_repository="$(jq -r '.value.ecr_repository' <<< "$entry")"
  ssm_document="$(jq -r '.value.ssm_document' <<< "$entry")"
  instance_id="$(jq -r '.value.instance_id' <<< "$entry")"
  full_repo="$ORG/$repo"

  echo "Configuring Actions variables for $full_repo"
  gh variable set AWS_REGION         --repo "$full_repo" --body "$AWS_REGION"
  gh variable set AWS_ROLE_ARN       --repo "$full_repo" --body "$role_arn"
  gh variable set ECR_REPOSITORY     --repo "$full_repo" --body "$ecr_repository"
  gh variable set SSM_DOCUMENT       --repo "$full_repo" --body "$ssm_document"
  gh variable set CALVIN_INSTANCE_ID --repo "$full_repo" --body "$instance_id"
done

echo "All learner repositories now have their Actions variables."
