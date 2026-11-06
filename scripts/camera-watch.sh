#!/bin/sh
# Streams open/close events on the camera devices for services/Camera.qml, one per line:
#   "OPEN /dev/video0" or "CLOSE_NOWRITE,CLOSE /dev/video0".
# Catches apps that open the camera directly instead of through PipeWire (most browsers).
# Exits quietly when there are no video devices or inotifywait (inotify-tools) is missing.
set -- /dev/video*
[ -e "$1" ] || exit 0
command -v inotifywait >/dev/null 2>&1 || exit 0
# setpriv: exit when the shell does, even if it is killed outright (Quickshell leaves long-running
# children behind then).
exec setpriv --pdeathsig TERM inotifywait -m -q -e open -e close --format '%e %w' "$@"
