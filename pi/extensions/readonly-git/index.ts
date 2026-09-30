/**
 * Block git commands that would modify a repository.
 * Read-only git commands such as status, diff, log, and show still run.
 *
 * Shell commands are checked before they start. A PATH shim also checks every
 * later `git` lookup, including git started from scripts.
 *
 * This covers pi's own tools only. With the `cursor` provider (pi-cursor-sdk),
 * the Cursor SDK agent runs its own Shell tool in a separate process, so pi's
 * `tool_call` handler never sees those commands. `hook.ts` plus a Cursor
 * `beforeShellExecution` hook (see ../../cursor/hooks.json) covers that path.
 */
import { spawnSync as nodeSpawnSync } from "node:child_process";
import { createRequire } from "node:module";
import { chmodSync, existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { createBashToolDefinition, type ExecOptions, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { blockReasonForInvocation, classifyShell, type ClassifyContext } from "./classify.ts";

const require = createRequire(fileURLToPath(import.meta.url));
const childProcess = require("node:child_process") as typeof import("node:child_process");

const WRAPPER_DIR = join(tmpdir(), "pi-readonly-git");
const MAX_SCRIPT_BYTES = 512 * 1024;

let realGit = "/usr/bin/git";
let installed = false;
const originalSpawn = childProcess.spawn;
const originalSpawnSync = childProcess.spawnSync;
const originalExec = childProcess.exec;
const originalExecSync = childProcess.execSync;
const originalExecFile = childProcess.execFile;
const originalExecFileSync = childProcess.execFileSync;

export default function (pi: ExtensionAPI) {
	installGuard();

	const originalPiExec = pi.exec.bind(pi);
	pi.exec = (async (command: string, args: string[] = [], options?: ExecOptions) => {
		const reason = blockReasonForInvocation(command, args, makeContext(options?.cwd ?? process.cwd()));
		if (reason) throw new Error(reason);
		return originalPiExec(command, args, options);
	}) as ExtensionAPI["exec"];

	const bashTool = createBashToolDefinition(process.cwd());
	pi.registerTool({
		...bashTool,
		async execute(toolCallId, params, signal, onUpdate, ctx) {
			const verdict = classifyShell(params.command, makeContext(ctx?.cwd ?? process.cwd()));
			if (!verdict.ok) throw new Error(verdict.reason);
			return bashTool.execute(toolCallId, params, signal, onUpdate, ctx);
		},
	});

	pi.on("tool_call", (event, ctx) => {
		const command = commandFromTool(event.toolName, event.input);
		if (command === undefined) return;
		const verdict = classifyShell(command, makeContext(ctx.cwd));
		if (verdict.ok) return;
		if (ctx.hasUI) ctx.ui.notify(verdict.reason, "error");
		return { block: true, reason: verdict.reason };
	});

	pi.on("user_bash", (event, ctx) => {
		const verdict = classifyShell(event.command, makeContext(event.cwd));
		if (verdict.ok) return;
		if (ctx.hasUI) ctx.ui.notify(verdict.reason, "error");
		return {
			result: {
				output: verdict.reason,
				exitCode: 1,
				cancelled: false,
				truncated: false,
			},
		};
	});
}

export function installGuard(): void {
	if (installed) return;
	installed = true;
	realGit = findRealGit();
	installPathShim();
	patchChildProcess();
}

function makeContext(cwd: string): ClassifyContext {
	return {
		cwd,
		readFile: readScript,
		runGit(args) {
			const result = originalSpawnSync(realGit, args, {
				cwd,
				encoding: "utf8",
				stdio: ["ignore", "pipe", "pipe"],
			});
			return { status: result.status, stdout: String(result.stdout ?? "") };
		},
	};
}

function patchChildProcess(): void {
	childProcess.spawn = ((command: string, args?: readonly string[] | object, options?: object) => {
		const parsed = parseSpawnArgs(command, args, options);
		const reason = parsed ? blockReasonForInvocation(parsed.command, parsed.argv, makeContext(parsed.cwd)) : undefined;
		if (reason) {
			return originalSpawn("/bin/sh", ["-c", `printf '%s\\n' ${shellQuote(reason)} >&2; exit 1`], parsed?.options);
		}
		return originalSpawn(command, args as never, options as never);
	}) as typeof childProcess.spawn;

	childProcess.spawnSync = ((command: string, args?: readonly string[] | object, options?: object) => {
		const parsed = parseSpawnArgs(command, args, options);
		const reason = parsed ? blockReasonForInvocation(parsed.command, parsed.argv, makeContext(parsed.cwd)) : undefined;
		if (reason) return blockedSync(reason);
		return originalSpawnSync(command, args as never, options as never);
	}) as typeof childProcess.spawnSync;

	childProcess.execFile = ((file: string, args?: readonly string[] | object, options?: object, callback?: (...values: unknown[]) => void) => {
		const normalized = normalizeExecFile(args, options, callback);
		const reason = blockReasonForInvocation(file, normalized.argv, makeContext(normalized.cwd));
		if (reason) {
			const error = Object.assign(new Error(reason), { code: 1, status: 1 });
			if (normalized.callback) {
				queueMicrotask(() => normalized.callback?.(error, "", reason));
				return originalSpawn("/bin/true", [], { stdio: "ignore" });
			}
			return originalSpawn("/bin/sh", ["-c", `printf '%s\\n' ${shellQuote(reason)} >&2; exit 1`]);
		}
		return originalExecFile(file, normalized.argv, normalized.options as never, normalized.callback as never);
	}) as typeof childProcess.execFile;

	childProcess.execFileSync = ((file: string, args?: readonly string[] | object, options?: object) => {
		const argv = Array.isArray(args) ? args.map(String) : [];
		const optionObject = (Array.isArray(args) ? options : args) as { cwd?: unknown } | undefined;
		const cwd = typeof optionObject?.cwd === "string" ? optionObject.cwd : process.cwd();
		const reason = blockReasonForInvocation(file, argv, makeContext(cwd));
		if (reason) throw Object.assign(new Error(reason), { status: 1, stderr: reason });
		return originalExecFileSync(file, args as never, options as never);
	}) as typeof childProcess.execFileSync;

	childProcess.exec = ((command: string, options?: object | ((...values: unknown[]) => void), callback?: (...values: unknown[]) => void) => {
		const optionObject = typeof options === "function" ? undefined : options;
		const cb = typeof options === "function" ? options : callback;
		const cwd = optionObject && typeof optionObject === "object" && "cwd" in optionObject && typeof optionObject.cwd === "string"
			? optionObject.cwd
			: process.cwd();
		const verdict = classifyShell(String(command), makeContext(cwd));
		if (!verdict.ok) {
			const error = Object.assign(new Error(verdict.reason), { code: 1, status: 1 });
			if (cb) {
				queueMicrotask(() => cb(error, "", verdict.reason));
				return originalSpawn("/bin/true", [], { stdio: "ignore" });
			}
			return originalSpawn("/bin/sh", ["-c", "exit 1"], { stdio: "ignore" });
		}
		return originalExec(command, options as never, callback as never);
	}) as typeof childProcess.exec;

	childProcess.execSync = ((command: string, options?: { cwd?: unknown }) => {
		const cwd = typeof options?.cwd === "string" ? options.cwd : process.cwd();
		const verdict = classifyShell(String(command), makeContext(cwd));
		if (!verdict.ok) throw Object.assign(new Error(verdict.reason), { status: 1, stderr: verdict.reason });
		return originalExecSync(command, options as never);
	}) as typeof childProcess.execSync;
}

function installPathShim(): void {
	mkdirSync(WRAPPER_DIR, { recursive: true });
	const wrapper = fileURLToPath(new URL("./wrapper.mts", import.meta.url));
	const script = `#!/bin/sh
export PI_READONLY_GIT_REAL=${shellQuote(realGit)}
exec ${shellQuote(process.execPath)} --experimental-strip-types ${shellQuote(wrapper)} "$@"
`;
	const path = join(WRAPPER_DIR, "git");
	writeFileSync(path, script, { mode: 0o755 });
	chmodSync(path, 0o755);

	const current = process.env.PATH ?? "";
	const entries = current.split(":").filter(Boolean).filter((entry) => entry !== WRAPPER_DIR);
	process.env.PATH = [WRAPPER_DIR, ...entries].join(":");
}

function findRealGit(): string {
	const dirs = (process.env.PATH ?? "").split(":").filter((dir) => dir && dir !== WRAPPER_DIR);
	for (const dir of dirs) {
		const candidate = join(dir, "git");
		if (existsSync(candidate)) return candidate;
	}
	for (const candidate of ["/usr/bin/git", "/usr/local/bin/git", "/opt/homebrew/bin/git"]) {
		if (existsSync(candidate)) return candidate;
	}
	return "/usr/bin/git";
}

function parseSpawnArgs(
	command: unknown,
	args: unknown,
	options: unknown,
): { command: string; argv: string[]; cwd: string; options: unknown } | undefined {
	if (typeof command !== "string") return undefined;
	const argv = Array.isArray(args) ? args.map(String) : [];
	const optionObject = (Array.isArray(args) ? options : args) as { cwd?: unknown } | undefined;
	const cwd = typeof optionObject?.cwd === "string" ? optionObject.cwd : process.cwd();
	return { command, argv, cwd, options: optionObject };
}

function normalizeExecFile(
	args: unknown,
	options: unknown,
	callback: ((...values: unknown[]) => void) | undefined,
): { argv: string[]; cwd: string; options: unknown; callback?: (...values: unknown[]) => void } {
	if (typeof args === "function") {
		return { argv: [], cwd: process.cwd(), options: undefined, callback: args as (...values: unknown[]) => void };
	}
	const argv = Array.isArray(args) ? args.map(String) : [];
	const optionObject = (Array.isArray(args) ? options : args) as { cwd?: unknown } | undefined;
	const cb = (Array.isArray(args) ? callback : typeof options === "function" ? options : callback) as
		| ((...values: unknown[]) => void)
		| undefined;
	const cwd = typeof optionObject?.cwd === "string" ? optionObject.cwd : process.cwd();
	return { argv, cwd, options: optionObject, callback: cb };
}

function commandFromTool(toolName: string, input: unknown): string | undefined {
	if (toolName !== "bash" && toolName !== "powershell") return undefined;
	if (!input || typeof input !== "object" || !("command" in input)) return undefined;
	const command = (input as { command?: unknown }).command;
	return typeof command === "string" ? command : undefined;
}

function readScript(path: string): string | undefined {
	try {
		const info = statSync(path);
		if (!info.isFile() || info.size > MAX_SCRIPT_BYTES) return undefined;
		return readFileSync(path, "utf8");
	} catch {
		return undefined;
	}
}

function blockedSync(reason: string): ReturnType<typeof nodeSpawnSync> {
	const stderr = `${reason}\n`;
	return {
		pid: 0,
		output: [null, "", stderr],
		stdout: "",
		stderr,
		status: 1,
		signal: null,
	};
}

function shellQuote(value: string): string {
	return `'${value.replaceAll("'", `'\\''`)}'`;
}
