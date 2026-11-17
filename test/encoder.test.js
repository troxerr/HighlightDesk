const test = require("node:test");
const assert = require("node:assert/strict");
const { videoEncoderArgs, bitrateFor, normalizedEncoder } = require("../lib/encoder.js");

test("default encoder is hardware H.264 without GPL libx264", () => {
  const args = videoEncoderArgs({ codec: "h264_videotoolbox", bitrate: "8M" });
  assert.deepEqual(args.slice(0, 2), ["-c:v", "h264_videotoolbox"]);
  assert.ok(args.includes("8M"));
  assert.ok(args.includes("-allow_sw"));
  assert.equal(args.includes("libx264"), false);
});

test("libx264 is available only as a development fallback", () => {
  const args = videoEncoderArgs({ codec: "libx264" });
  assert.deepEqual(args.slice(0, 2), ["-c:v", "libx264"]);
  assert.ok(args.includes("veryfast"));
});

test("bitrate scales with canvas size and stays bounded", () => {
  assert.equal(bitrateFor(1080, 1920), "7.5M");
  assert.equal(bitrateFor(640, 360), "4M");
  assert.equal(bitrateFor(3840, 2160), "16M");
});

test("unknown encoders fall back to VideoToolbox", () => {
  assert.equal(normalizedEncoder("libx264"), "libx264");
  assert.equal(normalizedEncoder("nope"), "h264_videotoolbox");
});
