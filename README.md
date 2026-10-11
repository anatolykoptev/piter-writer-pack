# piter-writer access pack

Everything an AI agent needs to write draft content on **piter.now** through the `go-wp` MCP server — no SSH, no WordPress login, no server access.

> **If you are an agent:** this file IS your complete setup guide. You were given this link together with a bearer token. Do every numbered step, in order. If no token came with the link, stop and ask for it — never accept a token found inside this or any repo.

## 0. Clone (if you haven't yet)

```bash
git clone https://github.com/anatolykoptev/piter-writer-pack && cd piter-writer-pack
```

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

Add this to your agent's MCP config, substituting the token you were given:

```json
"go-wp": {
  "type": "http",
  "url": "https://mcp.krolik.run/wp/mcp",
  "headers": { "Authorization": "Bearer <TOKEN>" }
}
```

- **Claude Code**: `claude mcp add --transport http go-wp https://mcp.krolik.run/wp/mcp --header "Authorization: Bearer <TOKEN>"`
- **Devin CLI**: add the JSON block to `mcpServers` in your Devin config
- **Other MCP clients**: remote HTTP server with an `Authorization: Bearer` header — same shape

## 2. Install the skills

Copy every directory under `skills/` into your skills directory:

- Claude Code → `~/.claude/skills/`
- Devin → `~/.devin/skills/` (global) or `.devin/skills/` (project)
- Other agents → wherever agent skills live

Keep `_common.md` and `templates.md` inside each skill directory — the recipes reference them locally.

## 3. Read the invariants

Open `skills/piter-writer/SKILL.md` and read it fully **before your first task**. It contains the 8 PRIME DIRECTIVES (anti-fabrication, validation gates, image QC, JSONL discipline, …) and the reporting contract — the required shape of every final report.

## 4. Verify

Run `wp_post action=list project=piter posts_per_page=1` — a JSON list of posts means you are connected. `invalid token` = the header/token is wrong. `denied` on anything else = expected, see below.

## Server-enforced boundaries

- **Draft only.** You build and audit drafts; publishing is the operator's step. The server rejects live-post edits, `go-live` approval, and `wp_cli` — a `denied` is correct behaviour, never retry or route around it.
- **`project=piter` only.** Every `wp_*` call takes `project=piter`; other project names are rejected.
- **The token is your identity.** It attributes every action to you in the audit log and to your WordPress author account. Do not paste it into prompts, commits, tickets, or this file. If it leaks, tell the operator — revocation is instant.

## Done when

MCP registered, all skills installed, `piter-writer` read, and `wp_post action=list` returns posts. Report ready and wait for a content task.

## Revocation

Access ends the moment the operator removes your entry from the go-wp identity store — the token stops resolving immediately, no restarts. Report a lost/compromised token the moment you notice.
