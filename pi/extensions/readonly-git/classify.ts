/**
 * Decide whether a git invocation is read-only.
 * Unknown subcommands are blocked. Aliases are expanded before that decision.
 */
import { isAbsolute, join, normalize } from "node:path";

export type Verdict = { ok: true } | { ok: false; reason: string };

export interface ClassifyContext {
	cwd: string;
	/** Run the real git binary. Used only to read alias definitions. */
	runGit: (args: string[]) => { status: number | null; stdout: string };
	/** Read a literal script file. Undefined means the file could not be read. */
	readFile?: (path: string) => string | undefined;
	depth?: number;
	aliasStack?: string[];
}

interface ShellWord {
	text: string;
	/** True when the word contains an expansion whose result is not known yet. */
	dynamic: boolean;
}

interface TokenizedShell {
	commands: ShellWord[][];
	nested: string[];
	failed: boolean;
}

const OK: Verdict = { ok: true };

const READONLY_COMMANDS = new Set([
	"annotate",
	"archive",
	"blame",
	"bugreport",
	"cat-file",
	"check-attr",
	"check-ignore",
	"check-mailmap",
	"check-ref-format",
	"cherry",
	"column",
	"count-objects",
	"credential",
	"credential-cache",
	"credential-store",
	"describe",
	"diagnose",
	"diff",
	"diff-files",
	"diff-index",
	"diff-tree",
	"difftool",
	"fmt-merge-msg",
	"for-each-ref",
	"format-patch",
	"fsck",
	"fsck-objects",
	"get-tar-commit-id",
	"grep",
	"help",
	"interpret-trailers",
	"log",
	"ls-files",
	"ls-remote",
	"ls-tree",
	"merge-base",
	"name-rev",
	"pack-redundant",
	"patch-id",
	"range-diff",
	"request-pull",
	"rev-list",
	"rev-parse",
	"shortlog",
	"show",
	"show-branch",
	"show-index",
	"show-ref",
	"status",
	"stripspace",
	"upload-archive",
	"upload-pack",
	"var",
	"verify-commit",
	"verify-pack",
	"verify-tag",
	"version",
	"whatchanged",
]);

/** Builtins that always change a repository. Aliases cannot hide these. */
const MUTATING_COMMANDS = new Set([
	"add",
	"am",
	"checkout",
	"checkout-index",
	"cherry-pick",
	"clean",
	"clone",
	"commit",
	"commit-tree",
	"fast-import",
	"fetch",
	"fetch-pack",
	"filter-branch",
	"gc",
	"init",
	"init-db",
	"maintenance",
	"merge",
	"mergetool",
	"mv",
	"prune",
	"prune-packed",
	"pull",
	"push",
	"read-tree",
	"rebase",
	"repack",
	"reset",
	"restore",
	"revert",
	"rm",
	"send-pack",
	"stage",
	"switch",
	"update-index",
	"update-ref",
	"write-tree",
]);

const SHELLS = new Set(["sh", "bash", "dash", "ash", "zsh", "ksh", "fish", "busybox", "toybox"]);

const SHELL_KEYWORDS = new Set([
	"{",
	"}",
	"if",
	"then",
	"else",
	"elif",
	"fi",
	"while",
	"until",
	"for",
	"do",
	"done",
	"in",
	"case",
	"esac",
	"!",
	"[[",
	"]]",
	"time",
]);

const MAX_DEPTH = 20;

export function isGitProgram(command: string): boolean {
	const base = command.split(/[/\\]/).pop() ?? command;
	return base === "git" || base === "git.exe";
}

export function classifyGitArgv(args: string[], ctx: ClassifyContext): Verdict {
	if ((ctx.depth ?? 0) > MAX_DEPTH) {
		return block("git command nested too deeply to verify");
	}
	const split = splitGlobalOptions(args);
	if (split.error) return block(split.error);
	if (!split.subcommand) return OK;

	const rendered = formatGit(args);
	if (split.subcommand.dynamic) {
		return block(`${rendered} (subcommand is not a literal)`);
	}

	const name = split.subcommand.text;
	const commandArgs = split.rest;
	if (READONLY_COMMANDS.has(name)) return OK;

	const conditional = classifyConditional(name, commandArgs);
	if (conditional === "allow") return OK;
	if (conditional === "block" || MUTATING_COMMANDS.has(name)) return block(rendered);

	return resolveAlias(name, commandArgs, split.configs, split.dashC, rendered, ctx);
}

export function classifyShell(command: string, ctx: ClassifyContext): Verdict {
	if ((ctx.depth ?? 0) > MAX_DEPTH) {
		return block("shell command nested too deeply to verify");
	}
	const tokenized = tokenizeShell(command);
	if (tokenized.failed && mentionsGit(command)) {
		return block("shell command mentions git but could not be parsed safely");
	}
	const next: ClassifyContext = { ...ctx, depth: (ctx.depth ?? 0) + 1 };
	for (const nested of tokenized.nested) {
		const verdict = classifyShell(nested, next);
		if (!verdict.ok) return verdict;
	}
	if (tokenized.failed) return OK;
	for (const words of tokenized.commands) {
		const verdict = classifySimpleCommand(words, command, next);
		if (!verdict.ok) return verdict;
	}
	return OK;
}

