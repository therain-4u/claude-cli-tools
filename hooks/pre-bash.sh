#!/bin/sh
# Claude Code PreToolUse audit hook
# Logs every Bash command attempted (before permission check / execution)
# Output: <tools-dir>/data/bash-audit.jsonl

TOOLS_DIR="$(cd "$(dirname "$0")/.." && pwd)"

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // ""')
TID=$(printf '%s' "$INPUT" | jq -r '.tool_use_id // ""')

jq -cn \
  --arg ts  "$TS"  \
  --arg sid "$SID" \
  --arg tid "$TID" \
  --arg cmd "$CMD" \
  '{ts:$ts, session:$sid, tool_use_id:$tid, event:"attempted", cmd:$cmd}' \
  >> "$TOOLS_DIR/data/bash-audit.jsonl"

exit 0
