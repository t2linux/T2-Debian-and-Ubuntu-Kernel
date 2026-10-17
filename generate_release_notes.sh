#!/bin/bash
#
# Generate the GitHub release body: commits since the previous release tag,
# a compare link and the installation instructions.
#
# Usage: ./generate_release_notes.sh <current tag, e.g. v7.2.11-2>
# Needs full history and tags (actions/checkout with fetch-depth: 0).

set -eu -o pipefail

CURRENT_TAG="$1"
REPO_URL="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-t2linux/T2-Debian-and-Ubuntu-Kernel}"
INSTRUCTIONS="$(dirname "$0")/.github/workflows/instructions.txt"

# Nearest earlier release tag reachable from HEAD. The current tag is excluded
# so a rebuild of an already tagged commit still diffs against the release
# before it; xanmod tags belong to another branch.
PREV_TAG=$(git describe --tags --abbrev=0 --match 'v[0-9]*' \
  --exclude "${CURRENT_TAG}" --exclude '*xanmod*' HEAD 2>/dev/null || true)

echo "## What's changed"
echo

if [ -n "${PREV_TAG}" ]
then
  RANGE="${PREV_TAG}..HEAD"
else
  RANGE="HEAD"
fi

CHANGES=$(git log --no-merges --format="- %s (%h)" "${RANGE}")
if [ -n "${CHANGES}" ]
then
  echo "${CHANGES}"
else
  echo "- Rebuild without source changes"
fi

if [ -n "${PREV_TAG}" ]
then
  echo
  echo "**Full changelog**: ${REPO_URL}/compare/${PREV_TAG}...${CURRENT_TAG}"
fi

echo
echo "## Installation"
echo
cat "${INSTRUCTIONS}"