export function shellScriptFromArgv(command: string, args: string[]): string | undefined {
	if (!SHELLS.has(programBase(command))) return undefined;
	for (let i = 0; i < args.length; i++) {
		const arg = args[i] ?? "";
		if (arg === "--") return undefined;
		if (arg === "-c" || arg === "--command") return args[i + 1] ?? "";
		if (arg.startsWith("-") && !arg.startsWith("--") && arg.includes("c")) return args[i + 1] ?? "";
		if (!arg.startsWith("-")) return undefined;
	}
	return undefined;
}

export function blockReasonForInvocation(command: string, args: string[], ctx: ClassifyContext): string | undefined {
	if (isGitProgram(command)) {
		const verdict = classifyGitArgv(args, ctx);
		return verdict.ok ? undefined : verdict.reason;
	}
	const script = shellScriptFromArgv(command, args);
	if (script !== undefined) {
		const verdict = classifyShell(script, ctx);
		return verdict.ok ? undefined : verdict.reason;
	}
	return undefined;
}

function classifySimpleCommand(words: ShellWord[], raw: string, ctx: ClassifyContext): Verdict {
	let index = 0;
	while (index < words.length && isEnvAssignment(words[index]?.text ?? "")) index++;
	while (index < words.length && isSkippedKeyword(words[index])) index++;

	const current = words[index];
	if (!current) return OK;
	if (current.dynamic && (current.text === "" || mentionsGit(current.text) || isGitProgram(current.text))) {
		return block("dynamic command name could not be verified as read-only git");
	}
	if (current.dynamic) return OK;

	const base = programBase(current.text);
	if (base === "sudo") return classifySimpleCommand(skipSudo(words.slice(index)), raw, ctx);
	if (base === "env") return classifySimpleCommand(skipEnv(words.slice(index)), raw, ctx);
	if (base === "command" || base === "exec" || base === "nohup" || base === "setsid" || base === "chronic") {
		return classifySimpleCommand(skipSimpleWrapper(words.slice(index), base), raw, ctx);
	}
	if (base === "nice" || base === "stdbuf" || base === "ionice" || base === "time") {
		return classifySimpleCommand(skipFlagWrapper(words.slice(index)), raw, ctx);
	}
	if (base === "xargs") return classifySimpleCommand(skipXargs(words.slice(index)), raw, ctx);
	if (base === "find") return classifyFind(words.slice(index), ctx);
	if (base === "eval") return classifyEval(words.slice(index + 1), ctx);
	if (base === "source" || current.text === ".") return classifySource(words.slice(index + 1), ctx);
	if (SHELLS.has(base)) return classifyShellInvocation(words.slice(index), ctx);
	if (!isGitProgram(current.text)) {
		if (looksLikeScript(current.text)) {
			const verdict = classifyFile(current.text, ctx);
			if (!verdict.ok) return verdict;
		}
		return OK;
	}

	const argv: string[] = [];
	for (const word of words.slice(index + 1)) {
		if (word.dynamic && word.text === "") {
			return block(`${formatGit(argv)} (git argument is not a literal)`);
		}
		argv.push(word.text);
	}
	return classifyGitArgv(argv, ctx);
}

function classifyFind(words: ShellWord[], ctx: ClassifyContext): Verdict {
	for (let i = 1; i < words.length; i++) {
		const flag = words[i]?.text;
		if (flag !== "-exec" && flag !== "-execdir" && flag !== "-ok" && flag !== "-okdir") continue;
		const command: ShellWord[] = [];
		i++;
		while (i < words.length && words[i]?.text !== ";" && words[i]?.text !== "+" && words[i]?.text !== "\\;") {
			const word = words[i];
			if (word) command.push(word);
			i++;
		}
		const verdict = classifySimpleCommand(command, command.map((word) => word.text).join(" "), ctx);
		if (!verdict.ok) return verdict;
	}
	return OK;
}

function classifyEval(words: ShellWord[], ctx: ClassifyContext): Verdict {
	if (words.some((word) => word.dynamic && word.text === "")) {
		return block("dynamic eval could not be verified as read-only git");
	}
	return classifyShell(words.map((word) => word.text).join(" "), ctx);
}

function looksLikeScript(command: string): boolean {
	return command.includes("/") || command.endsWith(".sh");
}

function classifyFile(path: string, ctx: ClassifyContext): Verdict {
	if (!ctx.readFile) return OK;
	const contents = ctx.readFile(resolveAgainst(ctx.cwd, path));
	if (contents === undefined || !mentionsGit(contents)) return OK;
	return classifyShell(contents, { ...ctx, depth: (ctx.depth ?? 0) + 1 });
}

