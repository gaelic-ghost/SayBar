#!/usr/bin/env sh
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export REPO_MAINTENANCE_COMMON_DIR="$SELF_DIR/../lib"
. "$SELF_DIR/../lib/common.sh"

if [ ! -f "$REPO_ROOT/project.yml" ]; then
  log "Skipping XcodeGen generated-project validation because project.yml is not present."
  exit 0
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  die "XcodeGen generated-project validation requires xcodegen, but it is not installed or not on PATH. Install the validated XcodeGen version before changing project.yml or generated project files."
fi

before_manifest="$(mktemp)"
after_manifest="$(mktemp)"
trap 'rm -f "$before_manifest" "$after_manifest"' EXIT

(
  cd "$REPO_ROOT"
  git ls-files SayBar.xcodeproj | sort | while IFS= read -r project_file; do
    shasum "$project_file"
  done
) > "$before_manifest"

(
  cd "$REPO_ROOT"
  xcodegen generate --spec project.yml --use-cache >/dev/null
)

(
  cd "$REPO_ROOT"
  git ls-files SayBar.xcodeproj | sort | while IFS= read -r project_file; do
    shasum "$project_file"
  done
) > "$after_manifest"

if ! cmp -s "$before_manifest" "$after_manifest"; then
  die "XcodeGen generated-project validation found stale generated output. Review the changed project.yml, Config/SayBar.xcconfig, and SayBar.xcodeproj files, then commit the regenerated project."
fi

log "XcodeGen generated-project output is in sync."
