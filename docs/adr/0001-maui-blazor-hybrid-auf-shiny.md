# ADR 0001: MAUI Blazor Hybrid auf Shiny

Status: angenommen, 2026-10-30

## Kontext

Vereineapp braucht eine App für Android und iOS, die Ehrenamtliche ohne Technikwissen sofort verstehen. Daneben entsteht eine Verwaltungswebseite (vereine-web, Astro). Der Owner hat entschieden: .NET MAUI mit Blazor (nicht klassisches XAML wie bei Orderlyze), Shiny als Basis, neueste .NET-11-Vorschau, NativeAOT.

## Entscheidung

- **Blazor Hybrid:** Die Oberfläche ist Razor in einer `BlazorWebView`. `App.CreateWindow` öffnet direkt `MainPage` mit der WebView; Navigation macht der Blazor-Router. Kein MAUI Shell, keine XAML-Seiten, kein MVVM-Framework. Gerätefunktionen bleiben nativ über MAUI und Shiny erreichbar.
- **Shiny als Basis:** `Shiny.Hosting.Maui` (`UseShiny`, `IPlatform`, Stores, Lebenszyklus), `Shiny.Mediator` mit `Shiny.Mediator.Maui` und `Shiny.Mediator.Blazor` (Handler, Events an Komponenten, HTTP-Clients aus OpenAPI), `Shiny.Extensions.Configuration` (appsettings als MauiAsset mit Plattform-Datei).
- **Ein Projekt:** `src/Vereine.App`. Ein zusätzlicher `net11.0`-Zielrahmen für Unit-Tests (im Template vorbereitet) entfällt, bis es testbare Logik gibt; dann kommt ein eigenes Testprojekt.
- **Plattformen:** `net11.0-android` überall, `net11.0-ios` nur auf macOS (iOS braucht Xcode).

## Herkunft

Erzeugt am 2026-10-30 mit `dotnet new shinymaui --blazor -m None --ctmvvm false -appid com.codelisk.vereine` aus `Shiny.Templates` 8.0.1 und danach von Hand gezogen:

- Das Template bricht in 8.0.1 beim Erzeugen ab (`Error while processing file .../Platforms/Android/AndroidManifest.xml: Object reference not set to an instance of an object`). Ursache: Bedingungen in den Template-Dateien verwenden Symbole, die `template.json` nicht definiert (`audio` in AndroidManifest.xml, Info.plist und PrivacyInfo.xcprivacy; dazu `appaction`, `screenbrightness`, `virtuallist` u. a.). Für die Erzeugung wurden diese Symbole lokal als `bool` mit Vorgabe `false` ergänzt; am erzeugten Inhalt ändert das nichts. Das Template `shinyblazor` erzeugt dagegen eine Blazor-WebAssembly-App und passt nicht.
- Entfernt: AppShell, MainPage-XAML, ViewModels, CommunityToolkit.Maui/.Mvvm, Bootstrap, Beispiel-Handler, `Linker.xml` mit `preserve="all"` (widerspricht AOT), die Mediator-Middleware `AddDataAnnotations()` (nicht trim-sicher), ungenutzte Berechtigungen (`RECEIVE_BOOT_COMPLETED`, `BATTERY_STATS`), die Platzhalter-Datenschutzangaben im PrivacyInfo.
- Gehoben: net10.0 auf net11.0, MAUI 10 auf 11 RC, Shiny 5.x auf 6.5, Shiny Mediator 6.8 auf 6.12, alle Versionen zentral in `Directory.Packages.props`.

## Folgen

- UI-Bausteine sind Web-Technik (HTML, CSS). Ein Komponentenpaket (z. B. `Shiny.Blazor.Controls`) kommt erst mit der Gestaltung und nur, wenn der NativeAOT-Publish es zulässt.
- Shiny Mediator erzeugt `AddMediatorRegistry()` erst, wenn es Handler gibt. Mit dem ersten Handler wird es in `MauiProgram` ergänzt.