function classifySource(words: ShellWord[], ctx: ClassifyContext): Verdict {
	const target = words[0];
	if (!target || target.dynamic || !ctx.readFile) {
		if (target?.dynamic && (target.text === "" || mentionsGit(target.text))) {
			return block("dynamic source could not be verified as read-only git");
		}
		return OK;
	}
	const contents = ctx.readFile(resolveAgainst(ctx.cwd, target.text));
	if (contents === undefined) return OK;
	return classifyShell(contents, ctx);
}

function classifyShellInvocation(words: ShellWord[], ctx: ClassifyContext): Verdict {
	let index = 1;
	while (index < words.length) {
		const arg = words[index];
		if (!arg) break;
		if (arg.dynamic && arg.text === "") return block("dynamic shell invocation could not be verified");
		if (arg.text === "--") {
			index++;
			break;
		}
		if (arg.text === "-c" || arg.text === "--command" || (arg.text.startsWith("-") && !arg.text.startsWith("--") && arg.text.includes("c"))) {
			const script = words[index + 1];
			if (!script) return OK;
			if (script.dynamic && (script.text === "" || mentionsGit(script.text))) {
				return block("dynamic shell script could not be verified as read-only git");
			}
			if (script.dynamic) return OK;
			return classifyShell(script.text, ctx);
		}
		if (arg.text.startsWith("-")) {
			index++;
			continue;
		}
		break;
	}
	const script = words[index];
	if (!script || script.dynamic || !ctx.readFile) return OK;
	const contents = ctx.readFile(resolveAgainst(ctx.cwd, script.text));
	if (contents === undefined) return OK;
	return classifyShell(contents, ctx);
}

function resolveAlias(
	name: string,
	rest: ShellWord[],
	configs: string[],
	dashC: string | undefined,
	rendered: string,
	ctx: ClassifyContext,
): Verdict {
	if (rest.some((word) => word.dynamic && word.text === "")) {
		return block(`${rendered} (git argument is not a literal)`);
	}
	const stack = ctx.aliasStack ?? [];
	if (stack.includes(name)) return block(`git alias ${name} recurses`);

	const prefix = `alias.${name}=`;
	const override = configs.find((entry) => entry.startsWith(prefix));
	let body = override ? override.slice(prefix.length) : undefined;
	if (body === undefined) {
		const args = ["-C", dashC ?? ctx.cwd];
		for (const entry of configs) args.push("-c", entry);
		args.push("config", "--get", `alias.${name}`);
		const result = ctx.runGit(args);
		if (result.status !== 0) {
			return block(`git ${name} is not a known read-only git command`);
		}
		body = result.stdout.replace(/\n$/, "");
	}
	if (!body) return block(`git ${name} is not a known read-only git command`);

	const child: ClassifyContext = {
		...ctx,
		depth: (ctx.depth ?? 0) + 1,
		aliasStack: [...stack, name],
	};
	const extra = rest.map((word) => word.text);
	if (body.startsWith("!")) {
		const script = `${body.slice(1)} ${extra.map(quoteShell).join(" ")}`.trim();
		return classifyShell(script, child);
	}
	const parsed = tokenizeShell(body);
	if (parsed.failed || parsed.nested.length > 0 || parsed.commands.length !== 1) {
		return block(`git alias ${name} could not be verified`);
	}
	const aliasArgs = parsed.commands[0]?.map((word) => word.text) ?? [];
	return classifyGitArgv([...aliasArgs, ...extra], child);
}

function classifyConditional(name: string, args: ShellWord[]): "allow" | "block" | "unknown" {
	switch (name) {
		case "branch":
			return classifyBranch(args);
		case "tag":
			return classifyTag(args);
		case "stash":
			return classifyStash(args);
		case "remote":
			return classifyRemote(args);
		case "config":
			return classifyConfig(args);
		case "reflog":
			return classifyReflog(args);
		case "worktree":
			return classifySubcommand(args, new Set(["list"]));
		case "submodule":
			return classifySubcommand(args, new Set(["status", "summary"]));
		case "notes":
			return classifySubcommand(args, new Set(["list", "show"]));
		case "rerere":
			return classifySubcommand(args, new Set(["status", "diff", "remaining"]));
		case "sparse-checkout":
			return classifySubcommand(args, new Set(["list"]));
		case "bundle":
			return classifySubcommand(args, new Set(["create", "verify", "list-heads"]));
		case "bisect":
			return classifySubcommand(args, new Set(["log", "view", "visualize"]));
		case "commit-graph":
		case "multi-pack-index":
			return classifySubcommand(args, new Set(["verify"]));
		case "apply":
			return classifyApply(args);
		case "hash-object":
			return args.some((word) => word.text === "-w") ? "block" : "allow";
		case "symbolic-ref":
			return classifySymbolicRef(args);
		case "merge-tree":
			return args.some((word) => word.text === "--write-tree") ? "block" : "allow";
		case "replace":
			return classifyReplace(args);
		default:
			return "unknown";
	}
}

