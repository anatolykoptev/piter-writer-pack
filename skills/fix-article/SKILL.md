---
name: fix-article
description: This skill should be used when the user asks to "fix article", "fix errors in article", "исправить статью", "починить статью", "починить ошибки", "fix PRD tasks", "fix audit errors", or wants targeted fixes for specific issues in an existing WordPress article based on PRD task list.
argument-hint: "post_id=ID [project=piter]"
---

## Setup

Load deferred MCP tools (required before any tool calls):

    ToolSearch "+go-wp wp_prd scan temp render image post seo enrich audit research format tags flush check"
    ToolSearch "+go-search smart web_url"

# Fix Article

Targeted fix for specific issues in an existing article. Refer to `_common.md` for content rules and JSONL data format.

**Core principle**: always verify data freshness during fixes — update outdated information along the way. After publishing, audit the live article and keep iterating until zero errors remain.

## Project selection

Project routing (`piter`=RU / `hully`=EN; ASK if ambiguous) and the Hully-specific notes live in `_common.md` (read every run). Pass `project={PROJECT}` to every `wp_*` call.

## Arguments

- `post_id` — WordPress post ID (required)
- `project` — project key (default: `piter`)

## Pipeline

### 1. PRD + AUDIT

Generate task list, fetch current SEO, and get article structure:

```
wp_prd action=optimize post_id=ID project={PROJECT}
   -> /tmp/go-wp/{PROJECT}/prd-ID.json (prioritized task list)
wp_audit_article post_id=ID project={PROJECT}
wp_seo action=get post_ids=[ID] project={PROJECT}
wp_format_spec category_id=CATEGORY project={PROJECT}
wp_post action=get post_id=ID decompile=true project={PROJECT}
   -> /tmp/go-wp/{PROJECT}/collection-ID.json
   -> /tmp/go-wp/{PROJECT}/decompiled-places-ID.jsonl
```

Read `prd-ID.json` — it lists every task: which places need rewrite, what meta blocks are missing, acceptance criteria for each. This file is the work plan.

### 2. RESEARCH (per place from PRD tasks)

For each place with a task in PRD, verify it exists and collect fresh data. Even if the PRD task is cosmetic (e.g. short paragraph), still check the place is open and data is current.

```
1. wp_research_get name="Name" post_id=ID project={PROJECT}
   -> check L1 cache + L2 agent decisions
2. wp_enrich mode=places data=[{"name":"Name","url":"https://..."}] project={PROJECT}
   -> status (open/closed), JSON-LD facts, phone, prices, og:image
3. If enrich insufficient or no website:
   research query="Name City 2026" depth=medium
   web_url_read url="https://official-site.ru"
4. wp_research_save post_id=ID name="Name" paragraphs=[...] facts_used=[...] project={PROJECT}
```

Key questions per place:
- Is it open right now? Has it moved, renamed, or closed?
- Current prices, schedule, phone, address?
- What's special — any new programs, renovations, events?

**If a place is CLOSED** — find a replacement via `research query="альтернатива Name City"`, research it fully, use same rank.

### 3. IMAGES (per place missing image)

For places with `image_id=0` or audit warning about external/narrow images, run the three-step haiku-thumbnail flow:

```
1. wp_image action=resolve_candidates place_name="Name" query="Name город" \
       website="https://official-site.ru" max_results=8 project={PROJECT}
   -> downloads thumbnails to /tmp/go-wp/{PROJECT}/img-candidates/{slug}/
   -> returns {manifest_path, slug, available_count}

2. Spawn Agent model:"haiku" with prompt per _common.md IMAGES section:
   - pass thumbs dir path and place_name
   - target: 1 (cover)
   - haiku reads thumbs via vision, returns {"selected": [idx]}

3. wp_image action=upload_selected slug={slug} selected=[{idx}] alt_text="..." project={PROJECT}
   -> returns {image_ids: [media_id]}
4. Use media_id in JSONL: {"rank":N, "image_id": MEDIA_ID}
```

Source priority: official site **og:image FIRST** (og:image is idx 0 when `website=` is provided) -> Yandex Maps -> VK group. Min width 880px. If available_count=0 — retry with different query or without website, then flag if exhausted.

**Every image MUST have a caption** (`image_caption` in JSONL). Describe what is specifically visible in the photo — a concrete detail, not a generic description. Max 90 chars. See `_common.md` for examples.

Images from `collection-ID.json` auto-merge by place name. Only provide `image_id` when replacing.

### 4. COMPOSE

Write JSONL based on PRD tasks and research results. Partial update semantics — omit unchanged fields, they inherit from decompiled original.

