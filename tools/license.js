#!/usr/bin/env node
"use strict";

const { getSecret } = require("../lib/credentials.js");

const DEFAULT_API_BASE = "https://api.lemonsqueezy.com";

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith("--")) continue;
    const key = arg.slice(2);
    const value = argv[i + 1] && !argv[i + 1].startsWith("--") ? argv[++i] : "";
    args[key] = value;
  }
  return args;
}

function normalize(data, action, expectedProductId = "") {
  const license = data.license_key || {};
  const meta = data.meta || {};
  const instance = data.instance || {};
  const status = String(license.status || "");
  const productId = meta.product_id === undefined || meta.product_id === null ? "" : String(meta.product_id);
  if (expectedProductId && productId && productId !== String(expectedProductId)) {
    throw new Error(`This license belongs to a different product (${productId}).`);
  }
  const ok = action === "activate"
    ? Boolean(data.activated)
    : action === "validate"
      ? Boolean(data.valid)
      : Boolean(data.deactivated);
  const valid = action !== "deactivate" && ok && status === "active";
  return {
    ok,
    valid: Boolean(valid),
    action,
    status,
    instanceId: instance.id || "",
    productId,
    productName: meta.product_name || "",
    customerEmail: meta.customer_email || "",
    expiresAt: license.expires_at || null,
    activationLimit: license.activation_limit || null,
    activationUsage: license.activation_usage || null
  };
}

async function licenseRequest(action, {
  licenseKey,
  instanceName = "",
  instanceId = "",
  productId = "",
  apiBase = DEFAULT_API_BASE,
  fetchImpl = fetch
}) {
  if (!licenseKey) throw new Error("A license key is required.");
  const paths = {
    activate: "/v1/licenses/activate",
    validate: "/v1/licenses/validate",
    deactivate: "/v1/licenses/deactivate"
  };
  if (!paths[action]) throw new Error(`Unknown license action: ${action}`);
  const body = new URLSearchParams({ license_key: licenseKey });
  if (action === "activate") body.set("instance_name", instanceName || "Highlight Desk");
  if (action === "validate" || action === "deactivate") {
    if (!instanceId) throw new Error("An instance ID is required.");
    body.set("instance_id", instanceId);
  }
  const response = await fetchImpl(`${String(apiBase).replace(/\/$/, "")}${paths[action]}`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/x-www-form-urlencoded"
    },
    body,
    signal: AbortSignal.timeout(30000)
  });
  let data = {};
  try {
    data = await response.json();
  } catch {
    data = {};
  }
  if (!response.ok) {
    throw new Error(data.error || data.message || `License service failed (${response.status}).`);
  }
  if (data.error) throw new Error(String(data.error));
  if (action === "activate" && !data.activated) throw new Error("The license key could not be activated.");
  if (action === "validate" && !data.valid) throw new Error("The license is not valid.");
  if (action === "deactivate" && !data.deactivated) throw new Error("The activation could not be removed.");
  return normalize(data, action, productId);
}

// Order: --license-key, LEMON_LICENSE_KEY, then the credential store
// (Windows DPAPI). The store is only read when the first two are empty.
function resolveLicenseKey(args = {}, env = process.env, secret = getSecret) {
  return String(args["license-key"] || env.LEMON_LICENSE_KEY || secret("license.key") || "").trim();
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const action = String(args.action || "validate").trim();
  const licenseKey = resolveLicenseKey(args);
  const instanceName = String(args["instance-name"] || process.env.LEMON_INSTANCE_NAME || "Highlight Desk").trim();
  const instanceId = String(args["instance-id"] || process.env.LEMON_INSTANCE_ID || "").trim();
  const productId = String(args["product-id"] || process.env.LEMON_PRODUCT_ID || "").trim();
  const apiBase = String(args["api-base"] || process.env.LEMON_API_BASE || DEFAULT_API_BASE).trim();
  const result = await licenseRequest(action, { licenseKey, instanceName, instanceId, productId, apiBase });
  process.stdout.write(JSON.stringify(result) + "\n");
}

if (require.main === module) {
  main().catch((error) => {
    process.stdout.write(JSON.stringify({ ok: false, error: error.message }) + "\n");
    process.exitCode = 1;
  });
}

module.exports = {
  DEFAULT_API_BASE,
  parseArgs,
  normalize,
  licenseRequest,
  resolveLicenseKey
};