function classifyBranch(args: ShellWord[]): "allow" | "block" {
	let listing = false;
	const positionals: string[] = [];
	for (let i = 0; i < args.length; i++) {
		const arg = args[i]?.text ?? "";
		if (arg === "--") {
			positionals.push(...args.slice(i + 1).map((word) => word.text));
			break;
		}
		if (isBranchWriteFlag(arg)) return "block";
		if (arg === "--list" || arg === "-l" || arg.startsWith("--list=")) {
			listing = true;
			continue;
		}
		if (consumesBranchValue(arg)) {
			if (!arg.includes("=") && args[i + 1] && !args[i + 1].text.startsWith("-")) i++;
			continue;
		}
		if (arg.startsWith("--")) continue;
		if (arg.startsWith("-")) {
			const letters = arg.slice(1);
			if (letters.includes("l")) listing = true;
			if (/[^avrliq]/.test(letters)) return "block";
			continue;
		}
		positionals.push(arg);
	}
	if (positionals.length > 0 && !listing) return "block";
	return "allow";
}

function isBranchWriteFlag(arg: string): boolean {
	return (
		arg === "-d" ||
		arg === "-D" ||
		arg === "--delete" ||
		arg === "-m" ||
		arg === "-M" ||
		arg === "--move" ||
		arg === "-c" ||
		arg === "-C" ||
		arg === "--copy" ||
		arg === "-u" ||
		arg === "--unset-upstream" ||
		arg === "--edit-description" ||
		arg === "-f" ||
		arg === "--force" ||
		arg === "--create-reflog" ||
		arg.startsWith("--set-upstream-to") ||
		arg.startsWith("--delete=") ||
		arg.startsWith("--move=") ||
		arg.startsWith("--copy=")
	);
}

function consumesBranchValue(arg: string): boolean {
	const names = ["--contains", "--no-contains", "--merged", "--no-merged", "--points-at", "--format", "--sort", "--color", "--abbrev", "--track"];
	return names.some((name) => arg === name || arg.startsWith(`${name}=`));
}

function classifyTag(args: ShellWord[]): "allow" | "block" {
	let listing = false;
	let verify = false;
	const positionals: string[] = [];
	for (let i = 0; i < args.length; i++) {
		const arg = args[i]?.text ?? "";
		if (arg === "--") {
			positionals.push(...args.slice(i + 1).map((word) => word.text));
			break;
		}
		if (isTagWriteFlag(arg)) return "block";
		if (arg === "-l" || arg === "--list" || arg.startsWith("--list=") || /^-n\d*$/.test(arg)) {
			listing = true;
			continue;
		}
		if (arg === "-v" || arg === "--verify") {
			verify = true;
			continue;
		}
		if (consumesTagValue(arg)) {
			if (!arg.includes("=") && args[i + 1] && !args[i + 1].text.startsWith("-")) i++;
			continue;
		}
		if (arg.startsWith("-")) continue;
		positionals.push(arg);
	}
	if (positionals.length > 0 && !listing && !verify) return "block";
	return "allow";
}

function isTagWriteFlag(arg: string): boolean {
	return (
		arg === "-d" ||
		arg === "--delete" ||
		arg === "-a" ||
		arg === "--annotate" ||
		arg === "-s" ||
		arg === "--sign" ||
		arg === "-u" ||
		arg === "--local-user" ||
		arg === "-f" ||
		arg === "--force" ||
		arg === "-m" ||
		arg === "--message" ||
		arg === "-F" ||
		arg === "--file" ||
		arg === "-e" ||
		arg === "--edit" ||
		arg === "--cleanup" ||
		arg === "--create-reflog" ||
		arg.startsWith("--message=") ||
		arg.startsWith("--file=") ||
		arg.startsWith("--local-user=") ||
		arg.startsWith("--cleanup=")
	);
}

function consumesTagValue(arg: string): boolean {
	const names = ["--contains", "--no-contains", "--merged", "--no-merged", "--points-at", "--format", "--sort", "--color", "--column"];
	return names.some((name) => arg === name || arg.startsWith(`${name}=`));
}

function classifyStash(args: ShellWord[]): "allow" | "block" {
	const sub = args.find((word) => !word.text.startsWith("-"))?.text;
	if (sub === "list" || sub === "show") return "allow";
	return "block";
}

function classifyRemote(args: ShellWord[]): "allow" | "block" {
	const sub = args.map((word) => word.text).find((arg) => arg !== "-v" && arg !== "--verbose" && !arg.startsWith("-"));
	if (!sub || sub === "show" || sub === "get-url") return "allow";
	return "block";
}

