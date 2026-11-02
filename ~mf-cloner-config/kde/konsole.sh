# Sets the Konsole tab title and color, if running inside Konsole.
set_terminal_tab_header() {
  local title="$1"
  local qdbus
  [ -n "${KONSOLE_DBUS_SESSION:-}" ] && qdbus=$(command -v qdbus6 || command -v qdbus) || return 0
  "$qdbus" "$KONSOLE_DBUS_SERVICE" "$KONSOLE_DBUS_SESSION" setTabTitleFormat 0 "$title" >/dev/null || true
  "$qdbus" "$KONSOLE_DBUS_SERVICE" "$KONSOLE_DBUS_SESSION" setTabTitleFormat 1 "$title" >/dev/null || true
  "$qdbus" "$KONSOLE_DBUS_SERVICE" "$KONSOLE_DBUS_SESSION" setTabColor "$tab_color" >/dev/null || true
}
