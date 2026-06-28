const messageTypes = Object.freeze({
  pageTextCaptured: "saybar.pageTextCaptured"
});

const nativeApplicationID = "com.galewilliams.SayBar";
const loopbackSpeechEndpoint = "http://127.0.0.1:7339/speech/live";
const extensionAPI = globalThis.browser || globalThis.chrome;

let lastCapture = null;

function normalizeCapture(payload) {
  if (!payload || typeof payload !== "object") {
    throw new Error("SayBar browser extension received a page-text capture without an object payload.");
  }

  return {
    title: typeof payload.title === "string" ? payload.title : "",
    url: typeof payload.url === "string" ? payload.url : "",
    text: typeof payload.text === "string" ? payload.text : "",
    html: typeof payload.html === "string" ? payload.html : "",
    captureMode: typeof payload.captureMode === "string" ? payload.captureMode : "page",
    capturedAt: typeof payload.capturedAt === "string" ? payload.capturedAt : new Date().toISOString()
  };
}

async function handOffCaptureToNative(capture) {
  if (typeof extensionAPI.runtime.sendNativeMessage !== "function") {
    return await handOffCaptureToLoopback(capture);
  }

  try {
    return await extensionAPI.runtime.sendNativeMessage(nativeApplicationID, {
      type: messageTypes.pageTextCaptured,
      payload: capture
    });
  } catch (error) {
    return await handOffCaptureToLoopback(capture);
  }
}

async function handOffCaptureToLoopback(capture) {
  const response = await fetch(loopbackSpeechEndpoint, {
    method: "POST",
    headers: {
      "Accept": "application/json",
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      text: capture.text,
      request_context: {
        reqPurpose: "speech",
        source: "Browser via SayBar",
        topic: normalizedOptional(capture.title),
        attributes: {
          surface: "browser_extension",
          "browser.name": "Browser",
          "browser.url": capture.url,
          "browser.capture_mode": capture.captureMode,
          "browser.captured_at": capture.capturedAt,
          "browser.handoff": "loopback"
        }
      }
    })
  });

  const responseText = await response.text();
  if (!response.ok) {
    throw new Error(`SayBar browser extension could not queue the page-text capture through the local SayBar endpoint. HTTP ${response.status}: ${responseText}`);
  }

  const accepted = responseText ? JSON.parse(responseText) : {};
  if (typeof accepted.request_id !== "string" || !accepted.request_id) {
    throw new Error("SayBar browser extension queued the page-text capture through the local endpoint, but the response did not include a request_id.");
  }

  return {
    ok: true,
    nativeHandoff: "loopback",
    requestID: accepted.request_id,
    characterCount: capture.text.length
  };
}

function normalizedOptional(value) {
  if (typeof value !== "string") {
    return null;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

extensionAPI.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (!message || message.type !== messageTypes.pageTextCaptured) {
    return false;
  }

  Promise.resolve()
    .then(async () => {
      lastCapture = normalizeCapture(message.payload);
      return await handOffCaptureToNative(lastCapture);
    })
    .then((response) => {
      sendResponse(response);
    })
    .catch((error) => {
      sendResponse({
        ok: false,
        error: error instanceof Error ? error.message : "SayBar browser extension could not hand the page-text capture to SayBar."
      });
    });

  return true;
});
