#!/usr/bin/env bash
# PostToolUse (Edit|Write): prüft die eben geschriebene Datei gegen das Designsystem (tools/check-design.sh) und
# meldet Verstöße an Claude (Exit 2, Text auf stderr).
file="$(sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
[ -n "$file" ] || exit 0

if ! output="$("$root/tools/check-design.sh" "$file" 2>&1)"; then
  printf 'Designsystem verletzt (Skill vereine-design). Jetzt beheben, nur Tokens aus tokens.md verwenden:\n%s\n' "$output" >&2
  exit 2
fi
exit 0
