#!/usr/bin/env sh
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export REPO_MAINTENANCE_COMMON_DIR="$SELF_DIR/../lib"
. "$SELF_DIR/../lib/common.sh"

package_resolution_args=

if [ "${CI:-}" = "true" ]; then
  package_resolution_args="-disablePackageRepositoryCache"
fi

if ! output="$(
  # shellcheck disable=SC2086
  xcodebuild -showTestPlans \
    -project "$REPO_ROOT/SayBar.xcodeproj" \
    -scheme SayBar \
    $package_resolution_args \
    2>&1
)"; then
  printf '%s\n' "$output" >&2
  die "xcodebuild could not list test plans for the SayBar scheme."
fi

printf '%s\n' "$output" | grep -Fq 'Test plans associated with the scheme "SayBar":' || die "Expected xcodebuild -showTestPlans to report test plans for the SayBar scheme."
printf '%s\n' "$output" | grep -Eq '^[[:space:]]+SayBar[[:space:]]*$' || die "Expected the SayBar scheme to include the SayBar test plan."
