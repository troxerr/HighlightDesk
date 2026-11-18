"use strict";

// Scripted self-test of the real window, used by CI (HIGHLIGHT_DESK_SMOKE=<dir>).
// It feeds a local video (HIGHLIGHT_DESK_INPUT) to the packaged recorder, saves
// a highlight, screenshots every page, and writes <dir>/result.json.
// Exit code 0 means every step passed.

const fs = require("node:fs");
const path = require("node:path");
const { app } = require("electron");

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function waitFor(check, ms, label) {
  const end = Date.now() + ms;
  for (;;) {
    const value = await check();
    if (value) return value;
    if (Date.now() > end) throw new Error(`timed out waiting for ${label}`);
    await sleep(500);
  }
}

async function run({ win, services, dir, send }) {
  const result = { steps: [], ok: false, node: process.versions.node, electron: process.versions.electron, execPath: process.execPath, dir };
  const shots = path.join(dir, "screenshots");
  fs.mkdirSync(shots, { recursive: true });
  const step = (name, detail) => { result.steps.push({ name, detail: detail || "" }); console.log(`[smoke] ${name}${detail ? `: ${detail}` : ""}`); };
  const shot = async (name) => {
    await sleep(400);
    const image = await win.webContents.capturePage();
    fs.writeFileSync(path.join(shots, `${name}.png`), image.toPNG());
    step("screenshot", name);
  };
  const page = async (name) => { send("navigate", name); await sleep(300); };
  const watchdog = setTimeout(() => finish(new Error("overall time limit reached")), 240000);

  async function finish(error) {
    clearTimeout(watchdog);
    if (error) { result.error = String(error.stack || error.message || error); console.error("[smoke] FAILED", result.error); }
    else result.ok = true;
    try { fs.writeFileSync(path.join(dir, "result.json"), JSON.stringify(result, null, 2)); } catch {}
    try { await services.core.shutdown(); } catch {}
    app.exit(result.ok ? 0 : 1);
  }

  try {
    await new Promise((resolve) => (win.webContents.isLoading() ? win.webContents.once("did-finish-load", resolve) : resolve()));
    step("window loaded", win.getTitle());
    if (Number(process.versions.node.split(".")[0]) < 22) throw new Error(`Node ${process.versions.node} is too old for the recorder (needs 22+)`);
    if (!process.env.HIGHLIGHT_DESK_INPUT || !fs.existsSync(process.env.HIGHLIGHT_DESK_INPUT)) throw new Error("HIGHLIGHT_DESK_INPUT must point at a test video");

    await shot("capture-idle");
    await page("clips"); await shot("clips-empty");
    await page("settings"); await shot("settings");
    await page("capture");

    await services.core.start("smoke_channel", { acknowledge: true });
    step("capture started");
    await waitFor(() => services.core.snapshot().capture.phase === "watching" && services.core.snapshot().capture.mediaTime >= 6, 90000, "6 seconds of recorded video");
    await shot("capture-watching");

    await waitFor(() => { try { return services.core.saveHighlight(); } catch { return false; } }, 30000, "the recorder to accept a highlight");
    step("highlight requested");
    const clip = await waitFor(() => services.core.clips.list().find((item) => item.available), 150000, "the saved clip");
    result.clip = { path: clip.localPath, bytes: fs.statSync(clip.localPath).size };
    step("clip saved", `${result.clip.bytes} bytes`);

    await page("clips"); await shot("clips-with-clip");
    await page("capture");
    await services.core.stop();
    step("capture stopped");
    await finish();
  } catch (error) {
    try { await shot("failure"); } catch {}
    await finish(error);
  }
}

module.exports = { run };
