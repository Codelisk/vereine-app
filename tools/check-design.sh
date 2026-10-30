#!/usr/bin/env bash
# Prüft die Oberfläche gegen das Designsystem (Skill `vereine-design`): Farben, Schrift, Radien, Schatten und
# Abstände kommen nur aus den Design-Tokens, nie als feste Werte.
#
# Aufruf:  tools/check-design.sh                      ganze App (src/Vereine.App)
#          tools/check-design.sh <datei>…             nur diese Dateien (Claude-Hook nach jedem Edit)
#          tools/check-design.sh --generated <datei>  Exit 0, wenn die Datei aus vereine-web/design erzeugt ist
#
# Ausgabe im MSBuild-Format `datei(zeile): error VDS…: text`. Der Build ruft das Skript auf (Vereine.App.csproj,
# Target _VereineDesignPruefen), Treffer sind dort Build-Fehler. Exit 1 bei Treffern, sonst 0.
set -uo pipefail
shopt -s extglob

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
app="$repo_root/src/Vereine.App"

# Erzeugt aus vereine-web/design (`npm run design` dort). Nur hier dürfen Werte stehen.
generated=(
  "$app/wwwroot/css/tokens.css"
  "$app/wwwroot/css/base.css"
  "$app/wwwroot/icons.svg"
  "$app/Components/Design/IconName.cs"
  "$app/Resources/Styles/Tokens.xaml"
  "$app/Resources/Styles/Tokens.props"
  "$app/Platforms/Android/Resources/values/colors.xml"
)

# Farbwerte: Hex mit 3, 4, 6 oder 8 Stellen (nicht `&#160;`, nicht `repo#123`) und Farbfunktionen.
hex='(^|[^&A-Za-z0-9_/#-])#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3,4})([^0-9A-Za-z_-]|$)'
color_fn='(^|[^a-z-])(rgba?|hsla?|hwb|lab|lch|oklab|oklch|color)\('
# Benannte Farben als Wert einer Farb-Eigenschaft (white, black, red …). transparent und currentColor sind erlaubt.
named_color='(color|background|border|outline|fill|stroke|shadow)[a-z-]*[[:space:]]*:[^;{}]*(^|[^a-z-])(white|black|red|green|blue|gray|grey|silver|yellow|orange|purple|pink|navy|teal|lime|maroon|olive|aqua|fuchsia|brown|gold|beige)([^a-z-]|$)'
# Diese Eigenschaften brauchen ein Token (var(--…)); erlaubt sind nur Schlüsselwörter wie 0, none, inherit.
token_props='font-family|font-size|font-weight|line-height|letter-spacing|border-radius|box-shadow|z-index|transition-duration|animation-duration'
spacing_props='margin|margin-top|margin-right|margin-bottom|margin-left|margin-block|margin-inline|margin-block-start|margin-block-end|margin-inline-start|margin-inline-end|padding|padding-top|padding-right|padding-bottom|padding-left|padding-block|padding-inline|padding-block-start|padding-block-end|padding-inline-start|padding-inline-end|gap|row-gap|column-gap'
literal_length='(^|[^a-z0-9.-])-?[0-9]*\.?[0-9]+(px|rem|em|pt)([^a-z]|$)'

errors=0

# Bekannte Tokens: alle in tokens.css definierten Custom Properties. Erfundene Namen (var(--color-txt)) sind Fehler.
declare -A known=()
while IFS= read -r name; do known["$name"]=1; done < <(
  grep -oE '^[[:space:]]*--[a-zA-Z0-9_-]+[[:space:]]*:' "$app/wwwroot/css/tokens.css" 2>/dev/null | tr -d ' :'
)

report() { # datei zeile code text
  printf '%s(%s): error %s: %s\n' "$1" "$2" "$3" "$4"
  errors=$((errors + 1))
}

is_generated() {
  local f
  for f in "${generated[@]}"; do [ "$1" = "$f" ] && return 0; done
  [[ "$1" == "$repo_root/.claude/skills/vereine-design/"* ]]
}

if [ "${1:-}" = "--generated" ]; then
  file="${2:-}"
  case "$file" in /*) ;; *) file="$PWD/$file" ;; esac
  is_generated "$file"
  exit
fi

# Zeilen ohne Kommentarinhalt: /* … */ (CSS), <!-- … --> (XAML, HTML), @* … *@ (Razor) werden geleert,
# damit Issue-Nummern oder Beispiele in Kommentaren nicht anschlagen. Mehrzeilige Kommentare zählen mit.
strip_comments() {
  awk '
    {
      line = $0; out = ""
      while (length(line) > 0) {
        if (incomment != "") {
          i = index(line, incomment)
          if (i == 0) { line = ""; break }
          line = substr(line, i + length(incomment)); incomment = ""
          continue
        }
        a = index(line, "/*"); b = index(line, "<!--"); c = index(line, "@*")
        first = 0; op = ""; cl = ""
        if (a > 0) { first = a; op = "/*"; cl = "*/" }
        if (b > 0 && (first == 0 || b < first)) { first = b; op = "<!--"; cl = "-->" }
        if (c > 0 && (first == 0 || c < first)) { first = c; op = "@*"; cl = "*@" }
        if (first == 0) { out = out line; line = ""; break }
        out = out substr(line, 1, first - 1)
        line = substr(line, first + length(op)); incomment = cl
      }
      print out
    }' "$1"
}

