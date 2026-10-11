#!/usr/bin/env bash
# Regenerate the pack from canonical sources. Run from the repo root.
# Sources: krolik:~/src/go-wp (.claude/skills + docs) and the operator's
# podborka-editorial skill. Re-run after any go-wp skill/_common.md change.
set -euo pipefail

cd "$(dirname "$0")"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ssh krolik 'tar czf - -C ~/src/go-wp .claude/skills docs/skills docs/project' \
  | tar xzf - -C "$TMP"

rsync -a --delete "$TMP/.claude/skills/" skills/
rsync -a "$HOME/.claude/skills/podborka-editorial/" skills/podborka-editorial/

for d in skills/*/; do
  cp "$TMP/docs/skills/_common.md" "$TMP/docs/project/templates.md" "$d"
  sed -i '' 's|docs/skills/_common\.md|_common.md|g; s|docs/project/templates\.md|templates.md|g' "$d/SKILL.md"
done

echo "Synced. Review with: git status --short"
