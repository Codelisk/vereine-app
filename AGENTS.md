# vereine-app: Einstieg für Codex

MAUI-Blazor-Hybrid-App von Vereineapp (Android, iOS) auf Shiny, NativeAOT. Lies zuerst `CLAUDE.md` vollständig: Kommandos, Aufbau und harte Regeln (AOT-Pflicht, Shiny-Basis, Blazor statt XAML) gelten unverändert. Die Regeln aus `/srv/business/vereineapp/CLAUDE.md` gelten ebenfalls.

```bash
source /srv/business/vereineapp/dev/env.sh
dotnet tool restore
dotnet build src/Vereine.App -f net11.0-android                  # vor jedem Commit, Warnungen sind Fehler
dotnet publish src/Vereine.App -f net11.0-android -c Release     # NativeAOT-Prüfung bei Paket-, Start- oder Routing-Änderungen
```

Oberfläche nur nach dem Designsystem: Skill `.agents/skills/vereine-design/SKILL.md` lesen, bevor Razor, CSS oder Bildschirmtexte entstehen. Farben und Maße nur als Tokens (`var(--…)`), Bausteine aus `wwwroot/css/base.css`, keine Inline-Styles. `tools/check-design.sh` prüft das in jedem Build. Erzeugte Design-Dateien nie hier ändern, Quelle ist vereine-web (`design/`, dort `npm run design`).

Skills liegen in `.agents/skills` (Symlink auf `.claude/skills`): Shiny-Skills für Shiny-Code, `vereine-design` für die Oberfläche, `maui-devflow-*` zum Bedienen und Prüfen der laufenden App. Microsoft-Doku über den MCP-Server in `.codex/config.toml`.
