const messageTypes = Object.freeze({
  pageTextCaptured: "saybar.pageTextCaptured"
});

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
    capturedAt: typeof payload.capturedAt === "string" ? payload.capturedAt : new Date().toISOString()
  };
}

extensionAPI.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (!message || message.type !== messageTypes.pageTextCaptured) {
    return false;
  }

  try {
    lastCapture = normalizeCapture(message.payload);
    sendResponse({
      ok: true,
      nativeHandoff: "pending",
      characterCount: lastCapture.text.length
    });
  } catch (error) {
    sendResponse({
      ok: false,
      error: error instanceof Error ? error.message : "SayBar browser extension could not normalize the page-text capture payload."
    });
  }

  return true;
});
