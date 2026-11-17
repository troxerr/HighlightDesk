"use strict";

const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const { spawnSync } = require("node:child_process");
const { normalizedEncoder } = require("./encoder.js");

const DEFAULT_CONFIG_PATH = path.join(os.homedir(), ".highlight-desk.json");
const VALID_PRESETS = new Set(["ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow"]);

const STORAGE_MODES = new Set(["local", "dropbox", "googleDrive"]);

const DEFAULT_CONFIG = {
  reframe: {
    enabled: true,
    width: 1080,
    height: 1920,
    crf: 20,
    preset: "veryfast",
    blur: 20,
    encoder: "h264_videotoolbox",
    bitrate: "8M"
  },
  storage: {
    mode: "local",
    folder: "/Highlight Desk",
    deleteAfterUpload: true,
    keepLocalCopy: false,
    keepRaw: false
  },
  dropbox: {
    enabled: true,
    appKey: "",
    appSecret: "",
    refreshToken: "",
    folder: "/Highlight Desk",
    deleteAfterUpload: true
  },
  googleDrive: {
    enabled: true,
    clientId: "",
    clientSecret: "",
    refreshToken: "",
    folder: "/Highlight Desk"
  }
};

function defaultConfig() {
  return JSON.parse(JSON.stringify(DEFAULT_CONFIG));
}

function resolveConfigPath(env = process.env) {
  return env.HIGHLIGHT_DESK_CONFIG ? path.resolve(env.HIGHLIGHT_DESK_CONFIG) : DEFAULT_CONFIG_PATH;
}

function readConfig({ env = process.env, filePath = resolveConfigPath(env) } = {}) {
  let config = {};
  let error = null;
  try {
    if (fs.existsSync(filePath)) {
      const parsed = JSON.parse(fs.readFileSync(filePath, "utf8"));
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
        throw new Error("Config root must be a JSON object.");
      }
      config = parsed;
    }
  } catch (readError) {
    error = readError.message;
    config = {};
  }
  return { config, path: filePath, error };
}

function clamp(value, fallback, min, max) {
  const number = Number(value);
  if (!Number.isFinite(number)) return fallback;
  return Math.min(max, Math.max(min, number));
}

function evenClamp(value, fallback, min, max) {
  const rounded = Math.round(clamp(value, fallback, min, max));
  const even = rounded % 2 === 0 ? rounded : rounded + 1;
  return Math.min(max, even);
}

function normalizeFolder(value) {
  let folder = String(value || "/Highlight Desk").trim();
  if (!folder.startsWith("/")) folder = "/" + folder;
  folder = folder.replace(/\/+/g, "/").replace(/\/$/, "");
  return folder || "/";
}

function keychainToken(account, env = process.env) {
  if (process.platform !== "darwin") return "";
  if (env.HIGHLIGHT_DESK_KEYCHAIN === "0" || process.env.HIGHLIGHT_DESK_KEYCHAIN === "0") return "";
  try {
    const result = spawnSync("/usr/bin/security", [
      "find-generic-password", "-w",
      "-s", "com.highlightdesk.app.credentials",
      "-a", account
    ], { encoding: "utf8", timeout: 5000 });
    return result.status === 0 ? String(result.stdout || "").trim() : "";
  } catch {
    return "";
  }
}

function envBool(value, fallback) {
  if (value === undefined || value === null || value === "") return fallback;
  return !/^(0|false|no|off)$/i.test(String(value));
}

function reframeSettings(config = {}, env = process.env) {
  const source = config.reframe && typeof config.reframe === "object" ? config.reframe : {};
  return {
    enabled: envBool(env.HIGHLIGHT_DESK_REFRAME, source.enabled !== false),
    width: evenClamp(source.width, 1080, 360, 2160),
    height: evenClamp(source.height, 1920, 640, 3840),
    crf: clamp(source.crf, 20, 16, 30),
    preset: VALID_PRESETS.has(source.preset) ? source.preset : "veryfast",
    blur: Math.round(clamp(source.blur, 20, 5, 60)),
    encoder: normalizedEncoder(source.encoder),
    bitrate: typeof source.bitrate === "string" && /^\d+(?:\.\d+)?[Mk]$/.test(source.bitrate) ? source.bitrate : "8M"
  };
}

