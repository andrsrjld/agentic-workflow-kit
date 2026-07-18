#!/usr/bin/env bash
# Install the kit's Hermes slash-command skills without touching credentials.
set -euo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SKILLS_DEST="$HERMES_HOME/skills/agentic-workflow"

model_default() {
  awk '
    /^model:/ { inside = 1; next }
    inside && /^[^[:space:]]/ { exit }
    inside && /^  default:/ { sub(/^  default:[[:space:]]*/, ""); print; exit }
  ' "$HERMES_HOME/config.yaml"
}

command -v hermes >/dev/null 2>&1 || {
  echo "Hermes CLI was not found on PATH." >&2
  exit 1
}

mkdir -p "$SKILLS_DEST"
for skill_dir in "$KIT_ROOT"/hermes/skills/*; do
  skill_name="$(basename "$skill_dir")"
  mkdir -p "$SKILLS_DEST/$skill_name"
  cp "$skill_dir/SKILL.md" "$SKILLS_DEST/$skill_name/SKILL.md"
done

# Keep the detailed workflow next to /nerve. The command uses this only for
# complex work, avoiding slow probes of a missing global runbook path.
mkdir -p "$SKILLS_DEST/nerve/references"
cp "$KIT_ROOT/agentic-workflows/nerve-runbook.md" \
  "$SKILLS_DEST/nerve/references/nerve-runbook.md"

# Preserve the configured provider and credentials; only select the requested
# default model. Hermes writes config.yaml atomically.
hermes config set model.default gpt-5.6-terra

echo "Installed Hermes agentic commands: /nerve, /agentic-init, /agentic-start, /task-work, /epic-loop, /engage"
echo "Installed local /nerve runbook reference."
echo "Default model: $(model_default)"
echo "Restart Hermes or run /reload-skills in an active session to refresh commands."