**If fixing lead / intro / quick-wins**: read `~/.claude/skills/podborka-editorial/SKILL.md`
for the single-source opening-structure rules — do not restate them from memory.
`wp_format_spec.editorial_standard_ref` (from the `wp_format_spec` call in step 1) and PRD
`data_rules.lead_rule` / `data_rules.intro_rule` / `data_rules.brief_axes` all point to that
skill. See also `_common.md` "Opening Structure Standard" section (pointer only).

#### Meta blocks (if PRD requires changes):

```
wp_temp action=write file=places-ID.jsonl content='{"rank":"lead","text":"..."}' project={PROJECT}
wp_temp action=write file=places-ID.jsonl content='{"rank":"intro","text":"..."}' append=true project={PROJECT}
wp_temp action=write file=places-ID.jsonl content='{"rank":"quick-wins","heading":"Коротко о главном","items":["...","...","...","..."]}' append=true project={PROJECT}
```

#### Place blocks (one per place needing changes):

```
wp_temp action=write file=places-ID.jsonl append=true content='{"rank":N,"name":"...","feature":"...","paragraphs":["...","..."],"features":["<strong>Label:</strong> fact","...","..."],"info":{"price":"...","schedule":"..."},"image_caption":"Concrete description of what is in the photo"}' project={PROJECT}
```

#### FAQ block (if PRD requires):

```
wp_temp action=write file=places-ID.jsonl append=true content='{"rank":"faq","heading":"...","items":[{"q":"...","a":"..."},{"q":"...","a":"..."}]}' project={PROJECT}
```

#### Content rules summary:
- **Lead**: 150-250 chars (no spaces), hook + topic + count
- **Paragraphs**: 2 per place (3 for museums/parks), 150-350 chars, 4+ information coordinates
- **Features**: 2-4 per place (validator min 2, max 4; 3 = default, never pad), `<strong>Label:</strong> fact`, 40-70 chars (max 100 runes)
- **Feature descriptor** (`feature` field): max 25 runes, what the place IS
- **Info keys**: address, phone, website, price, schedule, metro. Use `schedule`, never `hours`
- **FAQ**: 3-6 items, answers 120-300 chars (no spaces)
- **Forbidden in paragraphs**: addresses, phones, websites, exact prices duplicating info block
- **Antipatterns**: no generic praise ("уютная атмосфера") — concrete facts with numbers or names

### 5. VALIDATE

```
wp_temp action=compile file=places-ID.jsonl project={PROJECT}
wp_render_blocks places_file=places-ID.jsonl meta_file=meta-ID.json validate=true validate_level="lenient" save_to=/tmp/go-wp/{PROJECT}/collection-ID-compiled.json project={PROJECT}
```

If errors: fix with `wp_temp action=update rank=N ...` → re-compile → re-render. Do not publish with errors.

### 6. PUBLISH + AUDIT LOOP

```
wp_post action=update post_id=ID content_file=<html_file returned by wp_render_blocks> project={PROJECT}   # RENDERED HTML, not blocks_file/collection JSON (wp_post rejects it). TRUNCATION: JSONL must hold ALL ranks; verify place_count before/after (see _common.md Partial updates).
wp_seo action=set post_id=ID title="..." description="..." focus_keyword="..." project={PROJECT}
wp_post action=update post_id=ID excerpt="150-200 char summary for search snippets" project={PROJECT}
wp_check_anglicisms post_id=ID project={PROJECT}
wp_image action=set_featured post_id=ID search_query="topic" project={PROJECT}
wp_manage_tags action=assign_date_tags project={PROJECT}
wp_manage_tags action=assign_by_keywords keywords={"focus_keyword": ["tag1", "tag2"], "city_keyword": ["Петербург"]} project={PROJECT}
# GUARD distinctive keys only (>=4 chars). Short abbr like «КТ»/«УЗИ» substring-pollute 1000s of posts (see _common.md PUBLISH). For a few known posts tag by post_id: wp_cli command = eval "wp_set_post_tags(<id>, ['Тег','Санкт-Петербург'], true);" (3rd arg: true=append, false=replace all).
wp_flush_cache project={PROJECT}
```

SEO: title 50-60 chars with keyword, description 150-160 chars with CTA verb.

#### Convert to place (place-review only)

If content_type is `place-review` (single venue with address in info block):

```
wp_post action=convert_to_place post_id=ID meta={"address":"...","phone":"...","website":"...","price":"...","hours":"..."} project={PROJECT}
```

Automatically changes post_type, adds RankMath 301 redirect, fills ACF fields. **Only if** info block has at least address.

#### Mandatory post-publish audit

After publishing, run a final audit on the live article:

```
wp_audit_article post_id=ID project={PROJECT}
```

**If the audit returns errors** — fix them immediately:
1. Read the error list, identify what needs changing
2. Go back to the relevant pipeline step (COMPOSE/IMAGES/SEO)
3. Fix, validate, re-publish
4. Run `wp_audit_article` again
5. **Repeat until the audit returns zero errors.** Do not stop with remaining issues.
