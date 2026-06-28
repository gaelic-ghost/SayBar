const messageTypes = Object.freeze({
  pageTextCaptured: "saybar.pageTextCaptured"
});

const extensionAPI = globalThis.browser || globalThis.chrome;

const statusElement = document.getElementById("status");
const captureButton = document.getElementById("capture-page");

function setStatus(message) {
  statusElement.textContent = message;
}

async function activeTab() {
  const [tab] = await extensionAPI.tabs.query({
    active: true,
    currentWindow: true
  });

  if (!tab || typeof tab.id !== "number") {
    throw new Error("SayBar could not find an active browser tab to capture.");
  }

  return tab;
}

async function capturePageText() {
  const tab = await activeTab();

  await extensionAPI.scripting.executeScript({
    target: { tabId: tab.id },
    files: ["content/extract-page-text.js"]
  });

  const [result] = await extensionAPI.scripting.executeScript({
    target: { tabId: tab.id },
    func: () => globalThis.saybarExtractPageText()
  });

  const capture = result && result.result;
  if (!capture || !capture.text) {
    throw new Error("SayBar did not find readable text on this page.");
  }

  const response = await extensionAPI.runtime.sendMessage({
    type: messageTypes.pageTextCaptured,
    payload: capture
  });

  if (!response || !response.ok) {
    throw new Error(response && response.error ? response.error : "SayBar could not queue the captured page text.");
  }

  if (response.requestID) {
    setStatus(`Queued ${response.characterCount} characters for speech.`);
  } else {
    throw new Error("SayBar captured the page text but did not receive a queue confirmation from the native app.");
  }
}

captureButton.addEventListener("click", () => {
  setStatus("Capturing page text...");
  capturePageText().catch((error) => {
    setStatus(error instanceof Error ? error.message : "SayBar could not capture page text.");
  });
});
