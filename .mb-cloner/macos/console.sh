# Sets the terminal tab title on macOS (Terminal.app, iTerm2, Ghostty, ...), plus the tab color on iTerm2.
set_terminal_tab_header() {
  local title="$1"
  # Write to the terminal directly so it works even when stdout is redirected
  { : >/dev/tty; } 2>/dev/null || return 0

  # OSC 0: set window/tab title (supported by virtually every macOS terminal)
  printf '\033]0;%s\007' "$title" 2>/dev/null >/dev/tty || true

  # Tab color is iTerm2-only (OSC 6); other terminals have no escape sequence for it
  [ "${TERM_PROGRAM:-}" = "iTerm.app" ] || return 0
  local rgb
  case "${tab_color:-}" in
    red) rgb="220 50 47" ;;
    green) rgb="76 175 80" ;;
    blue) rgb="33 150 243" ;;
    yellow) rgb="255 235 59" ;;
    orange) rgb="255 152 0" ;;
    purple) rgb="156 39 176" ;;
    cyan) rgb="0 188 212" ;;
    magenta) rgb="255 0 255" ;;
    pink) rgb="233 30 99" ;;
    brown) rgb="121 85 72" ;;
    gray | grey) rgb="158 158 158" ;;
    \#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])
      rgb="$((16#${tab_color:1:2})) $((16#${tab_color:3:2})) $((16#${tab_color:5:2}))" ;;
    *) return 0 ;;
  esac
  local r g b
  read -r r g b <<<"$rgb"
  printf '\033]6;1;bg;red;brightness;%s\007\033]6;1;bg;green;brightness;%s\007\033]6;1;bg;blue;brightness;%s\007' \
    "$r" "$g" "$b" 2>/dev/null >/dev/tty || true
}