function classifyConfig(args: ShellWord[]): "allow" | "block" {
	let mode: "default" | "read" = "default";
	const positionals: string[] = [];
	for (let i = 0; i < args.length; i++) {
		const arg = args[i]?.text ?? "";
		if (arg === "--") {
			positionals.push(...args.slice(i + 1).map((word) => word.text));
			break;
		}
		if (isConfigWriteFlag(arg)) return "block";
		if (arg === "get" || arg === "list" || arg === "--list" || arg === "-l" || arg.startsWith("--get")) {
			mode = "read";
			continue;
		}
		if (arg === "--file" || arg === "-f" || arg === "--blob" || arg === "--type" || arg === "-t" || arg === "--default") {
			i++;
			continue;
		}
		if (
			arg.startsWith("--file=") ||
			arg.startsWith("--blob=") ||
			arg.startsWith("--type=") ||
			arg.startsWith("--default=")
		) {
			continue;
		}
		if (arg.startsWith("-")) continue;
		if (arg === "set" || arg === "unset" || arg === "rename-section" || arg === "remove-section" || arg === "edit") {
			return "block";
		}
		positionals.push(arg);
	}
	if (mode === "read") return "allow";
	if (positionals.length >= 2) return "block";
	return "allow";
}

function isConfigWriteFlag(arg: string): boolean {
	return (
		arg === "--replace-all" ||
		arg === "--add" ||
		arg === "--unset" ||
		arg === "--unset-all" ||
		arg === "--rename-section" ||
		arg === "--remove-section" ||
		arg === "-e" ||
		arg === "--edit"
	);
}

function classifyReflog(args: ShellWord[]): "allow" | "block" {
	const sub = args.find((word) => !word.text.startsWith("-") && word.text !== "--")?.text;
	if (sub === "expire" || sub === "delete") return "block";
	return "allow";
}

function classifySubcommand(args: ShellWord[], readonly: Set<string>): "allow" | "block" {
	const sub = args.find((word) => !word.text.startsWith("-") && word.text !== "--")?.text;
	if (!sub || readonly.has(sub)) return "allow";
	return "block";
}

function classifyApply(args: ShellWord[]): "allow" | "block" {
	const texts = args.map((word) => word.text);
	const readOnly = texts.some((arg) => arg === "--check" || arg === "--stat" || arg === "--summary" || arg === "--numstat");
	const writes = texts.some((arg) => arg === "--index" || arg === "--cached" || arg === "-3" || arg === "--3way");
	if (readOnly && !writes) return "allow";
	return "block";
}

function classifySymbolicRef(args: ShellWord[]): "allow" | "block" {
	const positionals: string[] = [];
	for (const word of args) {
		const arg = word.text;
		if (arg === "-d" || arg === "--delete") return "block";
		if (arg === "-q" || arg === "--quiet" || arg === "--short" || arg === "--recurse" || arg === "--no-recurse") continue;
		if (arg.startsWith("-")) return "block";
		positionals.push(arg);
	}
	return positionals.length <= 1 ? "allow" : "block";
}

function classifyReplace(args: ShellWord[]): "allow" | "block" {
	if (args.some((word) => word.text === "-d" || word.text === "--delete")) return "block";
	const listing = args.some((word) => word.text === "-l" || word.text === "--list");
	const positionals = args.filter((word) => !word.text.startsWith("-"));
	if (positionals.length === 0 || listing) return "allow";
	return "block";
}

interface GlobalSplit {
	configs: string[];
	dashC?: string;
	subcommand?: ShellWord;
	rest: ShellWord[];
	error?: string;
}

function splitGlobalOptions(args: string[]): GlobalSplit {
	const configs: string[] = [];
	let dashC: string | undefined;
	let index = 0;
	while (index < args.length) {
		const arg = args[index] ?? "";
		if (arg === "--") {
			index++;
			break;
		}
		if (!arg.startsWith("-")) break;
		if (isGlobalFlag(arg)) {
			index++;
			continue;
		}
		const attachedC = attachedGlobalArg("-C", arg);
		if (attachedC !== undefined) {
			dashC = attachedC;
			index++;
			continue;
		}
		const attachedConfig = attachedGlobalArg("-c", arg);
		if (attachedConfig !== undefined) {
			configs.push(attachedConfig);
			index++;
			continue;
		}
		const withValue = globalOptionWithValue(arg);
		if (withValue) {
			if (withValue.inline !== undefined) {
				if (withValue.name === "-C") dashC = withValue.inline;
				if (withValue.name === "-c") configs.push(withValue.inline);
				index++;
				continue;
			}
			const value = args[index + 1];
			if (value === undefined) return { configs, rest: [], error: `git option ${arg} is missing a value` };
			if (withValue.name === "-C") dashC = value;
			if (withValue.name === "-c") configs.push(value);
			index += 2;
			continue;
		}
		return { configs, rest: [], error: `unrecognized git option ${arg}` };
	}
	const sub = args[index];
	return {
		configs,
		dashC,
		subcommand: sub === undefined ? undefined : { text: sub, dynamic: false },
		rest: (args.slice(index + 1) ?? []).map((text) => ({ text, dynamic: false })),
	};
}

