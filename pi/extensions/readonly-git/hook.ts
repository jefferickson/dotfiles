#!/usr/bin/env node
/**
 * Cursor `beforeShellExecution` hook.
 *
 * With the `cursor` provider (pi-cursor-sdk), the Cursor SDK agent runs its own
 * Shell tool. Those commands never pass through pi's bash tool, so pi's
 * `tool_call` handler cannot see them. This hook applies the same read-only
 * git policy to Cursor's shell commands.
 *
 * Input (stdin): {"command": "...", "cwd": "..."}
 * Output (stdout): {"permission": "allow" | "deny", ...}
 */
import { spawnSync } from "node:child_process";
import { readFileSync, statSync } from "node:fs";
import { classifyShell, type ClassifyContext } from "./classify.ts";

const MAX_SCRIPT_BYTES = 512 * 1024;

function readStdin(): string {
	try {
		return readFileSync(0, "utf8");
	} catch {
		return "";
	}
}

let input: { command?: unknown; cwd?: unknown } = {};
try {
	input = JSON.parse(readStdin() || "{}");
} catch {
	// Malformed input: deny below, the command cannot be verified.
}

const command = typeof input.command === "string" ? input.command : undefined;
const cwd = typeof input.cwd === "string" && input.cwd ? input.cwd : process.cwd();

if (command === undefined) {
	const reason = "Blocked shell command: hook input had no command to verify.";
	console.log(JSON.stringify({ permission: "deny", user_message: reason, agent_message: reason }));
	process.exit(0);
}

const context: ClassifyContext = {
	cwd,
	readFile(path) {
		try {
			const info = statSync(path);
			if (!info.isFile() || info.size > MAX_SCRIPT_BYTES) return undefined;
			return readFileSync(path, "utf8");
		} catch {
			return undefined;
		}
	},
	runGit(args) {
		const result = spawnSync("git", args, { cwd, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
		return { status: result.status, stdout: String(result.stdout ?? "") };
	},
};

const verdict = classifyShell(command, context);
if (verdict.ok) {
	console.log(JSON.stringify({ permission: "allow" }));
} else {
	console.log(JSON.stringify({ permission: "deny", user_message: verdict.reason, agent_message: verdict.reason }));
}
