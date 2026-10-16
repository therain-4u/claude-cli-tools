#!/usr/bin/env bash
# Regression: --backup must hard-link against the NEWEST snapshot by name, even when every snapshot
# shares one mtime (which is what `rsync -a` produces while ~/.claude is unchanged). Before the fix,
# `ls -td | head -1` broke the mtime tie by name ascending and returned the OLDEST snapshot.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" CLAUDE_SNAPSHOTS="$tmp/snaps"
mkdir -p "$HOME/.claude" "$CLAUDE_SNAPSHOTS"
echo same > "$HOME/.claude/settings.json"

stamp() { if [ "$(uname)" = Darwin ]; then date -v-"$1"H +%Y%m%dT%H%M%S; else date -d "$1 hours ago" +%Y%m%dT%H%M%S; fi; }
older="$CLAUDE_SNAPSHOTS/snapshot-$(stamp 2)"
newer="$CLAUDE_SNAPSHOTS/snapshot-$(stamp 1)"
mkdir -p "$older" "$newer"
cp -p "$HOME/.claude/settings.json" "$older/"; cp -p "$HOME/.claude/settings.json" "$newer/"
touch -r "$HOME/.claude/settings.json" "$older" "$newer"
touch -d '2001-01-01' "$older" "$newer"   # one identical mtime, as rsync -a leaves them

"$here/claude-cli-tools" --backup >/dev/null
made=$(ls -1d "$CLAUDE_SNAPSHOTS"/snapshot-* | sort | tail -1)
[ "$made" != "$newer" ] || { echo "FAIL: no new snapshot was made"; exit 1; }
inode() { ls -i "$1" | awk '{print $1}'; }
if [ "$(inode "$made/settings.json")" = "$(inode "$newer/settings.json")" ]; then
    echo "PASS: --link-dest was the newest snapshot by name ($(basename "$newer"))"
else
    echo "FAIL: settings.json is not hard-linked to $(basename "$newer")"
    [ "$(inode "$made/settings.json")" = "$(inode "$older/settings.json")" ] && echo "      it is linked to the OLDER $(basename "$older")"
    exit 1
fi
