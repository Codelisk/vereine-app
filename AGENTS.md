# vereine-app: Einstieg für Codex

MAUI-Blazor-Hybrid-App von Vereineapp (Android, iOS) auf Shiny, NativeAOT. Lies zuerst `CLAUDE.md` vollständig: Kommandos, Aufbau und harte Regeln (AOT-Pflicht, Shiny-Basis, Blazor statt XAML) gelten unverändert. Die Regeln aus `/srv/business/vereineapp/CLAUDE.md` gelten ebenfalls.

```bash
source /srv/business/vereineapp/dev/env.sh
dotnet tool restore
dotnet build src/Vereine.App -f net11.0-android                  # vor jedem Commit, Warnungen sind Fehler
dotnet publish src/Vereine.App -f net11.0-android -c Release     # NativeAOT-Prüfung bei Paket-, Start- oder Routing-Änderungen
```

Skills liegen in `.agents/skills` (Symlink auf `.claude/skills`): Shiny-Skills für Shiny-Code, `maui-devflow-*` zum Bedienen und Prüfen der laufenden App. Microsoft-Doku über den MCP-Server in `.codex/config.toml`.
