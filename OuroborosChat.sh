#!/usr/bin/env bash
set -euo pipefail

echo "Welcome to OuroborosChat."
# MESSAGES END HERE

FILE="OuroborosChat.sh"
MARKER="# MESSAGES END HERE"

# Read line into INPUT
echo -n "Write your message: "
read -r INPUT

if [[ ! -f "$FILE" ]]; then
  echo "Error: $FILE not found in current directory $(pwd)." >&2
  exit 1
fi

# Find marker line number (first occurrence)
if ! MARKER_LINE=$(awk -v m="$MARKER" '$0==m{print NR; exit}' "$FILE"); then
  echo "Error: Failed to scan $FILE." >&2
  exit 1
fi

if [[ -z "$MARKER_LINE" ]]; then
  echo "Error: Marker line '$MARKER' not found in $FILE." >&2
  exit 1
fi

# Count lines before the marker
COUNT=$(( MARKER_LINE - 1 ))

# Encode INPUT to base64 (single-line)
ENCODED=$(printf '%s' "$INPUT" | base64 | tr -d '\n')

# Prepare insertion line that decodes and prints the original content (preserves newlines)
INSERT_LINE="echo '$ENCODED' | base64 -d; echo"

# Insert line immediately before the marker (first occurrence only)
TMPFILE=$(mktemp)
awk -v m="$MARKER" -v line="$INSERT_LINE" '
  $0==m && !done { print line; print; done=1; next }
  { print }
' "$FILE" > "$TMPFILE"
mv "$TMPFILE" "$FILE"

# Create and switch to the branch named message_<count>
BRANCH="message_${COUNT}"
git checkout -b "$BRANCH"

# Commit the change
git add "$FILE"
git commit -m "message"

# Push the branch
git push -u origin "$BRANCH"

# Open a PR on GitHub targeting master
gh pr create \
  --base master \
  --head "$BRANCH" \
  --title "message" \
  --body "Automated update: add message and open PR."

# Return to master and pull latest
git checkout master
sleep 25
git pull --ff-only

# Invoke OuroborosChat.sh
clear
bash "$FILE"
