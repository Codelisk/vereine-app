#!/usr/bin/env bash
# Stop: bevor Claude fertig meldet, muss die ganze Oberfläche das Designsystem einhalten (dieselbe Prüfung wie der
# Build). Läuft nur, wenn Oberflächendateien geändert sind, und blockiert einmal je Antwort (stop_hook_active).
input="$(cat)"
[[ "$input" =~ \"stop_hook_active\"[[:space:]]*:[[:space:]]*true ]] && exit 0
root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$root" || exit 0

git status --porcelain --untracked-files=all 2>/dev/null | cut -c4- |
  grep -qE '\.(css|razor|xaml|html|csproj|props)$|Platforms/Android/Resources/' || exit 0

if ! output="$(tools/check-design.sh 2>&1)"; then
  printf 'Noch nicht fertig: Designsystem verletzt (Skill vereine-design).\n%s\n' "$output" >&2
  exit 2
fi
exit 0
