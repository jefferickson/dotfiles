import assert from "node:assert/strict";
import { test } from "node:test";
import { classifyGitArgv, classifyShell, type ClassifyContext } from "./classify.ts";

function context(runGit?: ClassifyContext["runGit"], readFile?: ClassifyContext["readFile"]): ClassifyContext {
	return {
		cwd: "/stage",
		runGit: runGit ?? (() => ({ status: 1, stdout: "" })),
		readFile,
	};
}

function assertAllowed(command: string, runGit?: ClassifyContext["runGit"]): void {
	const verdict = classifyShell(command, context(runGit));
	assert.equal(verdict.ok, true, verdict.ok ? "" : verdict.reason);
}

function assertBlocked(command: string, runGit?: ClassifyContext["runGit"]): void {
	const verdict = classifyShell(command, context(runGit));
	assert.equal(verdict.ok, false, command);
	if (!verdict.ok) assert.match(verdict.reason, /Blocked git command/);
}

const allowed = [
	"git status",
	"git status -sb",
	"git diff HEAD",
	"git log -n 5 --oneline",
	"git show HEAD:file",
	"git rev-parse --is-inside-work-tree",
	"git -C /tmp status",
	"git --no-pager log",
	"git -c color.ui=false status",
	"git --git-dir=/tmp/repo status",
	"/usr/bin/git status",
	"git status && git diff",
	"git log | head",
	"GIT_DIR=/tmp/repo git status",
	"sudo git status",
	"command git status",
	"env git status",
	"nice -n 5 git status",
	"echo git commit",
	"echo 'git commit'",
	"git status # git commit",
	"bash -lc 'git status'",
	"git branch",
	"git branch -vv",
	"git branch --show-current",
	"git branch --list 'feat/*'",
	"git tag",
	"git tag -l 'v*'",
	"git tag -v v1.0",
	"git stash list",
	"git stash show -p",
	"git remote -v",
	"git remote get-url origin",
	"git remote show origin",
	"git config --get user.name",
	"git config user.name",
	"git config --global --list",
	"git reflog -5",
	"git symbolic-ref --short HEAD",
	"git apply --check patch",
	"git hash-object file",
	"git --version",
	"git help status",
	"echo $(git status)",
	"xargs git status",
	"find . -exec git status \\;",
	"cat <<EOF\ngit commit\nEOF",
	"git status >/tmp/out",
	"git status 2>&1",
	"git difftool HEAD~1",
	"git worktree list",
	"git submodule status",
	"git notes list",
	"git bundle verify pack.bundle",
	"git bisect log",
	"git commit-graph verify",
	"git replace -l",
	"git merge-tree A B",
];

const blocked = [
	"git commit",
	"git commit -m 'x'",
	"git reset --hard",
	"git add .",
	"git checkout -- .",
	"git switch main",
	"git push",
	"git pull",
	"git fetch",
	"git clean -fd",
	"git clean -n",
	"git init",
	"git clone url",
	"git rebase HEAD~3",
	"git merge main",
	"git stash",
	"git stash pop",
	"git branch foo",
	"git branch -d foo",
	"git tag v1",
	"git tag -d v1",
	"git config user.name x",
	"git config --unset user.name",
	"git reset --hard && echo ok",
	"git status && git commit",
	"bash -lc 'git reset --hard'",
	"sudo git commit",
	"/usr/bin/git reset --hard",
	"echo $(git commit -m x)",
	'git commit -m "hello && git status"',
	"command git commit",
	"env git commit",
	"xargs -n 1 git commit",
	"find . -exec git commit \\;",
	"git apply patch",
	"git hash-object -w file",
	"git symbolic-ref HEAD refs/heads/main",
	"git update-ref HEAD HEAD",
	"git gc",
	"git restore --staged .",
	"git worktree add ../other",
	"git submodule update",
	"git remote add origin url",
	"git reflog expire --all",
	"git bundle unbundle pack.bundle",
	"git bisect start",
	"git commit-graph write",
	"git replace abc def",
	"git merge-tree --write-tree A B",
	"git --foo status",
	"(git commit)",
	"if git status; then git commit; fi",
];

for (const command of allowed) {
	test(`allows ${command}`, () => {
		assertAllowed(command);
	});
}

for (const command of blocked) {
	test(`blocks ${command}`, () => {
		assertBlocked(command);
	});
}

test("does not consult git when blocking commit", () => {
	assertBlocked("git commit", () => {
		throw new Error("alias lookup should not run");
	});
});

test("expands a read-only alias", () => {
	assertAllowed("git st", (args) => {
		assert.ok(args.includes("alias.st"));
		return { status: 0, stdout: "status -sb\n" };
	});
});

test("expands a mutating alias", () => {
	assertBlocked("git cm", () => ({ status: 0, stdout: "commit -m hi\n" }));
});

test("honors a one-shot alias override", () => {
	assertBlocked("git -c alias.st=commit st", () => {
		throw new Error("config lookup should not run");
	});
});

test("blocks an unknown subcommand", () => {
	const verdict = classifyGitArgv(["not-a-real-command"], context());
	assert.equal(verdict.ok, false);
});

test("reads a sourced script", () => {
	const verdict = classifyShell("source deploy.sh", context(undefined, (path) => {
		assert.equal(path, "/stage/deploy.sh");
		return "git reset --hard\n";
	}));
	assert.equal(verdict.ok, false);
});

test("allows a sourced read-only script", () => {
	const verdict = classifyShell("bash deploy.sh", context(undefined, () => "git status\n"));
	assert.equal(verdict.ok, true);
});

test("blocks a script that runs git commit", () => {
	const verdict = classifyShell("./deploy.sh", context(undefined, (path) => {
		assert.equal(path, "/stage/deploy.sh");
		return "#!/bin/sh\ngit commit -m x\n";
	}));
	assert.equal(verdict.ok, false);
});
