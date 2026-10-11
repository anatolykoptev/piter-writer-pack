---
name: create-article
description: Create a new WordPress article or evergreen PLACES collection (restaurants, bars, museums, schools, services) from scratch. Use when asked to write a new article, create a collection of places, or build a listicle. Triggers on "new article", "create article", "write article", "create collection", "new collection", "подборка", "создать подборку", "новая подборка", "написать подборку", "топ мест", "лучшие места", "создать статью", "написать статью", "novaya statya", "napisat statyu". For an events/афиша round-up (мероприятия/события for a specific month) use the create-events skill.
argument-hint: "topic=\"...\" [project=piter]"
---

# Create Article

Creates a new evergreen PLACES article/collection (restaurants, bars, museums, schools, services) via the **go-workflow** `create-collection` pipeline.

Read `_common.md` for content rules and data format.

## Project selection

Project routing (`piter`=RU / `hully`=EN; ASK if ambiguous) and the Hully-specific notes live in `_common.md` (read every run). Pass `project={PROJECT}` to every `wp_*` call.

## Arguments

- `topic` — article topic (required)
- `project` — project key (default: `piter`)

## Setup

Load deferred MCP tools:

    ToolSearch "+go-wp wf_create wf_status wf_approve wf_cancel wf_templates"
    ToolSearch "+go-wp wp_prd temp render image post seo enrich audit research format tags flush check dedup"
    ToolSearch "+go-search smart web_url"

## Pipeline

### 1. PLAN

Check for duplicates:
```
wp_dedup_batch articles=[{"title":"Proposed title"}] project={PROJECT}
```

### 2. START WORKFLOW

For events (мероприятия/афиша) use the create-events skill — do not use create-collection for events.

Template: `create-collection` (restaurants, bars, museums, etc.)

**City param per project:**
- `project=piter` → `city="Санкт-Петербург"`
- `project=hully` → `city="San Francisco"` (default) OR a more specific CA city from the topic (e.g. "Los Angeles", "San Diego"). If the topic says "best coffee in Oakland", use `city="Oakland"`.
- Substitute `{CITY}` literally in the `wf_create` payload before calling.

> **Note on variable syntax**: `{{project}}` inside `wf_create` JSON is a **workflow-engine template var** resolved at workflow execution time. Agent-side substitutions elsewhere (in tool calls like `wp_check_style project={PROJECT}`) use single-brace `{PROJECT}` which YOU substitute at skill execution time. Do not confuse them.

```
wf_create template=create-collection owner=claude:session params={
  "topic": "{{topic}}",
  "project": "{{project}}",
  "city": "{CITY}"
}
```

### 3. FOLLOW WORKFLOW STEPS

The workflow has 7 steps. Step 1 (research) runs automatically.

**Step 1: research** (auto) — `wp_research` discovers items from competitor articles.

**Step 2: select** (approval) — Review research results. Pick 10-15 best items. Approve:
```
wf_approve workflow_id=ID approved=true data={"selected": ["Name1", "Name2", ...]}
```

**Step 3: enrich** (approval) — Build JSON array from selected items, call `wp_enrich`:
```
wp_enrich mode=places data=[{"name":"...", "city":"..."}]
```

`wp_enrich` may return immediately with `status=running` (async processing for >2 items).
In that case, **poll until done**:
```
wp_enrich action=status
```
Repeat until `status=done` BEFORE approving. Do NOT approve while `status=running`.

**Quality gate (MANDATORY before approving):**
After enrichment completes, verify the results:
- If >50% of places have `low_confidence=true` OR are missing BOTH `phone` AND `website`:
  REJECT with `wf_approve approved=false` and report the issue (enrichment quality too low).
- Only approve when enrichment is complete AND the majority of places have usable contact
  data (phone or website). Approving with garbage data produces a garbage article.

