#!/usr/bin/env bash
# AWS context detection — read-only
# Prints account, region, profile, and org info in a parseable format.

set -u

separator() { echo "---"; }

if ! command -v aws >/dev/null 2>&1; then
  echo "ERROR: aws CLI not found in PATH"
  exit 2
fi

echo "### AWS Context"
separator

echo "## Caller identity"
if ! aws sts get-caller-identity --output json 2>/dev/null; then
  echo "ERROR: aws CLI not configured or credentials invalid"
  echo "Hint: run 'aws configure' or check AWS_PROFILE / AWS_ACCESS_KEY_ID env vars"
  exit 3
fi
separator

echo "## Default region"
REGION=$(aws configure get region 2>/dev/null || echo "")
if [ -z "$REGION" ]; then
  REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-not-set}}"
fi
echo "$REGION"
separator

echo "## Profile"
echo "${AWS_PROFILE:-default}"
separator

echo "## Organization"
aws organizations describe-organization --output json 2>/dev/null || echo "no-org-or-no-access"
separator

echo "## Enabled regions"
aws ec2 describe-regions --query 'Regions[].RegionName' --output json 2>/dev/null || echo "unable-to-list"
separator

echo "### End of context"
