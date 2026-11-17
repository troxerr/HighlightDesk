const test = require("node:test");
const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { buildReframeFilter, buildArgs, reframeClip } = require("../lib/reframe.js");

const ffmpeg = spawnSync("ffmpeg", ["-version"], { stdio: "ignore" }).status === 0;
const ffprobe = spawnSync("ffprobe", ["-version"], { stdio: "ignore" }).status === 0;

test("buildReframeFilter creates a blurred 9:16 canvas with a centered foreground", () => {
  const filter = buildReframeFilter({ width: 1080, height: 1920, blur: 20 });
  assert.match(filter, /scale=540:960:force_original_aspect_ratio=increase/);
  assert.match(filter, /gblur=sigma=20:steps=5/);
  assert.match(filter, /scale=1080:1920:force_original_aspect_ratio=decrease/);
  assert.match(filter, /overlay=\(W-w\)\/2:\(H-h\)\/2/);
  assert.match(filter, /format=yuv420p/);
});

test("buildArgs encodes an MP4 with optional audio", () => {
  const args = buildArgs({ input: "/tmp/in.mp4", output: "/tmp/out.mp4", width: 1080, height: 1920, blur: 20, crf: 20, preset: "veryfast" });
  const joined = args.join(" ");
  assert.match(joined, /-filter_complex/);
  assert.match(joined, /-map \[v\]/);
  assert.match(joined, /-map 0:a\?/);
  assert.match(joined, /-movflags \+faststart/);
  assert.equal(args.at(-1), "/tmp/out.mp4");
});

test("reframeClip reports missing input", async () => {
  const result = await reframeClip({ input: "/tmp/does-not-exist-highlight-desk.mp4", output: "/tmp/out.mp4" });
  assert.equal(result.ok, false);
  assert.match(result.error, /Input not found/);
});

test("reframes a landscape clip into a 1080x1920 MP4", { skip: !ffmpeg || !ffprobe }, async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "highlight-desk-reframe-"));
  const input = path.join(dir, "input.mp4");
  const output = path.join(dir, "vertical.mp4");
  try {
    const generated = spawnSync("ffmpeg", [
      "-hide_banner", "-loglevel", "error", "-y",
      "-f", "lavfi", "-i", "testsrc=size=640x360:rate=30",
      "-f", "lavfi", "-i", "sine=frequency=440",
      "-t", "4", "-c:v", "h264_videotoolbox", "-b:v", "4M", "-allow_sw", "1", "-pix_fmt", "yuv420p",
      "-c:a", "aac", input
    ], { stdio: "ignore", timeout: 60000 });
    assert.equal(generated.status, 0);

    const result = await reframeClip({ input, output, width: 1080, height: 1920, crf: 24, preset: "ultrafast" });
    assert.equal(result.ok, true, result.error);
    assert.equal(fs.existsSync(output), true);
    assert.equal(fs.existsSync(output + ".partial"), false);

    const dimensions = spawnSync("ffprobe", [
      "-v", "error", "-select_streams", "v:0",
      "-show_entries", "stream=width,height", "-of", "csv=s=x:p=0", output
    ], { encoding: "utf8", timeout: 30000 });
    assert.equal(dimensions.stdout.trim(), "1080x1920");

    const duration = spawnSync("ffprobe", [
      "-v", "error", "-show_entries", "format=duration", "-of", "default=nw=1:nk=1", output
    ], { encoding: "utf8", timeout: 30000 });
    const seconds = Number(duration.stdout.trim());
    assert.ok(seconds >= 3.5 && seconds <= 4.5, `unexpected duration ${seconds}`);

    const audio = spawnSync("ffprobe", [
      "-v", "error", "-select_streams", "a:0",
      "-show_entries", "stream=codec_name", "-of", "default=nw=1:nk=1", output
    ], { encoding: "utf8", timeout: 30000 });
    assert.equal(audio.stdout.trim(), "aac");
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});
