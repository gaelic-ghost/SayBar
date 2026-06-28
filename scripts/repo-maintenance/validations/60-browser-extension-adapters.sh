#!/usr/bin/env sh
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export REPO_MAINTENANCE_COMMON_DIR="$SELF_DIR/../lib"
. "$SELF_DIR/../lib/common.sh"

if [ ! -f "$REPO_ROOT/BrowserExtension/Core/manifest.json" ]; then
  log "Skipping browser extension adapter validation because BrowserExtension/Core/manifest.json is not present."
  exit 0
fi

if ! command -v node >/dev/null 2>&1; then
  die "Browser extension adapter validation requires node, but node is not installed or not on PATH."
fi

if ! command -v jq >/dev/null 2>&1; then
  die "Browser extension adapter validation requires jq, but jq is not installed or not on PATH."
fi

node --check "$REPO_ROOT/scripts/browser-extension/package-adapters.mjs" >/dev/null
node --check "$REPO_ROOT/BrowserExtension/Core/background.js" >/dev/null
node --check "$REPO_ROOT/BrowserExtension/Core/content/extract-page-text.js" >/dev/null
node --check "$REPO_ROOT/BrowserExtension/Core/popup/popup.js" >/dev/null

(
  cd "$REPO_ROOT"
  node scripts/browser-extension/package-adapters.mjs >/dev/null
)

for adapter in chrome firefox zen; do
  manifest_path="$REPO_ROOT/Build/BrowserExtensionAdapters/$adapter/manifest.json"
  [ -f "$manifest_path" ] || die "Browser extension adapter validation expected generated manifest $manifest_path."

  jq -e '.manifest_version == 3' "$manifest_path" >/dev/null || die "Generated $adapter manifest must use Manifest V3."
  jq -e '.host_permissions == ["http://127.0.0.1:7339/*"]' "$manifest_path" >/dev/null || die "Generated $adapter manifest must use only the narrow SayBar loopback host permission."
  jq -e '(.permissions | index("activeTab")) and (.permissions | index("scripting"))' "$manifest_path" >/dev/null || die "Generated $adapter manifest must include activeTab and scripting permissions."
  jq -e '(.permissions | index("nativeMessaging") | not)' "$manifest_path" >/dev/null || die "Generated $adapter manifest must not include the Safari-only nativeMessaging permission."
done

jq -e '.browser_specific_settings.gecko.id == "page-speaker@saybar.galewilliams.com"' "$REPO_ROOT/Build/BrowserExtensionAdapters/firefox/manifest.json" >/dev/null || die "Generated Firefox manifest must include the stable Gecko extension ID."
jq -e '.browser_specific_settings.gecko.id == "page-speaker-zen@saybar.galewilliams.com"' "$REPO_ROOT/Build/BrowserExtensionAdapters/zen/manifest.json" >/dev/null || die "Generated Zen manifest must include the stable Gecko extension ID."

log "Browser extension adapter manifests are generated and permission-scoped."
