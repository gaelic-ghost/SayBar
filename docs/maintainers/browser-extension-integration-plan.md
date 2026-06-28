# Browser Extension Integration Plan

SayBar's browser integration should start WebExtension-first.

The first browser-facing job is to capture readable page text from a user-selected website and hand that text to SayBar for speech. That behavior is naturally browser-extension-shaped: JavaScript reads the document, a popup or background context controls the capture, and the extension asks for page access through the browser permission model.

## Shape Decision

- Use a shared WebExtension core for page-text extraction, popup UI, message names, and payload shape.
- Wrap that core in a Safari Web Extension target for the macOS app.
- Add Chrome, Firefox, and Zen packaging adapters after the shared capture contract is stable.
- Do not use a Safari App Extension as the main implementation path unless a macOS-only SafariServices callback becomes necessary.
- Do not use Safari automation, AppleScript, accessibility automation, or browser UI scripting for page text capture.

## Current Skeleton

- `BrowserExtension/Core/manifest.json` declares the portable extension shell.
- `BrowserExtension/Core/content/extract-page-text.js` extracts visible article/main/body text and a bounded HTML fragment.
- `BrowserExtension/Core/popup/` provides the first manual capture action.
- `BrowserExtension/Core/background.js` receives captured page-text payloads, sends them through Safari native messaging when available, and falls back to the existing embedded `/speech/live` loopback route for non-Safari adapters.
- `BrowserExtension/Adapters/` contains browser-specific manifest overrides for Chrome, Firefox, and Zen.
- `scripts/browser-extension/package-adapters.mjs` materializes reviewable adapter bundles under ignored `Build/BrowserExtensionAdapters/` by copying the shared core and applying only those manifest overrides.
- `SayBarSafariExtension/` wraps the WebExtension resources in a Safari Web Extension app-extension target.
- `SayBarSafariExtension/` converts captured HTML to Markdown-oriented speech text with SwiftSoup, logs a debug summary without the full body, and queues `/speech/live` through SayBar's embedded runtime transport.
- The shared WebExtension core declares `nativeMessaging` because Safari uses `browser.runtime.sendNativeMessage` to reach the containing app extension.
- The shared WebExtension core declares a narrow loopback host permission for `http://127.0.0.1:7339/*` so Chrome and Firefox-family adapters can queue user-initiated captures through the existing embedded runtime route without installing native messaging host manifests.

## Message Contract

The shared WebExtension core currently uses one message:

```json
{
  "type": "saybar.pageTextCaptured",
  "payload": {
    "title": "Example Page",
    "url": "https://example.com/article",
    "text": "Readable page text...",
    "html": "<article>Readable page HTML...</article>",
    "captureMode": "article",
    "capturedAt": "2026-06-24T00:00:00.000Z"
  }
}
```

Treat page text and URLs as sensitive. Do not persist captures in browser storage, app groups, logs, or diagnostics unless a user-facing feature explicitly needs retained history.

The native queue request intentionally lets `SpeakSwiftlyServer` apply `reqPurpose: .speech` from the `/speech/live` route. The browser-provided request context should stay lean: `source`, page-title `topic`, and only relevant browser-origin attributes such as surface, browser name, URL, capture mode, and capture timestamp.

## Browser Adapter Notes

Safari:

- Package the shared WebExtension core in `SayBarSafariExtension`.
- Use Safari Web Extension native messaging for the first user-initiated capture handoff.
- Use App Groups only when a later feature needs shared retained state between the containing app and extension.
- Validate that Safari sees the extension, the user enabled it, and the website permission is granted before debugging capture behavior.

Chrome:

- Use the shared Manifest V3 extension core.
- Package Chrome with `BrowserExtension/Adapters/Chrome/manifest.overrides.json`, which removes the Safari-only native messaging permission and relies on the loopback handoff.
- Prefer the sandbox-compliant loopback handoff before adopting a Chrome native messaging host. The browser adapter should package the shared capture UI and post explicit user-initiated captures to SayBar's existing embedded `/speech/live` endpoint.
- Keep Chrome native messaging host registration as a fallback only. It requires a host manifest in Chrome's `NativeMessagingHosts` search path, an executable host path, and extension-origin allowlisting, so it should be approval-gated before SayBar writes installer-managed files outside the app container.
- Use Chrome Web Store distribution for the browser adapter when the shared extension contract is stable enough for public updates.

Firefox and Zen:

