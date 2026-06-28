import { cpSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(scriptDirectory, "../..");
const coreDirectory = join(repoRoot, "BrowserExtension/Core");
const adaptersDirectory = join(repoRoot, "BrowserExtension/Adapters");
const outputRoot = join(repoRoot, "Build/BrowserExtensionAdapters");

const adapters = [
  { name: "chrome", overridePath: "Chrome/manifest.overrides.json" },
  { name: "firefox", overridePath: "Firefox/manifest.overrides.json" },
  { name: "zen", overridePath: "Zen/manifest.overrides.json" }
];

function readJSON(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}

function mergeManifest(base, override) {
  return {
    ...base,
    ...override
  };
}

rmSync(outputRoot, { force: true, recursive: true });
mkdirSync(outputRoot, { recursive: true });

const baseManifest = readJSON(join(coreDirectory, "manifest.json"));

for (const adapter of adapters) {
  const outputDirectory = join(outputRoot, adapter.name);
  const override = readJSON(join(adaptersDirectory, adapter.overridePath));
  const manifest = mergeManifest(baseManifest, override);

  cpSync(coreDirectory, outputDirectory, { recursive: true });
  writeFileSync(
    join(outputDirectory, "manifest.json"),
    `${JSON.stringify(manifest, null, 2)}\n`
  );
  console.log(`Packaged ${adapter.name} browser adapter at ${outputDirectory}`);
}
