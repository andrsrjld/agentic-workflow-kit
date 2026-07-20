/**
 * Nerve Learning Extension — automatic self-learning hooks for Pi.
 *
 * Ports the three Claude Code lifecycle hooks (SessionStart/PostToolUse/Stop
 * in claude/hooks/nerve-*.sh) onto Pi's extension events, so self-learning
 * (retrieve -> judge -> distill -> consolidate) fires automatically every
 * session instead of only when /skill:nerve is explicitly invoked.
 *
 * `pi.exec()` spawns with stdin set to "ignore" (no stdin passthrough), so the
 * sibling .sh scripts take plain CLI args instead of the JSON-on-stdin shape
 * Claude's hooks use — same manifest-driven logic, different calling
 * convention. Every step is best-effort and swallows its own errors: a
 * learning-loop failure must never break a Pi session.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const HERE = dirname(fileURLToPath(import.meta.url));
const WARM_START_SH = join(HERE, "nerve-warm-start.sh");
const CAPTURE_SH = join(HERE, "nerve-capture.sh");
const CONSOLIDATE_SH = join(HERE, "nerve-consolidate.sh");

export default function (pi: ExtensionAPI) {
	// RETRIEVE — warm-start once per fresh session (not on reload/resume/fork,
	// which would just re-inject the same recall into an already-warm context).
	pi.on("session_start", async (event) => {
		try {
			if (event.reason !== "startup") return;
			const { stdout, code } = await pi.exec("bash", [WARM_START_SH], { timeout: 6000 });
			if (code !== 0 || !stdout.trim()) return;
			pi.sendMessage(
				{ customType: "nerve-warm-start", content: stdout.trim(), display: true },
				{ deliverAs: "nextTurn" },
			);
		} catch {
			// Never let a learning-loop failure break session start.
		}
	});

	// CAPTURE (incremental) — one background spike per edit/write attempt.
	pi.on("tool_execution_start", (event) => {
		try {
			if (event.toolName !== "edit" && event.toolName !== "write") return;
			const path = (event.args as { path?: string } | undefined)?.path;
			if (!path) return;
			// Fire-and-forget: never await, never block the tool pipeline.
			void pi.exec("bash", [CAPTURE_SH, path, event.toolName], { timeout: 6000 }).catch(() => {});
		} catch {
			// Same graceful-degradation contract as claude/hooks/nerve-capture.sh.
		}
	});

	// DISTILL + CONSOLIDATE — once per session end.
	pi.on("session_shutdown", async (_event, ctx) => {
		try {
			const sessionId = ctx.sessionManager.getSessionFile() ?? "";
			const args = sessionId ? [CONSOLIDATE_SH, sessionId] : [CONSOLIDATE_SH];
			await pi.exec("bash", args, { timeout: 9000 }).catch(() => {});
		} catch {
			// A session must always be allowed to end cleanly.
		}
	});
}
