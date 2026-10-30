#!/usr/bin/env bash
# PreToolUse (Edit|Write): aus vereine-web/design erzeugte Dateien nie hier von Hand ändern.
# Liest nur tool_input.file_path aus dem Hook-JSON (ohne jq: auf dem Server nicht installiert).
file="$(sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

if [ -n "$file" ] && "$root/tools/check-design.sh" --generated "$file"; then
  echo "Erzeugte Datei, nicht von Hand ändern. Quelle: vereine-web/design (tokens.json, base.css, icons.json) und vereine-web/.claude/skills/vereine-design. Dort ändern, dann in vereine-web \`npm run design\`." >&2
  exit 2
fi
exit 0
