#!/bin/sh
# Claude Code PostToolUse audit hook
# Logs every Bash command that actually completed (approved + ran)
# Pairing pre/post by tool_use_id reveals which commands were denied or cancelled
# Output: <tools-dir>/data/bash-audit.jsonl

TOOLS_DIR="$(cd "$(dirname "$0")/.." && pwd)"

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // ""')
TID=$(printf '%s' "$INPUT" | jq -r '.tool_use_id // ""')
EC=$(printf '%s'  "$INPUT" | jq -r '.tool_response.exit_code // .tool_response.exitCode // "?"')

jq -cn \
  --arg ts  "$TS"  \
  --arg sid "$SID" \
  --arg tid "$TID" \
  --arg cmd "$CMD" \
  --arg ec  "$EC"  \
  '{ts:$ts, session:$sid, tool_use_id:$tid, event:"completed", cmd:$cmd, exit_code:$ec}' \
  >> "$TOOLS_DIR/data/bash-audit.jsonl"

exit 0