- Treat Zen as Firefox/WebExtensions-compatible until a real Zen-specific packaging or permission difference appears.
- Package Firefox with `BrowserExtension/Adapters/Firefox/manifest.overrides.json` and Zen with `BrowserExtension/Adapters/Zen/manifest.overrides.json`.
- Keep Firefox-family manifest overrides limited to stable Gecko IDs and permission differences until browser validation proves another difference is required.
- Prefer the same sandbox-compliant loopback handoff as Chrome before adopting native messaging. Firefox native messaging also requires an installed native manifest with explicit allowed extension IDs, so it carries the same approval-gated installer cost.
- Give Firefox-family builds a stable extension ID before any native-host fallback is attempted, because Firefox native manifests allow specific extension IDs rather than Chrome extension origins.
- Treat Zen listing, sideloading, and update behavior as a verification item against the current Zen release before committing to a marketplace promise.

## Recommended Cross-Browser Handoff

Use this sequence for non-Safari adapters:

1. Keep the shared capture contract browser-agnostic: title, URL, visible text, bounded HTML, capture mode, and capture timestamp.
2. Package Chrome and Firefox-family adapters that call the existing localhost `/speech/live` endpoint from explicit user action with the narrowest host permission that works.
3. Keep Safari on native messaging so the native extension can perform SwiftSoup-backed Markdown formatting before queueing.
4. Add app UI that checks whether each adapter is installed and whether the local capture endpoint is reachable.
5. Revisit native messaging hosts only if browser store rules, CORS behavior, or local-network permission prompts make the loopback route worse in practice.

The loopback route is the default recommendation because it avoids app-side installation of browser-specific native host manifests and uses the same embedded runtime owner. The tradeoff is that non-Safari adapters currently queue the WebExtension-extracted readable text directly, while Safari gets SwiftSoup-backed Markdown formatting inside the native extension. If Chrome and Firefox-family adapters need the exact same native Markdown formatting, add an explicit upstream browser-capture route to `SpeakSwiftlyServer` or another approved app-facing embedded-server surface rather than creating a second SayBar-owned HTTP listener.

## Distribution And Updates

Safari:

- Ship the Safari Web Extension inside the SayBar macOS app bundle.
- App updates should carry Safari extension updates.
- SayBar should surface a checklist for opening Safari Settings, enabling the extension, and granting per-site permission.

Chrome:

- Publish the Chrome adapter through the Chrome Web Store once the loopback contract and extension listing copy are stable.
- Let the Chrome Web Store own extension install and update delivery.
- SayBar should deep-link to the listing and expose a local connection check instead of writing Chrome extension files directly.

Firefox:

- Publish the Firefox-family adapter through addons.mozilla.org when it is ready for normal users, because release and beta Firefox require signed add-ons.
- Let AMO own listed extension updates when the adapter is public.
- Keep self-distribution only for beta or limited-audience builds that still go through Mozilla signing.

Zen:

- Verify whether the current Zen release installs directly from AMO, supports self-distributed signed XPIs, or needs a Zen-specific listing path before promising in-app installation.
- Treat Zen as a Firefox-family adapter until that verification finds a real difference.

SayBar App:

- Keep browser adapter install controls informational at first: listing links, connection checks, enabled-state troubleshooting, and clear failure messages.
- Do not write Chrome, Firefox, or Zen native messaging host manifests from SayBar unless Gale explicitly approves that installer surface.

## Packaging Command

```sh
node scripts/browser-extension/package-adapters.mjs
```

The command writes generated adapter bundles to `Build/BrowserExtensionAdapters/`. Those bundles are local validation artifacts, not checked-in source.

`scripts/repo-maintenance/validate-all.sh` runs the same packaging command and verifies that generated adapter manifests keep the narrow loopback permission shape, remove the Safari-only native messaging permission, and preserve Firefox-family Gecko IDs.

## Open Decisions

- Whether Chrome, Firefox, and Zen can all use the same localhost `/speech/live` permission shape without broad host permissions after live browser validation.
- Whether non-Safari browser captures need the first-class embedded browser-capture route tracked in SpeakSwiftlyServer issue #127 for native Markdown formatting parity with Safari.
- Whether page text should be chunked in the extension, in SayBar, or in `SpeakSwiftlyServer`.

## Reference Docs

- Apple: [Messaging a Web Extension's Native App](https://developer.apple.com/documentation/safariservices/messaging-a-web-extension-s-native-app)
- Chrome: [Native messaging](https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging)
- Chrome: [Publish in the Chrome Web Store](https://developer.chrome.com/docs/webstore/publish)
- Firefox: [Native manifests](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Native_manifests)
- Firefox: [Signing and distribution overview](https://extensionworkshop.com/documentation/publish/signing-and-distribution-overview/)
- Zen: [Desktop repository](https://github.com/zen-browser/desktop)