**Step 4: compose** (approval) — Write article content using enriched data:
1. **BEFORE writing, read three references and apply them THROUGHOUT composing:**
   - `~/.claude/skills/podborka-editorial/SKILL.md` — the **single source of truth** for the
     opening-structure standard: lead hook opener, intro context ladder, brief routing axes
     🏆/💰/🌟/📍. Load it locally; do not write the opening from memory or any restatement.
     (`wp_format_spec.editorial_standard_ref` and PRD `data_rules.lead_rule` /
     `.intro_rule` / `.brief_axes` all point here — they are not the rules themselves.)
   - `~/.claude/skills/humanizer/SKILL.md` — kills AI-tells (em-dash, rule-of-three, inflated symbolism, vague attributions, filler, varied sentence length).
   - `_common.md` sections "Russian-language hygiene" + "Foreign proper nouns: examples" — six rules: prefer Russian when it means the same; keep long-loads; refuse marketing slang; foreign names get a Russian descriptor; keep domain terms without a Russian equivalent; don't truncate foreign roots.

   Write clean Russian prose from the first draft. Don't "fix" AI-sounding or anglicism-heavy text afterwards.
2. Create meta file: `wp_temp action=write file=meta-ID.json content='...'`
3. Write JSONL with all place blocks + meta blocks (lead, intro, quick-wins, faq).
   Apply the podborka-editorial skill's rules to lead (hook formula), intro (context ladder),
   and quick-wins (routing axes). The "intro" line takes an optional `heading` sibling field
   (H2 keyword slot rendered between more and the intro paragraphs) — omit for no heading;
   what to put in it is also covered by podborka-editorial. Set it on ONE intro line — if
   multiple intro lines carry a heading, the last non-empty one silently wins.
4. See `_common.md` for JSONL data format
5. Approve when JSONL is complete

**Step 5: validate** (approval) — Render and validate:
```
wp_render_blocks places_file=... meta_file=... validate_level=strict   # renders to render_*.html and RETURNS html_file (the rendered HTML path)
```
Fix errors, re-render until 0 errors. Approve when clean.

**Step 6: create-draft** (approval, self-approved) — Build the post as a DRAFT and HOLD it unpublished. Do NOT flip `status=publish` and do NOT flush a publish cache in this step:
```
1. wp_post action=create title="..." categories=[ID] status=draft
2. wp_post action=update post_id=ID content_file=<html_file returned by step 5>  # the RENDERED HTML (NOT blocks_file / the collection JSON — wp_post rejects collection-format JSON)
3. wp_seo action=set post_id=ID title="..." description="..." focus_keyword="..."
4. wp_post action=update post_id=ID excerpt="≤150-char сок-first one-liner"  # MANDATORY — never skip; unset → WP auto-bloats a 300-500-char dek
5. wp_check_anglicisms post_id=ID project={PROJECT}
6. wp_audit_article post_id=ID → fix errors if any (now errors on empty/>200-char excerpt)
7. wp_image action=set_featured post_id=ID search_query="topic"
8. wp_manage_tags action=assign_date_tags
```
Then record the draft id and advance to the go-live gate (do NOT publish):
```
wf_approve workflow_id=ID approved=true data={"post_id": ID, "status": "draft"}
```
`post_id` MUST be a JSON number, not a string — the engine-owned publish step (below) consumes it directly and fails loudly on a missing/string value. A standalone run self-approves this step; an operator-gated run STOPS here at the next step (go-live).

**Step 7: go-live** (approval) — GO-LIVE GATE: approving this step AUTHORIZES publication, it does not perform it. The draft is built and held unpublished (`post_id` from step 6). Re-run `wp_audit_article` FRESH on that `post_id` — never trust a stale approval; if it is not clean, reject (`wf_approve approved=false`) and report. Once clean:
```
wf_approve workflow_id=ID approved=true
```
The ENGINE then publishes (`wp_post status=publish`) and flushes caches via two chained tool steps — do NOT call `wp_post`/`wp_flush_cache` manually here, the engine owns that now. If either step fails, the workflow ends `state=failed` (NOT published); `state=completed` now implies published. Withholding approval at go-live leaves the post a durable, unpublished draft (the engine holds the workflow at waiting_approval).

### Check status anytime

```
wf_status workflow_id=ID
```

### Cancel if needed

```
wf_cancel workflow_id=ID
```

## Key Rules

- `wp_enrich` is the primary research tool. `research` is fallback only.
- For images, use the three-step haiku-thumbnail flow from `_common.md` IMAGES section:
  `resolve_candidates` → spawn haiku Agent to select → `upload_selected`. Run per place during compose (step 4) before writing image_id to JSONL.
- Content rules and JSONL format: `_common.md`