function isGlobalFlag(arg: string): boolean {
	return (
		arg === "-v" ||
		arg === "--version" ||
		arg === "-h" ||
		arg === "--help" ||
		arg === "-p" ||
		arg === "--paginate" ||
		arg === "-P" ||
		arg === "--no-pager" ||
		arg === "--no-replace-objects" ||
		arg === "--bare" ||
		arg === "--no-optional-locks" ||
		arg === "--literal-pathspecs" ||
		arg === "--glob-pathspecs" ||
		arg === "--noglob-pathspecs" ||
		arg === "--icase-pathspecs" ||
		arg === "--no-lazy-fetch" ||
		arg === "--no-advice" ||
		arg === "--html-path" ||
		arg === "--man-path" ||
		arg === "--info-path"
	);
}

function attachedGlobalArg(flag: "-C" | "-c", arg: string): string | undefined {
	if (arg.startsWith(flag) && arg.length > flag.length) return arg.slice(flag.length);
	return undefined;
}

function globalOptionWithValue(arg: string): { name: string; inline?: string } | undefined {
	const names = ["-C", "-c", "--exec-path", "--list-cmds", "--namespace", "--super-prefix", "--git-dir", "--work-tree", "--attr-source", "--config-env"];
	for (const name of names) {
		if (arg === name) return { name };
		if (arg.startsWith(`${name}=`)) return { name, inline: arg.slice(name.length + 1) };
	}
	return undefined;
}

function tokenizeShell(input: string): TokenizedShell {
	const commands: ShellWord[][] = [];
	const nested: string[] = [];
	let words: ShellWord[] = [];
	let text = "";
	let dynamic = false;
	let inWord = false;
	let failed = false;
	let index = 0;

	const flushWord = () => {
		if (!inWord) return;
		words.push({ text, dynamic });
		text = "";
		dynamic = false;
		inWord = false;
	};
	const flushCommand = () => {
		flushWord();
		if (words.length > 0) commands.push(words);
		words = [];
	};
	const push = (value: string, isDynamic = false) => {
		text += value;
		if (isDynamic) dynamic = true;
		inWord = true;
	};

	while (index < input.length) {
		const start = index;
		const char = input[index] ?? "";
		if (char === "\\") {
			if (input[index + 1] === "\n") {
				index += 2;
				continue;
			}
			if (index + 1 < input.length) {
				push(input[index + 1] ?? "");
				index += 2;
				continue;
			}
		}
		if (char === "'") {
			inWord = true;
			index++;
			while (index < input.length && input[index] !== "'") {
				text += input[index] ?? "";
				index++;
			}
			if (index >= input.length) {
				failed = true;
				break;
			}
			index++;
			continue;
		}
		if (char === '"') {
			inWord = true;
			index++;
			while (index < input.length && input[index] !== '"') {
				if (input[index] === "\\" && index + 1 < input.length) {
					const next = input[index + 1] ?? "";
					if (next !== "\n") text += next;
					index += 2;
					continue;
				}
				if (input[index] === "$" && input[index + 1] === "(") {
					const body = readParenBody(input, index + 1);
					if (!body) {
						failed = true;
						break;
					}
					nested.push(body.body);
					dynamic = true;
					index = body.end;
					continue;
				}
				if (input[index] === "`") {
					const body = readBacktick(input, index);
					if (!body) {
						failed = true;
						break;
					}
					nested.push(body.body);
					dynamic = true;
					index = body.end;
					continue;
				}
				if (input[index] === "$") {
					const expansion = readDollar(input, index);
					push(expansion.text, true);
					index = expansion.end;
					continue;
				}
				text += input[index] ?? "";
				index++;
			}
			if (failed) break;
			if (index >= input.length) {
				failed = true;
				break;
			}
			index++;
			continue;
		}
		if (char === "`") {
			const body = readBacktick(input, index);
			if (!body) {
				failed = true;
				break;
			}
			nested.push(body.body);
			dynamic = true;
			inWord = true;
			index = body.end;
			continue;
		}
		if (char === "$" && input[index + 1] === "(") {
			const body = readParenBody(input, index + 1);
			if (!body) {
				failed = true;
				break;
			}
			nested.push(body.body);
			dynamic = true;
			inWord = true;
			index = body.end;
			continue;
		}
		if (char === "$") {
			const expansion = readDollar(input, index);
			push(expansion.text, true);
			index = expansion.end;
			continue;
		}
		if ((char === "<" || char === ">") && input[index + 1] === "(") {
			const body = readParenBody(input, index + 1);
			if (!body) {
				failed = true;
				break;
			}
			nested.push(body.body);
			index = body.end;
			continue;
		}
		if (char === "(") {
			const body = readParenBody(input, index);
			if (!body) {
				failed = true;
				break;
			}
			nested.push(body.body);
			index = body.end;
			continue;
		}
		if (char === "#" && !inWord) {
			while (index < input.length && input[index] !== "\n") index++;
			continue;
		}
		if (!inWord && input.startsWith("<<<", index)) {
			flushWord();
			index += 3;
			while (input[index] === " " || input[index] === "\t") index++;
			index = readRawWord(input, index);
			continue;
		}
		if (!inWord && char === "<" && input.startsWith("<<", index)) {
			const heredoc = skipHeredoc(input, index);
			if (!heredoc) {
				failed = true;
				break;
			}
			index = heredoc;
			continue;
		}
		if (isRedirect(input, index, inWord, text)) {
			if (inWord && /^\d+$/.test(text)) {
				text = "";
				dynamic = false;
				inWord = false;
			} else {
				flushWord();
			}
			const next = skipRedirect(input, index);
			if (next === index) {
				failed = true;
				break;
			}
			index = next;
			continue;
		}
		if (!inWord && isCommandSeparator(input, index)) {
			flushCommand();
			index = skipSeparator(input, index);
			continue;
		}
		if (char === " " || char === "\t" || char === "\r") {
			flushWord();
			index++;
			continue;
		}
		if (char === "\n") {
			flushCommand();
			index++;
			continue;
		}
		if (char === ")" || char === "}") {
			flushWord();
			index++;
			continue;
		}
		push(char);
		index++;
		if (index === start) {
			failed = true;
			break;
		}
	}
	if (!failed) flushCommand();
	return { commands, nested, failed };
}