# Meldet var(--name) ohne Definition in tokens.css oder in derselben Datei.
check_unknown_tokens() { # datei zeile text, lokale Namen in $local_names
  local rest="$3" name
  while [[ "$rest" =~ var\(--([a-zA-Z0-9_-]+) ]]; do
    name="--${BASH_REMATCH[1]}"
    rest="${rest#*"${BASH_REMATCH[0]}"}"
    [[ -n "${known[$name]:-}" || " $local_names " == *" $name "* ]] && continue
    report "$1" "$2" VDS005 "Unbekanntes Token $name. Erlaubt sind die aus tokens.css (Skill vereine-design, tokens.md)."
  done
}

check_css() {
  local file="$1" n=0 line
  local local_names
  local_names="$(grep -oE '(^|[;{[:space:]])--[a-zA-Z0-9_-]+[[:space:]]*:' "$file" | grep -oE -- '--[a-zA-Z0-9_-]+' | tr '\n' ' ')"
  while IFS= read -r line; do
    n=$((n + 1))
    check_unknown_tokens "$file" "$n" "$line"
    [[ "$line" =~ $hex ]] && report "$file" "$n" VDS001 "Fester Farbwert. Nimm ein Farb-Token, z. B. var(--text-base)."
    [[ "$line" =~ $color_fn ]] && report "$file" "$n" VDS001 "Farbfunktion mit festen Werten. Nimm ein Farb-Token; color-mix() nur mit var(--…)."
    [[ "$line" =~ $named_color ]] && report "$file" "$n" VDS001 "Benannte Farbe. Nimm ein Farb-Token."
    if [[ "$line" =~ (^|[;{[:space:]])($token_props)[[:space:]]*:([^;}]*) ]]; then
      local prop="${BASH_REMATCH[2]}" value="${BASH_REMATCH[3]}"
      if [[ ! "$value" =~ var\(-- ]] && [[ ! "$value" =~ ^[[:space:]]*(0|none|inherit|initial|unset|normal|auto)[[:space:]]*(!important)?[[:space:]]*$ ]]; then
        report "$file" "$n" VDS002 "$prop ohne Token. Nimm var(--…) aus tokens.css."
      fi
    fi
    if [[ "$line" =~ (^|[;{[:space:]])($spacing_props)[[:space:]]*:([^;}]*) ]]; then
      local value="${BASH_REMATCH[3]//var(--+([a-z0-9-]))/}"
      [[ "$value" =~ $literal_length ]] && report "$file" "$n" VDS003 "Fester Abstand. Nimm var(--space-…)."
    fi
  done < <(strip_comments "$file")
}

check_razor() {
  local file="$1" n=0 line
  while IFS= read -r line; do
    n=$((n + 1))
    [[ "$line" =~ (^|[[:space:]])style[[:space:]]*= ]] && report "$file" "$n" VDS004 "Inline-Style. Stil gehört in die .razor.css mit Tokens."
    [[ "$line" =~ \<style([[:space:]>]|$) ]] && report "$file" "$n" VDS004 "<style>-Block. Stil gehört in die .razor.css mit Tokens."
    [[ "$line" =~ $hex ]] && report "$file" "$n" VDS001 "Fester Farbwert. Farben kommen nur aus den Tokens."
  done < <(strip_comments "$file")
}

check_markup() { # XAML, HTML, Android-XML, csproj
  local file="$1" n=0 line
  while IFS= read -r line; do
    n=$((n + 1))
    [[ "$line" =~ $hex ]] && report "$file" "$n" VDS001 "Fester Farbwert. Nimm die Ressource aus Tokens.xaml bzw. die Eigenschaft aus Tokens.props."
    [[ "$line" =~ [A-Za-z]*Color[[:space:]]*=[[:space:]]*\"(White|Black|Transparent|[A-Z][a-z]+)\" ]] &&
      report "$file" "$n" VDS001 "Benannte Farbe. Nimm die Ressource aus Tokens.xaml."
    [[ "$file" == *.html && "$line" =~ (^|[[:space:]])style[[:space:]]*= ]] &&
      report "$file" "$n" VDS004 "Inline-Style. Stil gehört in app.css mit Tokens."
  done < <(strip_comments "$file")
}

check_file() {
  local file="$1"
  case "$file" in /*) ;; *) file="$PWD/$file" ;; esac
  [ -f "$file" ] || return 0
  case "$file" in "$app"/*) ;; *) return 0 ;; esac
  case "$file" in */artifacts/*|*/bin/*|*/obj/*) return 0 ;; esac
  is_generated "$file" && return 0
  case "$file" in
    *.css) check_css "$file" ;;
    *.razor) check_razor "$file" ;;
    *.xaml|*.html|*.csproj|*/Platforms/Android/Resources/*.xml|*.props) check_markup "$file" ;;
  esac
}

if [ "$#" -gt 0 ]; then
  for f in "$@"; do check_file "$f"; done
else
  while IFS= read -r -d '' f; do check_file "$f"; done < <(
    find "$app" \( -name artifacts -o -name bin -o -name obj \) -prune -o -type f \
      \( -name '*.css' -o -name '*.razor' -o -name '*.xaml' -o -name '*.html' -o -name '*.csproj' -o -name '*.props' -o -path '*/Platforms/Android/Resources/*.xml' \) -print0
  )
fi

if [ "$errors" -gt 0 ]; then
  echo "Designsystem: $errors Verstoß/Verstöße. Werte stehen nur in vereine-web/design/tokens.json (Skill vereine-design)." >&2
  exit 1
fi
exit 0
