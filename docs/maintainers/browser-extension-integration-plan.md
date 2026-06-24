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
- `BrowserExtension/Core/content/extract-page-text.js` extracts visible article/main/body text with a bounded character limit.
- `BrowserExtension/Core/popup/` provides the first manual capture action.
- `BrowserExtension/Core/background.js` receives captured page-text payloads and keeps the native handoff marked as pending.
- `SayBarSafariExtension/` wraps the WebExtension resources in a Safari Web Extension app-extension target.

## Message Contract

The shared WebExtension core currently uses one message:

```json
{
  "type": "saybar.pageTextCaptured",
  "payload": {
    "title": "Example Page",
    "url": "https://example.com/article",
    "text": "Readable page text...",
    "capturedAt": "2026-06-24T00:00:00.000Z"
  }
}
```

Treat page text and URLs as sensitive. Do not persist captures in browser storage, app groups, logs, or diagnostics unless a user-facing feature explicitly needs retained history.

## Browser Adapter Notes

Safari:

- Package the shared WebExtension core in `SayBarSafariExtension`.
- Use Safari Web Extension messaging or app-group storage only when the SayBar handoff needs it.
- Validate that Safari sees the extension, the user enabled it, and the website permission is granted before debugging capture behavior.

Chrome:

- Use the shared Manifest V3 extension core.
- Add Chrome packaging and native messaging host registration only when SayBar is ready to receive browser captures outside Safari.

Firefox and Zen:

- Treat Zen as Firefox/WebExtensions-compatible until a real Zen-specific packaging or permission difference appears.
- Add Firefox manifest overrides only where Firefox requires them.
- Add native messaging host registration only when SayBar exposes a stable native capture endpoint.

## Open Decisions

- Whether browser captures should queue directly as live speech or open an editable preview in SayBar first.
- Whether to use native messaging, app-group handoff, a localhost endpoint, or a custom URL command for each browser family.
- Whether to request broad host permissions or stay with user-initiated `activeTab` capture.
- Whether page text should be chunked in the extension, in SayBar, or in `SpeakSwiftlyServer`.