function readParenBody(input: string, openIndex: number): { body: string; end: number } | null {
	let index = openIndex + 1;
	let depth = 1;
	let quote: "'" | '"' | null = null;
	const start = index;
	while (index < input.length) {
		const char = input[index] ?? "";
		if (quote === "'") {
			if (char === "'") quote = null;
			index++;
			continue;
		}
		if (quote === '"') {
			if (char === "\\" && index + 1 < input.length) {
				index += 2;
				continue;
			}
			if (char === '"') quote = null;
			index++;
			continue;
		}
		if (char === "\\") {
			index += 2;
			continue;
		}
		if (char === "'" || char === '"') {
			quote = char;
			index++;
			continue;
		}
		if (char === "(") depth++;
		if (char === ")") {
			depth--;
			if (depth === 0) return { body: input.slice(start, index), end: index + 1 };
		}
		index++;
	}
	return null;
}

function readBacktick(input: string, start: number): { body: string; end: number } | null {
	let index = start + 1;
	let body = "";
	while (index < input.length) {
		if (input[index] === "\\" && index + 1 < input.length) {
			body += input[index + 1] ?? "";
			index += 2;
			continue;
		}
		if (input[index] === "`") return { body, end: index + 1 };
		body += input[index] ?? "";
		index++;
	}
	return null;
}

function readDollar(input: string, start: number): { text: string; end: number } {
	if (input[start + 1] === "{") {
		const end = input.indexOf("}", start + 2);
		if (end === -1) return { text: input.slice(start), end: input.length };
		return { text: input.slice(start, end + 1), end: end + 1 };
	}
	let index = start + 1;
	while (index < input.length && /[A-Za-z0-9_]/.test(input[index] ?? "")) index++;
	if (index === start + 1) index = start + 2;
	return { text: input.slice(start, Math.min(index, input.length)), end: Math.min(index, input.length) };
}

function skipHeredoc(input: string, start: number): number | null {
	let index = start + 2;
	const stripTabs = input[index] === "-";
	if (stripTabs) index++;
	while (input[index] === " " || input[index] === "\t") index++;
	let delimiter = "";
	let quoted = false;
	if (input[index] === "'" || input[index] === '"') {
		quoted = true;
		const quote = input[index];
		index++;
		while (index < input.length && input[index] !== quote && input[index] !== "\n") {
			delimiter += input[index] ?? "";
			index++;
		}
		if (input[index] === quote) index++;
	} else {
		while (index < input.length && input[index] !== "\n" && input[index] !== " " && input[index] !== "\t") {
			delimiter += input[index] ?? "";
			index++;
		}
	}
	if (!delimiter) return null;
	while (index < input.length && input[index] !== "\n") index++;
	if (input[index] === "\n") index++;
	while (index <= input.length) {
		const next = input.indexOf("\n", index);
		const line = input.slice(index, next === -1 ? input.length : next);
		const compare = stripTabs ? line.replace(/^\t+/, "") : line;
		if (compare === delimiter) return next === -1 ? input.length : next + 1;
		if (next === -1) return quoted ? input.length : null;
		index = next + 1;
	}
	return null;
}

function isRedirect(input: string, index: number, inWord: boolean, word: string): boolean {
	const char = input[index] ?? "";
	if (char === "<" || char === ">") return true;
	if (!inWord && /[0-9]/.test(char) && (input[index + 1] === "<" || input[index + 1] === ">")) return true;
	if (inWord && /^\d+$/.test(word) && (char === "<" || char === ">")) return true;
	return false;
}

function skipRedirect(input: string, index: number): number {
	if (/[0-9]/.test(input[index] ?? "")) index++;
	if (input.startsWith(">>", index) || input.startsWith("<<", index) || input.startsWith(">&", index) || input.startsWith("<&", index) || input.startsWith("<>", index)) {
		index += 2;
	} else if (input[index] === ">" || input[index] === "<") {
		index++;
		if (input[index] === "|") index++;
	} else {
		return index;
	}
	if (input[index] === "&") index++;
	while (input[index] === " " || input[index] === "\t") index++;
	if (input[index] === "&") return index + 1;
	const target = readRawWord(input, index);
	return target;
}

