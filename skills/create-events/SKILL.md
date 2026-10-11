---
name: create-events
description: Create a new WordPress EVENTS collection (a time-bound афиша of concerts, festivals, exhibitions, spectacles, city events for a specific month/season) from scratch via the go-wp create-events workflow. Triggers on "мероприятия", "события", "events", "афиша", "главные мероприятия", "мероприятия месяца", "события мая/июня/…", "лучшие мероприятия", "create events". For an evergreen PLACES collection (рестораны, музеи, школы, сервисы) use create-article instead.
argument-hint: "topic=\"Главные мероприятия <месяц> <год> в <городе>\" [project=piter]"
---

# Create Events

A time-bound EVENTS collection (афиша) via the go-wp **create-events** workflow. Distinct from `create-article` (evergreen places): events have a target month/year window, KudaGo/aggregator research, and a **`select-events` curation gate you must actively drive**. Read `_common.md` (content rules + JSONL format) every run.

## When to use
- **create-events (this):** a dated round-up — «Главные мероприятия августа 2026», афиша фестивалей/концертов/выставок for a specific month/season.
- **create-article:** an evergreen PLACES collection.

## Arguments
- `topic` — include the month + year, e.g. «Главные мероприятия августа 2026 в Петербурге» (required).
- `project` — `piter` (RU, default) / `hully` (EN). Pass `project={PROJECT}` to every `wp_*` call.

## Setup
Load the deferred go-wp / go-search / go-wowa MCP tools (ToolSearch), same as create-article — see `_common.md`. Confirm `project` first (piter default; ASK only if genuinely ambiguous).

## Pipeline

### 1. Dedup pre-gate
`wp_dedup_batch` / `wp_post list search="<месяц> <год>"` — confirm no collection for THIS month/year already exists (the previous months' events posts are the TEMPLATE, not a dup). A current one exists → `status:skipped` (clean no-op, not failed).

### 2. Start the workflow
```
wf_create template=create-events owner=claude:session params={ "topic": "{{topic}}", "project": "{{project}}", "city": "{CITY}" }
```
`{CITY}`: piter → `Санкт-Петербург`; hully → the CA city from the topic. (`{{topic}}`/`{{project}}` are engine template vars; substitute `{CITY}` yourself.)

### 3. DRIVE each gate ACTIVELY (7 steps)

> ⚠️ **THE failure mode — do not repeat it.** A step in `waiting_approval` is YOUR cue to ACT — NOT a stall to poll, NOT a failure. An approval gate advances ONLY when YOU handle it. NEVER sit polling `wf_status` waiting for the engine to self-advance; NEVER report "stuck/running/failed" at an approval gate. `select-events` (Step 2) is exactly where an un-driven run wrongly gives up.

**Step 1 — research (auto, ~2-3 min):** `wp_research` fetches events from KudaGo + aggregators for the target month/year. It runs by itself and CAN take 2-3 minutes — that is NORMAL, not a hang. Let it COMPLETE; the workflow then parks at select-events.

**Step 2 — select-events (approval) — the curation gate:** read the candidates (`wf_status` / `wp_research_get` / the research file). Curate the BEST events — match the count/quality of the previous monthly-events post (read it via `wp_post action=get decompile=true` for the bar). Approve WITH your selection:
```
wf_approve workflow_id=ID approved=true data={"selected": ["Event name 1", "Event name 2", ...]}
```
ANTI-FAB: select only REAL events with a verifiable date + venue in the research; drop uncertain ones; never pad the count.

**Step 3 — enrich (approval):** `wp_enrich mode=events data=[{"name":"...","city":"...","website":"<research source url>"}]` on the selected set. **Thread each event's `website`** = its research candidate's source link (the kudago/fiesta URL from the research file / `wp_research_get`). This is load-bearing anti-fab, not optional: with a `website` the enricher FETCHES that known page (correct entity + richer facts); WITHOUT it the enricher falls back to a bare-NAME web search, whose top hit is routinely a same-name venue in another city or an unrelated page (a Moscow «Вселенная неоклассики», an Outlook download page) — a WRONG venue on the card. When a candidate genuinely has no source URL, omit `website`: the server-side events gate then suppresses the uncorroborated venue (a MISS beats a WRONG match) rather than fabricating one. Verify each result has date(s) + venue; an item returned with `low_confidence` + a suppressed venue means no reliable page was found — drop it or supply a real `website`. Approve.

**Step 4 — compose-content (approval):** compose following the previous monthly-events post's format + `~/.claude/skills/podborka-editorial/SKILL.md` (opening doctrine — single source of truth) + `~/.claude/skills/humanizer/SKILL.md` + `_common.md` RU-hygiene. Per event: name, date/period, venue, a short warm description, price/ticket link if stated. Clean RU from the first draft. Write the JSONL + meta, approve.

**Step 5 — validate (approval):** `wp_render_blocks … validate_level=strict`, fix to 0 errors, approve.

**Step 6 — create-draft (approval):** build the post `status=draft`, HOLD it (title, rendered HTML via the html_file from step 5, `wp_seo`, ≤150-char excerpt, `wp_check_anglicisms`, `wp_audit_article`→0, featured image). **TAGS (policy):** primary «мероприятия Петербург <Месяц Год>» (a «<тема> <Месяц Год>» event tag) + reuse thematic tags («фестивали Петербург», «концерты СПб») — NEVER bare «Санкт-Петербург», bare «<Месяц Год>», or single-word tags; ~3-5 total. Do NOT run `assign_date_tags` (bare-date noise). Then `wf_approve … data={"post_id":ID,"status":"draft"}`.

**Step 7 — go-live (approval):** the publish gate. STANDALONE run: re-run `wp_audit_article` FRESH, then self-approve. **workflow_mode / council build: STOP HERE — do NOT approve go-live; the parked held draft is the terminal.** `resumePublish` (later) crosses go-live after a fresh clean audit.

`wf_status workflow_id=ID` anytime; `wf_cancel workflow_id=ID` to abort.

## Key rules
- Anti-fabrication is cardinal: every event REAL, date + venue verified; empty beats invented; never pad.
- YOU drive every gate; `waiting_approval` = act now, never poll or treat as a stall/failure.
- Events tag policy above (time-bound «<тема> <Месяц Год>», no bare city/date/single-word).
- In workflow_mode keep it a DRAFT (stop at go-live); a build never publishes.
