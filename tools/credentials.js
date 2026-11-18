#!/usr/bin/env node
"use strict";

// Manage secrets in the Windows credential store (DPAPI).
//
//   node tools/credentials.js set google.refresh     # prompts (hidden) or reads stdin
//   node tools/credentials.js has google.refresh     # exit 0 if stored
//   node tools/credentials.js delete google.refresh
//   node tools/credentials.js list                   # names only, never values
//
// There is deliberately no "get": printing a secret is never needed.

const readline = require("node:readline");
const { createCredentialStore } = require("../lib/credentials.js");

function readSecret() {
  if (!process.stdin.isTTY) {
    return new Promise((resolve) => {
      let data = "";
      process.stdin.setEncoding("utf8");
      process.stdin.on("data", (chunk) => { data += chunk; });
      process.stdin.on("end", () => resolve(data.replace(/\r?\n$/, "")));
    });
  }
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout, terminal: true });
    let muted = false;
    const write = rl._writeToOutput;
    rl._writeToOutput = function (text) { if (!muted) write.call(rl, text); };
    rl.question("Secret (hidden): ", (answer) => { muted = false; rl.close(); process.stdout.write("\n"); resolve(answer); });
    muted = true;
  });
}

async function main(argv, store = createCredentialStore({ respectDisableFlag: false })) {
  const [command, account] = argv;
  if (!store.canWrite && command !== "list") {
    console.error(store.backend === "keychain"
      ? "On macOS, use the Highlight Desk app to connect accounts; it saves tokens in Keychain."
      : "This platform has no credential store.");
    return 2;
  }
  switch (command) {
    case "set": {
      if (!account) { console.error("Usage: credentials set <name>"); return 2; }
      store.set(account, await readSecret());
      console.log(`Stored ${account}.`);
      return 0;
    }
    case "has": return account && store.has(account) ? 0 : 1;
    case "delete":
      if (!account) { console.error("Usage: credentials delete <name>"); return 2; }
      console.log(store.delete(account) ? `Deleted ${account}.` : `${account} was not stored.`);
      return 0;
    case "list":
      for (const name of store.list()) console.log(name);
      return 0;
    default:
      console.error("Usage: credentials <set|has|delete|list> [name]");
      return 2;
  }
}

if (require.main === module) {
  main(process.argv.slice(2)).then((code) => process.exit(code), (error) => { console.error(error.message); process.exit(1); });
}

module.exports = { main };
