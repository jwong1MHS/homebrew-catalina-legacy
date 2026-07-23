#!/usr/bin/env bash
#
# extract-old-cask.sh
#
# Extracts an old version of a Homebrew cask from the homebrew/cask git
# history, mirroring what `brew extract` does for formulae (which has
# no cask equivalent). Finds the commit where the cask matches the
# given version and writes that file, unmodified, to the given path.
#
# Usage:
#   ./extract-old-cask.sh <cask-name> <version> <output-file>
#
# Example:
#   ./extract-old-cask.sh kitty 0.26.5 Casks/kitty.rb

set -euo pipefail

CASK_NAME="${1:-}"
VERSION="${2:-}"
OUTPUT_FILE="${3:-}"

if [[ -z "${CASK_NAME}" || -z "${VERSION}" || -z "${OUTPUT_FILE}" ]]
then
  echo "Usage: ${0} <cask-name> <version> <output-file>"
  echo "Example: ${0} kitty 0.26.5 Casks/kitty.rb"
  exit 1
fi

# Resolve a relative OUTPUT_FILE against the current directory before
# we cd into the homebrew/cask tap below.
ORIGINAL_DIR="$(pwd)"
if [[ "${OUTPUT_FILE}" != /* ]]
then
  OUTPUT_FILE="${ORIGINAL_DIR}/${OUTPUT_FILE}"
fi

echo "==> Ensuring homebrew/cask is tapped with full git history..."
brew tap homebrew/cask --force

CASK_TAP_DIR="$(brew --repository homebrew/cask)"
cd "${CASK_TAP_DIR}"

echo "==> Locating cask file for '${CASK_NAME}'..."
CASK_PATH="$(git ls-files 'Casks/*' | grep -E "/${CASK_NAME}\.rb$" || true)"

if [[ -z "${CASK_PATH}" ]]
then
  echo "Error: could not find Casks/*/${CASK_NAME}.rb in homebrew/cask."
  exit 1
fi

echo "==> Searching commit history for version '${VERSION}'..."
COMMIT_HASH="$(git log --oneline -- "${CASK_PATH}" | grep -iF "${VERSION}" | awk '{print $1}' | tail -n1 || true)"

if [[ -z "${COMMIT_HASH}" ]]
then
  echo "Error: version '${VERSION}' of '${CASK_NAME}' was not found in commit history."
  exit 1
fi

mkdir -p "$(dirname "${OUTPUT_FILE}")"
git show "${COMMIT_HASH}:${CASK_PATH}" >"${OUTPUT_FILE}"

echo "==> Wrote: ${OUTPUT_FILE}"
