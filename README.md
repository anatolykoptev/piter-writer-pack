# piter-writer access pack

Everything an AI agent needs to write draft content on **piter.now** through the `go-wp` MCP server — no SSH, no WordPress login, no server access.

## 0. Get this pack

```bash
git clone https://github.com/anatolykoptev/piter-writer-pack
```

Private repo — authenticate with whichever GitHub access you were given (a read-only PAT works: `git clone https://x-access-token:<GH_PAT>@github.com/anatolykoptev/piter-writer-pack`). If `gh` is already authenticated, `gh repo clone anatolykoptev/piter-writer-pack` just works.

## What's inside

```
skills/
  piter-writer/          — pipeline invariants + your authority boundary (READ FIRST)
  podborka-editorial/    — the editorial canon for leads/intros (single source of truth)
  create-article/        — new collection/article workflow
  create-events/         — monthly events round-up (афиша)
  update-article/        — full refresh of a place-listicle
  update-facts/          — refresh a fact-listicle
  update-single/         — historical-date / place-review (Gutenberg blocks directly)
  fix-article/           — targeted validator-error fixes
  news-pipeline/         — news posts
  maintenance/           — cross-article links/tags/SEO
  */_common.md           — content rules + JSONL bible (bundled in every skill)
  */templates.md         — paragraph/block templates
```

## 1. Register the MCP server

Add this to your agent's MCP config, replacing `<TOKEN>` with the bearer token you were given **over a secure channel** (it is not in this pack):

```json
"go-wp": {
  "type": "http",
  "url": "https://mcp.krolik.run/wp/mcp",
  "headers": { "Authorization": "Bearer <TOKEN>" }
}
```

- **Claude Code**: `claude mcp add --transport http go-wp https://mcp.krolik.run/wp/mcp --header "Authorization: Bearer <TOKEN>"`
- **Devin CLI**: add the JSON block to `mcpServers` in your Devin config
- **Other MCP clients**: remote HTTP server, `Authorization: Bearer` header — same shape

## 2. Install the skills

Copy every directory under `skills/` into your agent's skills directory:

- Claude Code → `~/.claude/skills/`
- Devin → `~/.devin/skills/` (global) or `.devin/skills/` (project)
- Other agents → wherever agent skills live

Keep `_common.md` and `templates.md` inside each skill directory — the recipes reference them locally.

## 3. Verify

Ask the agent to run `wp_post action=list project=piter posts_per_page=1`. A JSON list of posts = connected. `invalid token` = the header/token is wrong; `denied` on anything else = expected — see below.

## Rules that are enforced server-side

- **Draft only.** You build and audit drafts; publishing is the operator's step. The server rejects live-post edits, `go-live` approval, and `wp_cli` — a `denied` is correct behaviour, not a bug. Never retry or route around it.
- **`project=piter` only.** Every `wp_*` call takes `project=piter`; other project names are rejected.
- **The token is your identity.** It attributes every action to you in the audit log and to your WordPress author account. Do not paste it into prompts, commits, tickets, or this file. If it leaks, tell the operator — revocation is instant.
- **Read `skills/piter-writer/SKILL.md` before your first task** — the 8 PRIME DIRECTIVES (anti-fabrication, validation gates, image QC, JSONL discipline, …) are mandatory, and the reporting contract is the required shape of every final report.

## Revocation

Access ends the moment the operator removes your entry from the go-wp identity store — your token stops resolving immediately, no restarts needed. Report a lost/compromised token the moment you notice.
