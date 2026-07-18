#!/usr/bin/env bash
# Read-only verification for the Hermes adapter.
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SKILLS_DEST="$HERMES_HOME/skills/agentic-workflow"
commands=(nerve agentic-init agentic-start task-work epic-loop engage)
failures=0

model_default() {
  awk '
    /^model:/ { inside = 1; next }
    inside && /^[^[:space:]]/ { exit }
    inside && /^  default:/ { sub(/^  default:[[:space:]]*/, ""); print; exit }
  ' "$HERMES_HOME/config.yaml"
}

command -v hermes >/dev/null 2>&1 || { echo "FAIL Hermes CLI missing"; exit 1; }

if [ "$(model_default)" = "gpt-5.6-terra" ]; then
  echo "PASS default model is gpt-5.6-terra"
else
  echo "FAIL default model is not gpt-5.6-terra"
  failures=$((failures + 1))
fi

for command in "${commands[@]}"; do
  if [ -s "$SKILLS_DEST/$command/SKILL.md" ]; then
    echo "PASS /$command skill installed"
  else
    echo "FAIL /$command skill missing"
    failures=$((failures + 1))
  fi
done

if [ -s "$SKILLS_DEST/nerve/references/nerve-runbook.md" ]; then
  echo "PASS local /nerve runbook reference installed"
else
  echo "FAIL local /nerve runbook reference missing"
  failures=$((failures + 1))
fi

if [ -f "$HOME/.agentic-workflows/nerve-runbook.md" ]; then
  echo "PASS canonical nerve runbook present"
else
  echo "WARN canonical nerve runbook missing; /nerve uses its local reference"
fi

exit "$failures"
