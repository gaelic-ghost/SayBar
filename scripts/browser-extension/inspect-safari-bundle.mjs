import { existsSync, readFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { strict as assert } from "node:assert";

const appPath = resolve(process.argv[2] || "Build/Products/Debug/SayBar.app");
const extensionPath = join(appPath, "Contents/PlugIns/SayBarSafariExtension.appex");
const resourcesPath = join(extensionPath, "Contents/Resources");
const manifestPath = join(resourcesPath, "manifest.json");

function assertFile(path) {
  assert.ok(existsSync(path), `Expected ${path} to exist.`);
}

assertFile(appPath);
assertFile(extensionPath);
assertFile(manifestPath);
assertFile(join(resourcesPath, "background.js"));
assertFile(join(resourcesPath, "content/extract-page-text.js"));
assertFile(join(resourcesPath, "popup/popup.html"));
assertFile(join(resourcesPath, "popup/popup.css"));
assertFile(join(resourcesPath, "popup/popup.js"));

const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));

assert.equal(manifest.manifest_version, 3);
assert.equal(manifest.name, "SayBar Page Speaker");
assert.equal(manifest.background?.service_worker, "background.js");
assert.equal(manifest.action?.default_popup, "popup/popup.html");
assert.deepEqual(manifest.host_permissions, ["http://127.0.0.1:7339/*"]);
assert.ok(manifest.permissions.includes("activeTab"));
assert.ok(manifest.permissions.includes("nativeMessaging"));
assert.ok(manifest.permissions.includes("scripting"));

console.log(`Safari Web Extension resources are present in ${extensionPath}.`);
