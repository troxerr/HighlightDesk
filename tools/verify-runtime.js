#!/usr/bin/env node
"use strict";

// Checks that the FFmpeg and Streamlink on PATH (or in --bin <dir>) are fit to
// ship in the app: FFmpeg must be an LGPL build with no GPL or non-free parts
// and no libx264/libx265, and it must still have an H.264 encoder to use.
//
//   node tools/verify-runtime.js [--bin <dir>]

const path = require("node:path");
const { spawnSync } = require("node:child_process");

const GPL_ENCODERS = ["libx264", "libx264rgb", "libx265", "libxvid"];
const HARDWARE = ["h264_nvenc", "h264_qsv", "h264_amf", "h264_videotoolbox"];
// Software-or-hardware H.264 encoders an LGPL build can legally contain.
const H264_ENCODERS = [...HARDWARE, "h264_mf", "libopenh264"];

function analyzeFfmpeg({ version = "", encoders = "" }) {
  const problems = [];
  const configuration = (version.match(/^configuration:(.*)$/m) || [, ""])[1];
  if (!/^ffmpeg version/m.test(version)) problems.push("Not an FFmpeg build (no version line).");
  if (/--enable-gpl\b/.test(configuration)) problems.push("Built with --enable-gpl, so it is GPL.");
  if (/--enable-nonfree\b/.test(configuration)) problems.push("Built with --enable-nonfree, so it cannot be redistributed.");
  const names = new Set(encoders.split(/\r?\n/).map((line) => (line.match(/^\s*[VAS][.FSXBD]{5}\s+(\S+)/) || [])[1]).filter(Boolean));
  for (const name of GPL_ENCODERS) if (names.has(name)) problems.push(`Contains the GPL encoder ${name}.`);
  const h264 = H264_ENCODERS.filter((name) => names.has(name));
  if (!h264.length) problems.push("Has no H.264 encoder the app can use.");
  return { ok: problems.length === 0, problems, h264, hardware: HARDWARE.filter((name) => names.has(name)) };
}

function run(command, args, bin) {
  const exe = bin ? path.join(bin, command) : command;
  const result = spawnSync(exe, args, { encoding: "utf8", timeout: 30000, windowsHide: true, maxBuffer: 16 * 1024 * 1024 });
  return { status: result.status, stdout: String(result.stdout || ""), error: result.error };
}

function main(argv, out = console) {
  const flag = argv.indexOf("--bin");
  const bin = flag >= 0 ? path.resolve(argv[flag + 1] || ".") : "";
  const ffmpeg = { version: run("ffmpeg", ["-hide_banner", "-version"], bin), encoders: run("ffmpeg", ["-hide_banner", "-encoders"], bin) };
  if (ffmpeg.version.error || ffmpeg.version.status !== 0) {
    out.error("ffmpeg could not be run.");
    return 1;
  }
  const report = analyzeFfmpeg({ version: ffmpeg.version.stdout, encoders: ffmpeg.encoders.stdout });
  const streamlink = run("streamlink", ["--version"], bin);
  const streamlinkOk = !streamlink.error && streamlink.status === 0;
  out.log(JSON.stringify({ ffmpeg: report, streamlink: streamlinkOk ? streamlink.stdout.trim() : null }, null, 2));
  if (!streamlinkOk) out.error("streamlink could not be run.");
  for (const problem of report.problems) out.error(problem);
  return report.ok && streamlinkOk ? 0 : 1;
}

if (require.main === module) process.exit(main(process.argv.slice(2)));

module.exports = { analyzeFfmpeg, main, GPL_ENCODERS };
