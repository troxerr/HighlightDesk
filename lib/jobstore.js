"use strict";

const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

function defaultStateDir(env = process.env) {
  if (env.HIGHLIGHT_DESK_STATE) return path.resolve(env.HIGHLIGHT_DESK_STATE);
  return path.join(os.homedir(), "Library", "Application Support", "Highlight Desk");
}

function readJson(file, fallback) {
  try {
    if (!fs.existsSync(file)) return fallback;
    const parsed = JSON.parse(fs.readFileSync(file, "utf8"));
    return parsed && typeof parsed === "object" ? parsed : fallback;
  } catch {
    return fallback;
  }
}

function writeJson(file, value) {
  const directory = path.dirname(file);
  fs.mkdirSync(directory, { recursive: true, mode: 0o700 });
  const draft = `${file}.partial`;
  fs.writeFileSync(draft, JSON.stringify(value, null, 2) + "\n", { mode: 0o600 });
  fs.renameSync(draft, file);
  try { fs.chmodSync(file, 0o600); } catch {}
}

function createJobStore({ stateDir = defaultStateDir(), maxHistory = 500 } = {}) {
  const queueFile = path.join(stateDir, "queue.json");
  const historyFile = path.join(stateDir, "history.json");
  let disabled = false;
  let memoryQueue = [];
  let memoryHistory = [];

  function ensure() {
    if (disabled) return false;
    try {
      fs.mkdirSync(stateDir, { recursive: true, mode: 0o700 });
      return true;
    } catch {
      disabled = true;
      return false;
    }
  }

  function loadQueue() {
    if (!ensure()) return memoryQueue.slice();
    const data = readJson(queueFile, []);
    return Array.isArray(data) ? data : [];
  }

  function saveQueue(queue) {
    memoryQueue = Array.isArray(queue) ? queue.slice() : [];
    if (!ensure()) return;
    try { writeJson(queueFile, memoryQueue); } catch { disabled = true; }
  }

  function loadHistory() {
    if (!ensure()) return memoryHistory.slice();
    const data = readJson(historyFile, []);
    return Array.isArray(data) ? data : [];
  }

  function saveHistory(history) {
    memoryHistory = Array.isArray(history) ? history.slice(0, maxHistory) : [];
    if (!ensure()) return;
    try { writeJson(historyFile, memoryHistory); } catch { disabled = true; }
  }

  function enqueue(item) {
    const queue = loadQueue();
    const index = queue.findIndex((entry) => entry.id === item.id);
    if (index >= 0) queue[index] = { ...queue[index], ...item };
    else queue.push(item);
    saveQueue(queue);
    return item;
  }

  function update(id, patch) {
    const queue = loadQueue();
    const index = queue.findIndex((entry) => entry.id === id);
    if (index < 0) return null;
    queue[index] = { ...queue[index], ...patch, updatedAt: new Date().toISOString() };
    saveQueue(queue);
    return queue[index];
  }

  function remove(id) {
    const queue = loadQueue().filter((entry) => entry.id !== id);
    saveQueue(queue);
  }

  function listQueue() {
    return loadQueue();
  }

  function due(now = Date.now()) {
    return loadQueue().filter((entry) => {
      if (entry.status === "uploading") return false;
      return !entry.nextRetryAt || Date.parse(entry.nextRetryAt) <= now;
    });
  }

  function recover() {
    const queue = loadQueue();
    let changed = false;
    for (const entry of queue) {
      if (entry.status === "uploading") {
        entry.status = "pending";
        entry.updatedAt = new Date().toISOString();
        changed = true;
      }
    }
    if (changed) saveQueue(queue);
    return queue;
  }

  function addHistory(entry) {
    const history = loadHistory();
    const index = history.findIndex((item) => item.id === entry.id);
    if (index >= 0) history[index] = { ...history[index], ...entry };
    else history.unshift(entry);
    saveHistory(history.slice(0, maxHistory));
    return entry;
  }

  function listHistory() {
    return loadHistory();
  }

  function clearHistory() {
    saveHistory([]);
  }

  return {
    stateDir,
    queueFile,
    historyFile,
    get disabled() { return disabled; },
    enqueue,
    update,
    remove,
    listQueue,
    due,
    recover,
    addHistory,
    listHistory,
    clearHistory
  };
}

module.exports = {
  defaultStateDir,
  createJobStore
};
