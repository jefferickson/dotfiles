/**
 * Load the extension and confirm mutating git never reaches the real binary.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { createRequire } from "node:module";
import extension from "./index.ts";

const require = createRequire(import.meta.url);

const headBefore = spawnSync("/usr/bin/git", ["rev-parse", "HEAD"], { cwd: "/stage", encoding: "utf8" });
assert.equal(headBefore.status, 0);
const head = headBefore.stdout.trim();

const calls: string[] = [];
const handlers = new Map<string, (event: unknown, ctx: unknown) => unknown>();
const pi = {
	on(event: string, handler: (event: unknown, ctx: unknown) => unknown) {
		handlers.set(event, handler);
		return () => handlers.delete(event);
	},
	registerTool() {},
	exec: async (command: string, args: string[] = []) => {
		calls.push(`${command} ${args.join(" ")}`);
		return { stdout: "real-exec", stderr: "", code: 0, killed: false };
	},
};

extension(pi as never);

const ctx = {
	cwd: "/stage",
	hasUI: true,
	ui: { notify() {} },
};

const toolCall = handlers.get("tool_call");
const userBash = handlers.get("user_bash");
assert.ok(toolCall);
assert.ok(userBash);

const blockedTool = await Promise.resolve(toolCall({ toolName: "bash", input: { command: "git commit -m x" } }, ctx));
assert.equal((blockedTool as { block?: boolean }).block, true);

const allowedTool = await Promise.resolve(toolCall({ toolName: "bash", input: { command: "git status -sb && git diff" } }, ctx));
assert.equal(allowedTool, undefined);

const compound = await Promise.resolve(toolCall({ toolName: "bash", input: { command: "git status && git reset --hard" } }, ctx));
assert.equal((compound as { block?: boolean }).block, true);

const echoed = await Promise.resolve(toolCall({ toolName: "bash", input: { command: "echo git commit" } }, ctx));
assert.equal(echoed, undefined);

const userBlocked = await Promise.resolve(userBash({ command: "git reset --hard", cwd: "/stage" }, ctx));
assert.equal((userBlocked as { result: { exitCode: number } }).result.exitCode, 1);

await assert.rejects(() => pi.exec("git", ["commit", "-m", "x"]), /Blocked git command/);
await assert.rejects(() => pi.exec("bash", ["-lc", "git push"]), /Blocked git command/);
const readOnly = await pi.exec("git", ["rev-parse", "--is-inside-work-tree"]);
assert.equal(readOnly.stdout, "real-exec");
assert.deepEqual(calls, ["git rev-parse --is-inside-work-tree"]);

const branch = "pi-readonly-git-should-not-exist";
const created = spawnSync("git", ["branch", branch], { cwd: "/stage", encoding: "utf8" });
assert.notEqual(created.status, 0, `${created.stderr}`);
const listed = spawnSync("/usr/bin/git", ["branch", "--list", branch], { cwd: "/stage", encoding: "utf8" });
assert.equal(listed.stdout.trim(), "");

const status = spawnSync("git", ["status", "-sb"], { cwd: "/stage", encoding: "utf8" });
assert.equal(status.status, 0, `${status.stderr}`);
assert.match(status.stdout, /## /);

const childProcess = require("node:child_process") as typeof import("node:child_process");
const absolute = childProcess.spawnSync("/usr/bin/git", ["branch", branch], { cwd: "/stage", encoding: "utf8" });
assert.notEqual(absolute.status, 0, `${absolute.stderr}`);
const listedAgain = spawnSync("/usr/bin/git", ["branch", "--list", branch], { cwd: "/stage", encoding: "utf8" });
assert.equal(listedAgain.stdout.trim(), "");

const shell = spawnSync("/bin/bash", ["-c", "git branch pi-readonly-git-should-not-exist"], {
	cwd: "/stage",
	encoding: "utf8",
});
assert.notEqual(shell.status, 0);
assert.match(`${shell.stderr}`, /Blocked git command/);

const headAfter = spawnSync("/usr/bin/git", ["rev-parse", "HEAD"], { cwd: "/stage", encoding: "utf8" });
assert.equal(headAfter.stdout.trim(), head);

console.log("readonly-git extension checks passed");
