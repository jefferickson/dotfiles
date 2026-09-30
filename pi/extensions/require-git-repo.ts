/**
 * Run Pi only inside a git work tree.
 * Outside one, complain and stop before any prompt, tool, or command runs.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const MESSAGE = "Pi must be run inside a git repo.";

async function isInsideGitRepo(pi: ExtensionAPI, cwd: string): Promise<boolean> {
	const { stdout, code } = await pi.exec("git", ["rev-parse", "--is-inside-work-tree"], { cwd });
	return code === 0 && stdout.trim() === "true";
}

export default function (pi: ExtensionAPI) {
	let blocked = false;

	pi.on("session_start", async (_event, ctx) => {
		if (await isInsideGitRepo(pi, ctx.cwd)) {
			blocked = false;
			return;
		}

		blocked = true;
		ctx.ui.notify(MESSAGE, "error");
		ctx.shutdown();
		if (ctx.mode !== "tui") {
			console.error(MESSAGE);
			process.exit(1);
		}
	});

	// Interactive shutdown restores the terminal before this event.
	// Exit here so the resume hint is not printed and the process stops.
	pi.on("session_shutdown", (event) => {
		if (!blocked || event.reason !== "quit") return;
		console.error(MESSAGE);
		process.exit(1);
	});

	pi.on("input", () => {
		if (!blocked) return;
		return { action: "handled" as const };
	});

	pi.on("tool_call", () => {
		if (!blocked) return;
		return { block: true, reason: MESSAGE };
	});

	pi.on("user_bash", () => {
		if (!blocked) return;
		return {
			result: {
				output: MESSAGE,
				exitCode: 1,
				cancelled: true,
				truncated: false,
			},
		};
	});

	pi.on("agent_start", (_event, ctx) => {
		if (!blocked) return;
		ctx.abort();
		ctx.shutdown();
	});
}
