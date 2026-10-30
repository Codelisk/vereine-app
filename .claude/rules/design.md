---
paths:
  - "**/*.razor"
  - "**/*.razor.css"
  - "**/wwwroot/**"
  - "**/*.xaml"
---

# Oberfläche: Designsystem

Vor dem Schreiben Skill `vereine-design` lesen (Bausteine, Tokens, Icons, Texte). Kurzfassung:

- Werte nur als `var(--…)` aus `.claude/skills/vereine-design/tokens.md`: keine Hex-Farben, kein `rgb()`, keine
  festen `px`/`rem` für Abstand und Schrift, keine Inline-Styles. `tools/check-design.sh` lehnt alles andere ab, auch
  erfundene Token-Namen; der Hook meldet es nach jedem Edit, `dotnet build` bricht ab.
- Bausteine aus `wwwroot/css/base.css` (Markup in `bausteine.md`): `page`, `button` (eine Hauptaktion je Ansicht mit
  `button-primary set-accent`), `icon-button`, `chip`, `list-row`, `card`, `section`, `empty-state`, `banner`,
  `field`, `tab-bar`. Eigenes CSS nur für die Anordnung, in `*.razor.css`.
- Icons nur `<Icon Name="IconName.…" />` (`Components/Design`); Icon-Buttons mit `aria-label`.
- Großer Titel statt Kopfleiste, zwei Textstufen (`--text-base`, `--text-subdued`), Akzent nur für Hauptaktion und
  aktiven Zustand. Hell und Dunkel gleichwertig.
- Texte kurz, Du-Form, Satzschreibung, keine Gedankenstriche (`texte.md`).
- Erzeugt, nie von Hand ändern: `wwwroot/css/tokens.css`, `wwwroot/css/base.css`, `wwwroot/icons.svg`,
  `Components/Design/IconName.cs`, `Resources/Styles/Tokens.xaml`, `Resources/Styles/Tokens.props`,
  `Platforms/Android/Resources/values/colors.xml` und der ganze Skill `vereine-design`. Quelle ist vereine-web
  (`design/`, Skill dort), danach `npm run design` in vereine-web; beide Repos committen.
- Größere Oberflächen prüft der Subagent `design-review`.
