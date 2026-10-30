# CLAUDE.md: vereine-app

App von Vereineapp für Android und iOS: .NET MAUI Blazor Hybrid auf Basis von Shiny, NativeAOT. Sie entlastet das Ehrenamt in Vereinen, zuerst für Fußballvereine. Die Fachlichkeit folgt; bis dahin ist die Oberfläche ein Platzhalter.

Die Workspace-Regeln aus `/srv/business/vereineapp/CLAUDE.md` gelten (Secrets, öffentliches Repo, Orleans im Backend, keine Abwärtskompatibilität, Nutzertexte).

## Kommandos

```bash
source /srv/business/vereineapp/dev/env.sh          # RC-SDK aus dev/tools/dotnet, nie ~/.dotnet (gehört Orderlyze)
dotnet tool restore                                 # lokale Werkzeuge aus .config/dotnet-tools.json (maui, maui devflow)
dotnet build src/Vereine.App -f net11.0-android     # Debug-Build mit Mono, Warnungen sind Fehler, Output unter artifacts/
dotnet publish src/Vereine.App -f net11.0-android -c Release   # NativeAOT, signiertes AAB/APK unter artifacts/publish
dotnet publish src/Vereine.App -f net11.0-ios -c Release -r ios-arm64   # nur auf macOS mit Xcode
```

Vor jedem Commit: Debug-Build ohne Warnungen. Bei Änderungen an Paketen, Startcode, Razor-Routing oder Reflection zusätzlich den NativeAOT-Publish; nur er zeigt Trim- und AOT-Probleme vollständig.

## Aufbau

- `src/Vereine.App` ist das einzige Projekt: MAUI-Kopf, Razor-Komponenten und Infrastruktur.
- `App.CreateWindow` öffnet direkt `MainPage` mit der `BlazorWebView`. Kein MAUI Shell, keine XAML-Seiten: Navigation macht der Blazor-Router (`Components/Routes.razor`), Seiten liegen in `Components/Pages` mit `@page`.
- `MauiProgram` richtet Shiny (`UseShiny`), Shiny Mediator (`AddShinyMediator` mit `UseBlazor`) und die Konfiguration ein (`appsettings.json` plus `appsettings.android.json`/`appsettings.apple.json` als MauiAsset).
- Backend-Zugriff läuft über Shiny Mediator HTTP. Contracts werden aus der OpenAPI-Beschreibung von vereine-api generiert, sobald es Endpunkte gibt (README, Abschnitt API-Anbindung). Basis-URLs stehen unter `Mediator:Http` in den appsettings, Kopfzeilen setzt `Infrastructure/AppHttpRequestDecorator`.
- Farben und Hell/Dunkel als CSS-Variablen in `wwwroot/css/app.css`; Komponenten-CSS als `*.razor.css`.

## Harte Regeln

1. **AOT ist Pflicht** (`docs/adr/0002-nativeaot.md`). Android und iOS werden mit NativeAOT veröffentlicht, Trim-, AOT- und Single-File-Analyzer laufen in jedem Build, Warnungen im eigenen Code sind Fehler. Deshalb:
   - Keine Reflection ohne Annotation, kein `Activator.CreateInstance(Type)`, kein `MakeGenericType`, keine `System.Linq.Expressions`-Kompilierung.
   - JSON nur über source-generierte `JsonSerializerContext` (bei Shiny `[ShinyJsonContext]`, siehe Skill `shiny-serialization`/`shiny-mediator`).
   - Kein Paket und keine Middleware mit `RequiresUnreferencedCode`/`RequiresDynamicCode` einbauen (Beispiel: `AddDataAnnotations()` von Shiny Mediator ist deshalb draußen).
   - Neue Fremdpakete nur, wenn der NativeAOT-Publish danach keine neue `IL2104`/`IL3053`-Meldung für sie zeigt. Bestehende Meldungen und ihre Bewertung stehen im ADR.
   - `UnconditionalSuppressMessage` nur mit Begründung im Code und nur, wenn die Ursache außerhalb des eigenen Codes liegt.
2. **Shiny ist die Basis.** Gerätefunktionen, Hintergrundarbeit, Push, Speicher und Kommunikation zuerst mit Shiny lösen, dann erst mit anderen Paketen. Vor dem Schreiben den passenden Skill lesen (unten).
3. **Blazor Hybrid statt XAML.** Oberfläche in Razor; XAML nur für den App-Rahmen (`App.xaml`, `MainPage.xaml`).
4. **Versionen zentral** in `Directory.Packages.props`, SDK in `global.json`. Bei neuer .NET-Vorschau gemeinsam mit vereine-api und dem Workspace heben (`dotnet workload install maui-android` nach SDK-Wechsel).
5. **Konfiguration bleibt im Repo:** Skills, MCP-Server, Agent-Einstellungen und .NET-Werkzeuge liegen hier und werden eingecheckt, nichts auf Benutzer- oder globaler Ebene.
6. **Conventional Commits auf Deutsch.** Keine Secrets, Keystores, Signierprofile oder echten Daten committen (öffentliches Repo).

## Skills

Alle liegen in `.claude/skills` (für Codex über den Symlink `.agents/skills`). Die Shiny-Skills kommen unverändert aus github.com/shinyorg/skills; aktualisieren mit `tools/sync-shiny-skills.sh [ref]`, Stand in `.claude/skills/.shiny-skills-version`. Nie von Hand ändern, eigene Skills daneben anlegen.

| Thema | Skill |
|---|---|
| Hosting, DI, `IPlatform`, Lebenszyklus | `shiny-core`, `shiny-di` |
| Mediator, Handler, Middleware, HTTP-Clients aus OpenAPI | `shiny-mediator` |
| JSON (AOT), Key/Value-Speicher, Reflection ohne Reflection | `shiny-serialization`, `shiny-stores`, `shiny-reflector` |
| Lokalisierung aus .resx | `localizegen` |
| Blazor-Controls | `shiny-controls` |
| Push, lokale Benachrichtigungen | `shiny-push`, `shiny-firebase`, `shiny-notifications` |
| Hintergrundjobs, Sync, Uploads | `shiny-jobs`, `shiny-data-sync`, `shiny-http-transfers` |
| Kalender, Kontakte, Biometrie, Store-Updates | `shiny-calendarstore`, `shiny-contactstore`, `shiny-biometrics`, `shiny-appstore` |
| Lokale Dokumentablage | `shiny-documentdb` |
| App bedienen, Screenshots, Visual Tree, Logs | `maui-devflow-debug` (Einrichtung: `maui-devflow-onboard`) |

Die übrigen Shiny-Skills (Bluetooth, OBD, Gamepad, Wi-Fi …) liegen bereit, sind für eine Vereins-App aber selten relevant.

Für .NET-, MAUI- und Blazor-APIs den Microsoft-Learn-MCP nutzen (`.mcp.json`), nicht raten.

## Tests

Es gibt noch keine Tests. Kommt Logik dazu, die ohne Gerät testbar ist, entsteht ein eigenes Testprojekt unter `tests/`. Tests gezielt per Filter ausführen, volle Läufe nur auf Anweisung des Owners.
