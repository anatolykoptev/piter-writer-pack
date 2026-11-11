# CLAUDE.md

Notes for coding agents working on piter-writer-pack: a documentation-only pack of agent skills
(Markdown) that lets a remote writer agent draft articles on piter.now through the go-wp MCP
server. There is no build and no test suite. Every document is indexed in
[docs/INDEX.md](docs/INDEX.md).

## Layout

- `README.md` is the setup guide an incoming writer agent follows (token, MCP registration, skill
  install, verification). It is written for the agent, not for maintainers.
- `skills/<name>/SKILL.md` is one skill each: `piter-writer` (invariants and authority boundary,
  read first), `podborka-editorial` (editorial canon), and the recipes `create-article`,
  `create-events`, `update-article`, `update-facts`, `update-single`, `fix-article`,
  `news-pipeline`, `maintenance`.
- `skills/<name>/_common.md` (content rules and the JSONL bible) and `skills/<name>/templates.md`
  are byte-identical copies in every skill directory, so each skill is self-contained when
  installed alone.
- `sync.sh` regenerates the whole `skills/` tree from the canonical sources.

## Gate

There is no CI workflow. Before a PR:

```sh
repo-standards check --visibility public .   # documents and personal-data scan
md5sum skills/*/_common.md | cut -d' ' -f1 | sort -u | wc -l   # must print 1
md5sum skills/*/templates.md | cut -d' ' -f1 | sort -u | wc -l # must print 1
```

## Invariants that are easy to break

- **Do not hand-edit `skills/`.** `sync.sh` runs `rsync --delete` and overwrites every file under
  `skills/`, and the `_common.md` and `templates.md` copies must stay identical. Change the
  canonical source, then run `sync.sh` from a machine that has access to it.
- **Draft only, `project=piter` only.** The skills describe a writer identity whose publishing and
  live-post edits are rejected server-side. Never write a skill that instructs routing around a
  `denied` response.
- **No tokens, ever.** The README tells agents to receive the bearer token out of band (a file in
  the working directory, a file in the home directory, or the clipboard) and never from chat or
  from a repository. `.gitignore` excludes `.env`. Do not commit a token, a username issued to a
  writer, or an example that looks like one.
- **The recipes assume MCP access only.** Anything reachable only over SSH or on the server
  filesystem is operator-side; the skills tell the writer to flag it, not to attempt it.
- **This repository is public.** No hostnames of private machines, SSH aliases, operator paths,
  account names or tokens in tracked files. The pack still carries some such text copied from the
  canonical sources (`repo-standards check` reports the lines); removing it is a change to the
  canonical sources first, then a re-sync.
