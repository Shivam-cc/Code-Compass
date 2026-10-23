#!/usr/bin/env node
import { writeFileSync } from "node:fs";

writeFileSync("installed-skill.json", JSON.stringify(process.argv.slice(2)));
console.error("Installer completed.");
process.exitCode = Number(process.env.CODECOMPASS_INSTALLER_EXIT ?? 0);
