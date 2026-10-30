# vereine-app

App von Vereineapp für Android und iOS. Sie entlastet das Ehrenamt in Vereinen, zuerst für Fußballvereine. Gebaut mit .NET MAUI Blazor Hybrid auf [Shiny](https://shinylib.net), veröffentlicht mit NativeAOT.

Weitere Teile: `vereine-api` (Backend, .NET 11 und Microsoft Orleans) und `vereine-web` (Verwaltungswebseite, Astro).

## Stack

| Bereich | Wahl |
|---|---|
| Laufzeit | .NET 11 (neueste Vorschau, siehe `global.json`), C# `preview` |
| App | .NET MAUI 11, Blazor Hybrid (`BlazorWebView`) |
| Basis | Shiny Hosting, Shiny Mediator (MAUI und Blazor), Shiny Configuration |
| Veröffentlichung | NativeAOT, volles Trimmen (`docs/adr/0002-nativeaot.md`) |
| Plattformen | Android (ab 8.0, API 26), iOS (ab 15) |

## Voraussetzungen

- .NET-SDK aus `global.json` mit Workload `maui-android` (und `maui-ios` auf macOS). Auf dem Vereineapp-Server: `source /srv/business/vereineapp/dev/env.sh`.
- Android-SDK (`ANDROID_HOME`) und JDK 17.
- iOS nur auf macOS mit passendem Xcode.

## Kommandos

```bash
dotnet tool restore                                               # lokale Werkzeuge (maui CLI mit DevFlow)
dotnet build src/Vereine.App -f net11.0-android                   # Debug-Build
dotnet build src/Vereine.App -f net11.0-android -t:Run            # auf Emulator oder Gerät starten
dotnet publish src/Vereine.App -f net11.0-android -c Release      # NativeAOT, AAB und APK unter artifacts/publish
dotnet publish src/Vereine.App -f net11.0-ios -c Release -r ios-arm64   # macOS
```

Build-Ausgaben liegen unter `artifacts/` (`UseArtifactsOutput`). Warnungen sind Fehler.

## Aufbau

```
src/Vereine.App/
  MauiProgram.cs            Shiny, Mediator, BlazorWebView, Konfiguration, DevFlow (nur Debug)
  App.xaml(.cs)             App-Rahmen, öffnet MainPage
  MainPage.xaml(.cs)        Seite mit der BlazorWebView
  Components/               Router, Layout, Seiten (Razor)
  Infrastructure/           Querschnitt, z. B. Kopfzeilen für HTTP-Aufrufe
  Platforms/Android|iOS/    Plattformeinstieg, Manifest, Info.plist, Privacy-Manifest
  Resources/                App-Icon und Splash
  wwwroot/                  index.html und CSS (Farben, Hell/Dunkel)
  appsettings*.json         Konfiguration (gemeinsam plus Android bzw. Apple)
docs/adr/                   Architekturentscheidungen
tools/                      Hilfsskripte (Shiny-Skills aktualisieren)
```

## API-Anbindung

Die App spricht vereine-api über Shiny Mediator HTTP. Contracts und Handler werden aus der OpenAPI-Beschreibung der API generiert, sobald es Endpunkte gibt:

```xml
<!-- src/Vereine.App/Vereine.App.csproj -->
<ItemGroup>
  <MediatorHttp Include="openapi/vereine-api.json"
                Namespace="Vereine.App.Api"
                ContractPostfix="HttpRequest"
                GenerateJsonConverters="true"
                Visible="false" />
</ItemGroup>
```

- Die Beschreibung liefert vereine-api unter `/openapi/v1.json`; als Datei im Repo eingecheckt, damit der Build ohne laufende API geht.
- Registrierung in `MauiProgram`: `.AddGeneratedOpenApiClient()` im `AddShinyMediator`-Aufruf.
- Basis-URL je Namespace unter `Mediator:Http` in `appsettings.json`. Für die Entwicklung: `http://localhost:5610`, im Android-Emulator `http://10.0.2.2:5610`. Unverschlüsseltes HTTP blockiert Android ab API 28; für die lokale Entwicklung braucht es dann eine Debug-Netzwerkkonfiguration oder HTTPS.
- Jeder Aufruf bekommt Kopfzeilen aus `Infrastructure/AppHttpRequestDecorator` (App-Version, Gerät, Sprache, Zeitzone; später das Anmelde-Token).
- Mit `GenerateJsonConverters="true"` erzeugt der Generator auch die JSON-Auflöser. Das ist für NativeAOT nötig, Reflection-JSON gibt es nicht.

## Agenten und Werkzeuge

Alles projektlokal und eingecheckt:

- `.claude/skills/`: Shiny-Skills (unverändert aus [shinyorg/skills](https://github.com/shinyorg/skills), aktualisieren mit `tools/sync-shiny-skills.sh [ref]`) und MAUI-DevFlow-Skills (`dotnet maui devflow skills update --scope project --target claude`). `.agents/skills` verweist für Codex darauf.
- `.config/dotnet-tools.json`: `maui` CLI mit `maui devflow` zum Bedienen der laufenden Debug-App (Visual Tree, Screenshots, Logs, Blazor über CDP).
- `.mcp.json` (Claude) und `.codex/config.toml` (Codex): Microsoft-Learn-Doku, für Claude zusätzlich context7.
- `CLAUDE.md`/`AGENTS.md`: Regeln und Einstieg.
