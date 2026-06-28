import { readFileSync } from "node:fs";
import { strict as assert } from "node:assert";
import { Script, createContext } from "node:vm";
import { resolve } from "node:path";

const backgroundPath = resolve("BrowserExtension/Core/background.js");
const source = readFileSync(backgroundPath, "utf8");

function runBackground({ sendNativeMessage, fetch }) {
  let listener;
  const context = createContext({
    browser: {
      runtime: {
        sendNativeMessage,
        onMessage: {
          addListener(callback) {
            listener = callback;
          }
        }
      }
    },
    fetch,
    Date,
    Error,
    JSON,
    Object,
    Promise
  });

  new Script(source, { filename: backgroundPath }).runInContext(context);
  assert.equal(typeof listener, "function");
  return listener;
}

async function dispatchCapture(listener, payload) {
  let response;
  const didKeepChannelOpen = listener(
    {
      type: "saybar.pageTextCaptured",
      payload
    },
    {},
    (value) => {
      response = value;
    }
  );

  assert.equal(didKeepChannelOpen, true);
  await new Promise((resolvePromise) => setTimeout(resolvePromise, 0));
  return response;
}

const capture = {
  title: " Example Article ",
  url: "https://example.com/articles/one",
  text: "Speak this article.",
  html: "<article><h1>Example Article</h1></article>",
  captureMode: "article",
  capturedAt: "2026-06-28T12:00:00.000Z"
};

{
  let submittedRequest;
  const listener = runBackground({
    sendNativeMessage: undefined,
    fetch: async (url, request) => {
      submittedRequest = {
        url,
        request
      };

      return {
        ok: true,
        text: async () => JSON.stringify({ request_id: "request-123" })
      };
    }
  });

  const response = await dispatchCapture(listener, capture);
  const body = JSON.parse(submittedRequest.request.body);

  assert.equal(submittedRequest.url, "http://127.0.0.1:7339/speech/live");
  assert.equal(submittedRequest.request.method, "POST");
  assert.equal(submittedRequest.request.headers.Accept, "application/json");
  assert.equal(submittedRequest.request.headers["Content-Type"], "application/json");
  assert.equal(body.text, "Speak this article.");
  assert.equal(body.request_context.reqPurpose, "speech");
  assert.equal(body.request_context.source, "Browser via SayBar");
  assert.equal(body.request_context.topic, "Example Article");
  assert.deepEqual(body.request_context.attributes, {
    surface: "browser_extension",
    "browser.name": "Browser",
    "browser.url": "https://example.com/articles/one",
    "browser.capture_mode": "article",
    "browser.captured_at": "2026-06-28T12:00:00.000Z",
    "browser.handoff": "loopback"
  });
  assert.equal(response.ok, true);
  assert.equal(response.nativeHandoff, "loopback");
  assert.equal(response.requestID, "request-123");
  assert.equal(response.characterCount, "Speak this article.".length);
}

{
  let loopbackWasCalled = false;
  const listener = runBackground({
    sendNativeMessage: async () => {
      throw new Error("Native messaging unavailable.");
    },
    fetch: async () => {
      loopbackWasCalled = true;
      return {
        ok: true,
        text: async () => JSON.stringify({ request_id: "request-456" })
      };
    }
  });

  const response = await dispatchCapture(listener, capture);

  assert.equal(loopbackWasCalled, true);
  assert.equal(response.ok, true);
  assert.equal(response.nativeHandoff, "loopback");
  assert.equal(response.requestID, "request-456");
}

{
  const listener = runBackground({
    sendNativeMessage: undefined,
    fetch: async () => ({
      ok: false,
      status: 503,
      text: async () => "embedded runtime unavailable"
    })
  });

  const response = await dispatchCapture(listener, capture);

  assert.equal(response.ok, false);
  assert.match(
    response.error,
    /SayBar browser extension could not queue the page-text capture through the local SayBar endpoint\. HTTP 503: embedded runtime unavailable/
  );
}

console.log("Browser extension background handoff tests passed.");
