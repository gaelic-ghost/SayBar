const messageTypes = Object.freeze({
  pageTextCaptured: "saybar.pageTextCaptured"
});

const nativeApplicationID = "application.id";
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
    return {
      ok: true,
      nativeHandoff: "unavailable",
      characterCount: capture.text.length
    };
  }

  return await extensionAPI.runtime.sendNativeMessage(nativeApplicationID, {
    type: messageTypes.pageTextCaptured,
    payload: capture
  });
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
        error: error instanceof Error ? error.message : "SayBar browser extension could not hand the page-text capture to the native extension."
      });
    });

  return true;
});
