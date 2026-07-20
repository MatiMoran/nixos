#!/bin/bash

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('command', ''))
" 2>/dev/null)

[ -z "$COMMAND" ] && exit 0

DESTRUCTIVE_PATTERNS=(
  "rm -rf"
  "rm -r"
  "rm -f"
  "git reset --hard"
  "git clean"
  "git push --force"
  "git push -f"
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE"
  "dd if="
  "mkfs"
  ": > "
  "chmod -R 777"
)

MATCHED=""
for pattern in "${DESTRUCTIVE_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qi "$pattern"; then
    MATCHED="$pattern"
    break
  fi
done

[ -z "$MATCHED" ] && exit 0

RESULT=$(osascript -e "
button returned of (display dialog \"⚠️ Destructive command detected\n\nPattern: $MATCHED\n\nCommand:\n$COMMAND\n\nDo you want to run it?\" \
  with title \"Claude Code — Destructive Command\" \
  buttons {\"Block\", \"Run\"} \
  default button \"Block\" \
  with icon caution)" 2>/dev/null)

if [[ "$RESULT" != "Run" ]]; then
  echo "Blocked by user — destructive command confirmation declined." >&2
  exit 2
fi

exit 0
