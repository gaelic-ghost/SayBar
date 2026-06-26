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
- `BrowserExtension/Core/background.js` receives captured page-text payloads and sends them through Safari native messaging when available.
- `SayBarSafariExtension/` wraps the WebExtension resources in a Safari Web Extension app-extension target.
- `SayBarSafariExtension/` converts captured HTML to Markdown-oriented speech text with SwiftSoup, logs a debug summary without the full body, and queues `/speech/live` through SayBar's embedded runtime transport.

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
- Add Chrome packaging and native messaging host registration only when SayBar is ready to receive browser captures outside Safari.

Firefox and Zen:

- Treat Zen as Firefox/WebExtensions-compatible until a real Zen-specific packaging or permission difference appears.
- Add Firefox manifest overrides only where Firefox requires them.
- Add native messaging host registration only when SayBar exposes a stable native capture endpoint.

## Open Decisions

- Whether Chrome, Firefox, and Zen should use native messaging hosts, a localhost endpoint, or another browser-family-specific app handoff once Safari is working.
- Whether to request broad host permissions or stay with user-initiated `activeTab` capture.
- Whether page text should be chunked in the extension, in SayBar, or in `SpeakSwiftlyServer`.
