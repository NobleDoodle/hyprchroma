#!/usr/bin/env bash
# How this behaves where it does not belong. The daemon is for Omarchy; on a
# system without it the only correct outcome is to say so and change nothing.
REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd -- "$REPO" || exit 1
chk(){ [[ $2 == "$3" ]] && echo "  PASS $1" || echo "  FAIL $1: got [$2] want [$3]"; }
code(){ sed -e 's/[[:space:]]*#.*//' "$@"; }
countcode(){ local pat=$1; shift; code "$@" | grep -ohE "$pat" | wc -l; }

STAGE=$(mktemp -d "$HOME/portability-XXXXXX"); trap 'rm -rf "$STAGE"' EXIT
make install DESTDIR="$STAGE/root" >/dev/null 2>&1
H="$STAGE/home"; mkdir -p "$H/.config" "$H/.local/state" "$H/.local/share"

# No palette readable: whether omarchy is missing entirely or installed with no
# theme set, there is nothing to follow and nothing should be written.
out=$(timeout 20 systemd-run --user --collect --wait --pipe \
  --property=TemporaryFileSystem=/usr/share/omarchy \
  --property=RestartPreventExitStatus=78 \
  --setenv=HOME="$H" --setenv=XDG_CONFIG_HOME="$H/.config" \
  --setenv=XDG_STATE_HOME="$H/.local/state" --setenv=XDG_DATA_HOME="$H/.local/share" \
  "$STAGE/root/usr/bin/hyprchroma" daemon 2>&1)
chk "refuses with EX_CONFIG when no palette can be read" \
  "$(grep -oE 'status=78/CONFIG' <<<"$out" | head -1)" "status=78/CONFIG"
chk "says why, in words" \
  "$(grep -c 'no theme palette can be read\|omarchy is not installed' <<<"$out")" "1"
chk "writes nothing into a home that has no Omarchy" \
  "$(find "$H/.config" -mindepth 1 2>/dev/null | wc -l)" "0"
chk "the refusal happens before any hook directory is made" \
  "$([ -d "$H/.config/omarchy" ] && echo made || echo none)" "none"

# The check has to be the real operation: a binary that exists but cannot
# produce a colour is not a working Omarchy.
chk "the guard asks omarchy for a colour, not just for its presence" \
  "$(countcode 'omarchy theme color background' bin/hyprchroma)" "1"

# --- the unit must survive Hyprland not being up yet -----------------------
# watch-events returns 0 when there is no event stream, which is the ordinary
# case at login; on-failure would leave the daemon stopped for the session.
unit=packaging/systemd/hyprchromad.service
chk "unit restarts on a clean exit" "$(grep -c '^Restart=always' $unit)" "1"
chk "unit does not use Restart=on-failure" "$(grep -c '^Restart=on-failure' $unit)" "0"
chk "unit does not restart into a missing Omarchy" \
  "$(grep -c '^RestartPreventExitStatus=78' $unit)" "1"

# --- the requirement is stated where someone would look --------------------
chk "PKGBUILD names omarchy" "$(grep -c 'omarchy: REQUIRED' packaging/PKGBUILD)" "1"
chk "README says this is for Omarchy" "$(grep -c 'This is for Omarchy' README.md)" "1"

# --- no promises of a fallback that no longer exists -----------------------
# The timer lived in the plugin's Service.qml, which the split deleted.
# Only claims that one exists; the comments explaining its absence are fine.
chk "nothing still claims a fallback timer exists" \
  "$(grep -rhoE "(service's|a) fallback timer" bin/ lib/ packaging/ README.md 2>/dev/null \
     | grep -v 'no fallback timer' | wc -l)" "0"