function readRawWord(input: string, index: number): number {
	while (index < input.length) {
		const char = input[index] ?? "";
		if (char === " " || char === "\t" || char === "\n" || char === "|" || char === "&" || char === ";") break;
		if (char === "'" || char === '"') {
			const quote = char;
			index++;
			while (index < input.length && input[index] !== quote) {
				if (input[index] === "\\" && quote === '"') index++;
				index++;
			}
			index++;
			continue;
		}
		if (char === "\\") {
			index += 2;
			continue;
		}
		index++;
	}
	return index;
}

function isCommandSeparator(input: string, index: number): boolean {
	const two = input.slice(index, index + 2);
	if (two === "&&" || two === "||" || two === "|&") return true;
	const char = input[index];
	return char === "|" || char === ";" || char === "&";
}

function skipSeparator(input: string, index: number): number {
	const two = input.slice(index, index + 2);
	if (two === "&&" || two === "||" || two === "|&") return index + 2;
	return index + 1;
}

function skipSudo(words: ShellWord[]): ShellWord[] {
	let index = 1;
	while (index < words.length && (words[index]?.text.startsWith("-") ?? false)) {
		const flag = words[index]?.text ?? "";
		index++;
		if (flag === "--") break;
		if (["-u", "-g", "-h", "-p", "-C", "-T", "-R", "--user", "--group", "--host", "--prompt", "--chdir", "--role", "--type", "--other-user", "--close-from"].includes(flag)) {
			index++;
		}
	}
	return words.slice(index);
}

function skipEnv(words: ShellWord[]): ShellWord[] {
	let index = 1;
	while (index < words.length) {
		const arg = words[index]?.text ?? "";
		if (arg === "--") {
			index++;
			break;
		}
		if (isEnvAssignment(arg)) {
			index++;
			continue;
		}
		if (arg === "-u" || arg === "--unset") {
			index += 2;
			continue;
		}
		if (arg.startsWith("--unset=") || arg === "-i" || arg === "-0" || arg === "-v" || arg === "--ignore-environment") {
			index++;
			continue;
		}
		if (arg.startsWith("-")) {
			index++;
			continue;
		}
		break;
	}
	return words.slice(index);
}

function skipSimpleWrapper(words: ShellWord[], base: string): ShellWord[] {
	let index = 1;
	if (base === "command") {
		while (index < words.length && ["-p", "-v", "-V", "--"].includes(words[index]?.text ?? "")) index++;
	}
	return words.slice(index);
}

function skipFlagWrapper(words: ShellWord[]): ShellWord[] {
	let index = 1;
	while (index < words.length && (words[index]?.text.startsWith("-") ?? false)) {
		const flag = words[index]?.text ?? "";
		index++;
		if (flag === "-n" || flag === "-c" || flag === "-p" || flag === "-i" || flag === "-o" || flag === "-e") index++;
	}
	return words.slice(index);
}

function skipXargs(words: ShellWord[]): ShellWord[] {
	const valued = new Set(["-I", "-J", "-L", "-n", "-P", "-s", "-E", "-e", "-d", "-a", "--max-chars", "--max-args", "--max-procs", "--delimiter", "--replace", "--eof", "--arg-file", "--max-lines"]);
	let index = 1;
	while (index < words.length) {
		const arg = words[index]?.text ?? "";
		if (arg === "--") {
			index++;
			break;
		}
		if (arg.startsWith("-")) {
			index++;
			if (valued.has(arg)) index++;
			continue;
		}
		break;
	}
	return words.slice(index);
}

function isSkippedKeyword(word: ShellWord | undefined): boolean {
	return !!word && !word.dynamic && SHELL_KEYWORDS.has(word.text);
}

function isEnvAssignment(text: string): boolean {
	return /^[A-Za-z_][A-Za-z0-9_]*=/.test(text);
}

function programBase(command: string): string {
	return command.split(/[/\\]/).pop() ?? command;
}

function mentionsGit(text: string): boolean {
	return /(?:^|[^A-Za-z0-9_.-])(?:[\w./-]*\/)?git(?:\.exe)?(?=$|[^A-Za-z0-9_.-])/i.test(text);
}

function resolveAgainst(cwd: string, path: string): string {
	return normalize(isAbsolute(path) ? path : join(cwd, path));
}

function formatGit(args: string[]): string {
	return ["git", ...args].map(quoteShell).join(" ");
}

function quoteShell(value: string): string {
	if (/^[A-Za-z0-9_./:=@+-]+$/.test(value)) return value;
	return `'${value.replaceAll("'", `'\\''`)}'`;
}

function block(detail: string): Verdict {
	return {
		ok: false,
		reason: `Blocked git command that would modify the repository: ${detail}. Read-only git commands are allowed.`,
	};
}
