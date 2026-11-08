# Contributing

This repository is a distribution of agent skills for writing piter.now drafts. It is generated
from canonical sources, so most changes are made upstream and arrive here through `sync.sh`.

## What to send

- Corrections to `README.md` (setup steps, wording, a command that no longer works): edit the file
  and open a pull request.
- Corrections to a skill (`skills/*/SKILL.md`, `_common.md`, `templates.md`): open an issue
  naming the file and the line. The files are overwritten on the next sync, so the maintainers
  apply the fix at the source and re-sync. A pull request that edits `skills/` directly is
  accepted only for the sync commit itself.

## Check before you open a pull request

There is no build or CI job. Run these from the repository root:

```sh
repo-standards check --visibility public .
md5sum skills/*/_common.md | cut -d' ' -f1 | sort -u | wc -l     # must print 1
md5sum skills/*/templates.md | cut -d' ' -f1 | sort -u | wc -l   # must print 1
```

`repo-standards` is <https://github.com/anatolykoptev/repo-standards>.

## Commits

Short imperative subject; the body says why. No version tags are cut, so history is the release
record: add a line under "Unreleased" in [CHANGELOG.md](CHANGELOG.md) for any user-visible change.

## Pull requests

- Keep a change to one concern and say how you checked it.
- Never include a token, a writer username or any credential, in the diff or the description.
- Update [docs/INDEX.md](docs/INDEX.md) when you add or rename a document.
