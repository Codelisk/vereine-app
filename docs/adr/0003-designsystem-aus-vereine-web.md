# ADR 0003: Designsystem kommt aus vereine-web, Prüfung im Build

Status: angenommen, 2026-10-30

## Kontext

App und Verwaltungswebseite sollen gleich aussehen und dieselben Farben, Maße, Icons und Textregeln nutzen, nach
dem Vorbild von Spotify (Encore). Nichts darf hart codiert sein, und Claude soll sich verlässlich daran halten.
Grundsatzentscheidung und Recherche: vereine-web `docs/adr/0001-designsystem.md` und `docs/design/recherche.md`.

Die App ist Blazor Hybrid (ADR 0001): die Oberfläche ist HTML und CSS im WebView, XAML gibt es nur für den
Rahmen. Damit kann sie dasselbe CSS nutzen wie die Webseite. Node gibt es in diesem Repo nicht.

## Entscheidung

- **Quelle bleibt in vereine-web** (`design/`). `npm run design` dort schreibt hierher:
  `wwwroot/css/tokens.css`, `wwwroot/css/base.css`, `wwwroot/icons.svg`, `Components/Design/IconName.cs`,
  `Resources/Styles/Tokens.xaml` (Rahmenfarben für `MainPage`), `Resources/Styles/Tokens.props` (Farbe für
  App-Icon und Splash), `Platforms/Android/Resources/values/colors.xml` und den Skill `.claude/skills/vereine-design`.
  Alle Dateien tragen einen Kopf „Erzeugt aus vereine-web/design …“ und werden eingecheckt, damit dieses Repo
  allein baut.
- **Prüfung im Build:** `tools/check-design.sh` (Bash und awk, rund 0,1 s) läuft vor jedem Build als
  MSBuild-Target und meldet im kanonischen Format `datei(zeile): error VDSnnn: …`, damit `dotnet build` abbricht:
  - VDS001 Farbe als Hex, Farbfunktion oder Farbname,
  - VDS002 Schrift, Radius, Schatten, Ebene oder Dauer ohne `var()`,
  - VDS003 feste Länge in Abstand oder Position,
  - VDS004 Inline-Style oder `<style>` in Razor bzw. HTML,
  - VDS005 unbekanntes Token,
  - dazu feste Farben in XAML, csproj, props und Android-Ressourcen.
  Kein Stylelint: das bräuchte Node und ein `package.json` nur für die Prüfung. Das Skript prüft dieselben Regeln
  für die Dateiarten der App.
- **Icons typisiert:** `<Icon Name="IconName.House" />` (`Components/Design`), das Enum ist erzeugt; ein falscher
  Name ist ein Compilerfehler. Die SVG-Symbole liegen in einem Sprite, kein Icon-Font, keine Reflection, AOT-tauglich.
- **Claude-Hooks** wie in vereine-web: erzeugte Dateien gesperrt, Prüfung nach jedem Edit, Gesamtprüfung vor dem
  Abschluss. Review per Subagent `design-review`, Screenshots über DevFlow (`maui-devflow-debug`).
- `wwwroot/css/app.css` enthält nur App-Eigenes (Fehleranzeige von Blazor, Überscroll-Verhalten), Komponenten-CSS
  in `*.razor.css` nur für die Anordnung.

## Folgen

- Design-Änderungen nie hier, immer in vereine-web, dann beide Repos committen.
- Neue Dateiarten mit Stil (z. B. eigene XAML-Seiten) brauchen eine Regel in `tools/check-design.sh`.
- Auf Windows läuft die Build-Prüfung nicht (Bash); die Hooks und der Server-Build decken das ab.

## Neu bewerten, wenn

- die App Teile ohne WebView bekommt (native Steuerelemente brauchen dann XAML-Ressourcen aus den Tokens),
- `shiny-controls` Bausteine mitbringt, die eigene Stile setzen.
