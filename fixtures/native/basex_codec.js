#!/usr/bin/env node
const path = require("path");

const pkgDir = process.argv[2];
const mode = process.argv[3];
const value = process.argv[4];
if (!pkgDir || !mode || typeof value !== "string") {
  process.stdout.write("REJECT");
  process.exit(0);
}

const baseXMod = require(path.join(pkgDir, "node_modules", "base-x"));
const baseX = baseXMod.default || baseXMod;
const ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
const b58 = baseX(ALPHABET);

try {
  if (mode === "b58dec") {
    const out = Buffer.from(b58.decode(value)).toString("hex");
    process.stdout.write(out);
  } else if (mode === "b58enc") {
    const out = b58.encode(Buffer.from(value, "hex"));
    process.stdout.write(out);
  } else {
    process.stdout.write("REJECT");
  }
} catch {
  process.stdout.write("REJECT");
}
