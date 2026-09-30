/**
 * PATH entry for git. Read-only invocations exec the real binary.
 * Mutating invocations print a reason and exit without running git.
 */
import { spawnSync } from "node:child_process";
import { readFileSync, statSync } from "node:fs";
import { classifyGitArgv, type ClassifyContext } from "./classify.ts";

const realGit = process.env.PI_READONLY_GIT_REAL;
if (!realGit) {
	console.error("Blocked git command that would modify the repository: readonly git wrapper is not configured.");
	process.exit(127);
}

const cwd = process.cwd();
const context: ClassifyContext = {
	cwd,
	readFile(path) {
		try {
			const info = statSync(path);
			if (!info.isFile() || info.size > 512 * 1024) return undefined;
			return readFileSync(path, "utf8");
		} catch {
			return undefined;
		}
	},
	runGit(args) {
		const result = spawnSync(realGit, args, {
			cwd,
			encoding: "utf8",
			stdio: ["ignore", "pipe", "pipe"],
		});
		return { status: result.status, stdout: String(result.stdout ?? "") };
	},
};

const verdict = classifyGitArgv(process.argv.slice(2), context);
if (!verdict.ok) {
	console.error(verdict.reason);
	process.exit(1);
}

const result = spawnSync(realGit, process.argv.slice(2), { stdio: "inherit" });
if (result.error) {
	console.error(result.error.message);
	process.exit(127);
}
if (result.signal) {
	process.kill(process.pid, result.signal);
}
process.exit(result.status ?? 1);
