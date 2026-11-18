const test = require("node:test");
const assert = require("node:assert/strict");
const { videoEncoderArgs, bitrateFor, normalizedEncoder, resolveEncoder } = require("../lib/encoder.js");

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

test("unknown encoders fall back per platform", () => {
  assert.equal(normalizedEncoder("libx264"), "libx264");
  assert.equal(normalizedEncoder("nope", "darwin"), "h264_videotoolbox");
  assert.equal(normalizedEncoder("nope", "win32"), "auto");
  assert.equal(normalizedEncoder("h264_nvenc", "win32"), "h264_nvenc");
});

test("Windows hardware encoders build rate-controlled args", () => {
  for (const codec of ["h264_nvenc", "h264_qsv", "h264_amf", "h264_mf"]) {
    const args = videoEncoderArgs({ codec, bitrate: "6M" });
    assert.deepEqual(args.slice(0, 2), ["-c:v", codec]);
    assert.ok(args.includes("6M"));
  }
});

test("resolveEncoder picks the first encoder that really encodes", () => {
  const tried = [];
  const spawnImpl = (_bin, args) => {
    const codec = args[args.indexOf("-c:v") + 1];
    tried.push(codec);
    return { status: codec === "h264_amf" ? 0 : 1 };
  };
  assert.equal(resolveEncoder({ ffmpegPath: "ff-a", platform: "win32", spawnImpl }), "h264_amf");
  assert.deepEqual(tried, ["h264_nvenc", "h264_qsv", "h264_amf"]);
  // memoized: no further probing
  assert.equal(resolveEncoder({ ffmpegPath: "ff-a", platform: "win32", spawnImpl }), "h264_amf");
  assert.equal(tried.length, 3);
});

test("resolveEncoder falls back to h264_mf on Windows when nothing probes", () => {
  const spawnImpl = () => ({ status: 1 });
  assert.equal(resolveEncoder({ ffmpegPath: "ff-b", platform: "win32", spawnImpl }), "h264_mf");
});