function googleDriveSettings(config = {}, env = process.env) {
  const source = config.googleDrive && typeof config.googleDrive === "object" ? config.googleDrive : {};
  const enabled = envBool(env.GOOGLE_ENABLED, source.enabled !== false);
  const accessToken = env.GOOGLE_ACCESS_TOKEN || source.accessToken || "";
  const clientId = env.GOOGLE_CLIENT_ID || source.clientId || "";
  const clientSecret = env.GOOGLE_CLIENT_SECRET || source.clientSecret || "";
  const refreshToken = env.GOOGLE_REFRESH_TOKEN || source.refreshToken || keychainToken("google.refresh", env);
  return {
    enabled,
    configured: enabled && Boolean(accessToken || (clientId && clientSecret && refreshToken)),
    accessToken,
    clientId,
    clientSecret,
    refreshToken,
    folder: normalizeFolder(env.GOOGLE_DRIVE_FOLDER || source.folder || "/Highlight Desk"),
    apiBase: env.GOOGLE_API_BASE || source.apiBase || "",
    uploadBase: env.GOOGLE_UPLOAD_BASE || source.uploadBase || "",
    tokenUrl: env.GOOGLE_TOKEN_URL || source.tokenUrl || ""
  };
}

function storageSettings(config = {}, env = process.env) {
  const source = config.storage && typeof config.storage === "object" ? config.storage : {};
  const dropbox = dropboxSettings(config, env);
  const googleDrive = googleDriveSettings(config, env);
  let requested = String(env.HIGHLIGHT_DESK_STORAGE || source.mode || "").trim();
  if (requested === "google") requested = "googleDrive";
  let mode;
  if (STORAGE_MODES.has(requested)) mode = requested;
  else if (!requested) mode = dropbox.configured ? "dropbox" : googleDrive.configured ? "googleDrive" : "local";
  else mode = "local";

  const folderSource = source.folder
    || (mode === "dropbox" ? dropbox.folder : mode === "googleDrive" ? googleDrive.folder : (dropbox.folder || googleDrive.folder || "/Highlight Desk"));

  return {
    mode,
    configured: mode === "local" || (mode === "dropbox" ? dropbox.configured : googleDrive.configured),
    folder: normalizeFolder(folderSource),
    deleteAfterUpload: envBool(env.HIGHLIGHT_DESK_DELETE_AFTER_UPLOAD, source.deleteAfterUpload !== false),
    keepLocalCopy: envBool(env.HIGHLIGHT_DESK_KEEP_LOCAL, source.keepLocalCopy === true),
    keepRaw: envBool(env.HIGHLIGHT_DESK_KEEP_RAW, source.keepRaw === true),
    invalidMode: requested && !STORAGE_MODES.has(requested) ? requested : null,
    dropbox,
    googleDrive
  };
}

function dropboxSettings(config = {}, env = process.env) {
  const source = config.dropbox && typeof config.dropbox === "object" ? config.dropbox : {};
  const enabled = envBool(env.DROPBOX_ENABLED, source.enabled !== false);
  const accessToken = env.DROPBOX_ACCESS_TOKEN || source.accessToken || "";
  const appKey = env.DROPBOX_APP_KEY || source.appKey || "";
  const appSecret = env.DROPBOX_APP_SECRET || source.appSecret || keychainToken("dropbox.appSecret", env);
  const refreshToken = env.DROPBOX_REFRESH_TOKEN || source.refreshToken || keychainToken("dropbox.refresh", env);
  return {
    enabled,
    configured: enabled && Boolean(accessToken || (appKey && refreshToken)),
    accessToken,
    appKey,
    appSecret,
    refreshToken,
    folder: normalizeFolder(env.DROPBOX_FOLDER || source.folder || "/Highlight Desk"),
    deleteAfterUpload: envBool(env.DROPBOX_DELETE_AFTER_UPLOAD, source.deleteAfterUpload !== false),
    apiBase: env.DROPBOX_API_BASE || source.apiBase || "",
    contentBase: env.DROPBOX_CONTENT_BASE || source.contentBase || "",
    tokenUrl: env.DROPBOX_TOKEN_URL || source.tokenUrl || ""
  };
}

module.exports = {
  DEFAULT_CONFIG_PATH,
  DEFAULT_CONFIG,
  VALID_PRESETS,
  STORAGE_MODES,
  defaultConfig,
  resolveConfigPath,
  readConfig,
  reframeSettings,
  dropboxSettings,
  googleDriveSettings,
  keychainToken,
  storageSettings,
  normalizeFolder,
  envBool
};
