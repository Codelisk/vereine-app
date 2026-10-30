# ADR 0002: NativeAOT für Android und iOS

Status: angenommen, 2026-10-30

## Kontext

Der Owner hat AOT für App und Backend zur Pflicht gemacht. Ziele: schneller Start auf günstigen Android-Geräten, kleinere Pakete, keine Überraschungen durch Reflection zur Laufzeit. Mit .NET 11 kann MAUI auf Android und iOS mit NativeAOT veröffentlichen. Blazor Hybrid (ADR 0001) ist dabei der heikle Teil: Blazor, das WebView und JSInterop sind in .NET 11 noch nicht vollständig trim- und AOT-annotiert.

## Entscheidung

- `PublishAot=true` und `TrimMode=full` im Projekt, ohne Bedingung auf die Konfiguration (so empfiehlt es die MAUI-Doku: `PublishAot` schaltet Feature-Switches, Debug soll sich wie Release verhalten). `dotnet build` läuft weiter mit Mono und schnellem Deploy, `dotnet publish` erzeugt NativeAOT.
- Trim-, AOT- und Single-File-Analyzer laufen in jedem Build (`Directory.Build.props`), Warnungen sind Fehler. Eigener Code mit Reflection, `MakeGenericType`, Reflection-JSON usw. bricht schon den Debug-Build (geprüft mit einer Probe-Datei: `IL2057`, `IL2026`, `IL3050` als Fehler).
- Die App-Assembly ist `TrimmerRootAssembly`: Der Blazor-Router findet Seiten per Reflection über `[Route]`, Blazor unterstützt das Trimmen der App-Assembly nicht (dotnet/aspnetcore#63951). Alle anderen Assemblies werden voll getrimmt.
- Im Publish meldet die App-Assembly jede Warnung einzeln (`TrimmerSingleWarn=false`), damit nichts Eigenes in einer Sammelmeldung verschwindet.
- Fremde Assemblies melden sich gesammelt (`IL2104` Trim, `IL3053` AOT). Diese und `IL3000` aus dem Blazor-WebView sind im Publish **Warnungen, keine Fehler** (Target `_VereineAotWarnungen` im csproj, greift erst nach dem Kompilieren). Sie stammen aus Blazor selbst, die App kann sie nicht beheben.
- `AddDataAnnotations()` von Shiny Mediator ist nicht trim-sicher (`IL2026`) und bleibt draußen. In `Routes.razor` sind `IL2110`/`IL2111` für `Router.NotFoundPage` mit Begründung unterdrückt: Der Verweis zeigt per `typeof` auf eine Seite der gerooteten App-Assembly.

## Nachweis

`dotnet publish src/Vereine.App -f net11.0-android -c Release` mit SDK 11.0.100-rc.3.26522.148, MAUI 11.0.0-rc.2.26505.5, Android-SDK-Pack 37.2.0-rc.2.84, Laufzeit-IDs `android-arm64` und `android-x64`:

- Ergebnis am 2026-10-30: erfolgreich, Exit-Code 0, keine Warnung aus der App-Assembly.
- Im APK liegt pro ABI nur `lib/<abi>/libVereine.App.so` (arm64 29,0 MB, x86_64 28,1 MB unkomprimiert), keine Mono-Laufzeit und keine IL-Assemblies.
- Größen: APK 27,5 MB, AAB 29,1 MB (beide ABIs, signiert mit dem Debug-Schlüssel des SDK, solange kein Release-Keystore eingerichtet ist).
- Debug-Build (`dotnet build -f net11.0-android`, Mono): 0 Warnungen, APK 20,2 MB.

### Verbleibende Meldungen

| Meldung | Quelle | Bewertung |
|---|---|---|
| `XA1040` | Android-SDK | NativeAOT auf Android ist in .NET 11 als experimentell markiert. Bewusst in Kauf genommen. |
| `IL2104`/`IL3053` | `Microsoft.AspNetCore.Components`, `.Web`, `.WebView`, `Microsoft.JSInterop` | Reflection-JSON in JSInterop und IPC (`IpcCommon`, `DotNetDispatcher`, `JSRuntime.InvokeAsync`), `MakeGenericType`/`MakeGenericMethod` für Task-Ergebnisse, Property-Injection und Parameter-Setzen der Komponenten. Ob der Blazor-Grundbetrieb unter NativeAOT trägt, zeigt erst der Laufzeittest (unten). Eigene JSInterop-Aufrufe mit eigenen Typen sind das größte Risiko. |
| `IL2104` | `Shiny.Mediator.Blazor` | `BlazorEventCollector.CreateInstance(Type)` ohne `DynamicallyAccessedMembers`. Betrifft das Verteilen von Mediator-Events an Komponenten. |
| `IL3000` | `WebViewManager.StaticWebAssetsLoader` | `Assembly.Location` ist unter NativeAOT leer. Der Loader sucht damit das Entwicklungs-Manifest der statischen Web-Assets neben der Assembly; in der App liegen die Assets im Paket. Im Laufzeittest prüfen, dass CSS und `index.html` laden. |

Die Einzelmeldungen hinter den Sammelmeldungen zeigt ein Publish mit `-p:TrimmerSingleWarn=false`.

### Workaround XA4319

Das Android-SDK 37.2 RC sucht die DGML-Graphen von ILC (Grundlage der R8-Regeln) nur im klassischen obj-Layout. Mit `UseArtifactsOutput` liegen die RID-Builds unter `artifacts/obj/Vereine.App/release_net11.0-android_<rid>/`, der Publish bricht mit `XA4319: No NativeAOT DGML files were provided` ab. Das Target `_VereineNativeAotDgmlImArtefaktLayout` im csproj ergänzt die Pfade. Entfernen, sobald das SDK das Layout kennt.

## Offen

- **Kein Laufzeittest.** Der Publish beweist, dass NativeAOT baut, nicht, dass die App unter NativeAOT startet und Blazor rendert. Erster Test auf einem Emulator oder Gerät vor jeder Veröffentlichung; dabei besonders: Start, Navigation, ein JSInterop-Aufruf, ein Mediator-Event an eine Komponente.
- **iOS** ist nur konfiguriert, nicht gebaut (braucht macOS mit Xcode).
- Eigene JSInterop-Aufrufe nur mit Typen aus einem Quell-generierten `JsonSerializerContext`.

## Neu bewerten, wenn

- eine neue .NET-11-Vorschau oder GA erscheint (Blazor-Annotationen, `XA1040`, `XA4319`),
- ein neues Paket eine neue `IL2104`/`IL3053`-Meldung bringt (dann Paket ablehnen oder hier begründen),
- der erste Laufzeittest unter NativeAOT fehlschlägt. Rückfall wäre Mono mit vollem Trimmen (`PublishAot=false`, `TrimMode=full`), nur mit Entscheidung des Owners.
