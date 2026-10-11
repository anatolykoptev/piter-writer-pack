---
name: update-facts
description: This skill should be used when the user asks to "update fact article", "update tips article", "обновить подборку фактов", "обновить советы", "update records", "обновить рекорды", or when the scanner returns content_type "fact-listicle". Handles listicle articles where items are facts, tips, or records — NOT venues with addresses.
argument-hint: "post_id=ID [project=piter]"
---

## Setup

Load deferred MCP tools (required before any tool calls):

    ToolSearch "+go-wp wp_prd scan temp render image post seo enrich audit research format tags flush check"
    ToolSearch "+go-search research smart web_url"

> **Note**: substitute `{CITY}` based on project — `Санкт-Петербург` for piter, `San Francisco` (or topic-specific CA city) for hully.

# Update Fact Listicle

Update a fact/tip/record listicle where items are NOT venues. Read `_common.md` for shared rules.

**Key difference from place-listicle:** No info blocks, no features, no CTA. Items are facts, tips, records, or list entries — they don't have addresses/phones/prices.

## Project selection

Project routing (`piter`=RU / `hully`=EN; ASK if ambiguous) and the Hully-specific notes live in `_common.md` (read every run). Pass `project={PROJECT}` to every `wp_*` call.

## Arguments

- `post_id` — WordPress post ID (required)
- `project` — project key (default: `piter`)

## Pipeline

### 1. PRD + AUDIT

```
wp_prd action=optimize post_id=ID project={PROJECT}
wp_audit_article post_id=ID project={PROJECT}
wp_seo action=get post_ids=[ID] project={PROJECT}
wp_format_spec category_id=CATEGORY project={PROJECT}
wp_post action=get post_id=ID decompile=true project={PROJECT}
   -> /tmp/go-wp/{PROJECT}/collection-ID.json
   -> /tmp/go-wp/{PROJECT}/decompiled-places-ID.jsonl
```

Read `prd-ID.json` — task list. For fact-listicles, tasks will be mostly `rewrite` (missing/short paragraphs) and `caption` (missing image captions).

### 2. RESEARCH (per item from PRD tasks)

For each item (fact/tip/record) needing update, verify the information is still accurate:

```
research query="[fact topic] 2026" depth=medium
web_url_read url="https://source-url.ru"
```

Key questions per item:
- Is this fact/record still current? Has it been superseded?
- Are there newer numbers, dates, or details?
- Is the source still valid?

**If a fact is outdated or wrong** — update with current information and cite the source.

### 3. IMAGES (per item missing image)

For items with `image_id=0` or no image, use the three-step haiku-thumbnail flow:

```
1. wp_image action=resolve_candidates place_name="[item topic]" query="[item topic] {CITY}" \
       max_results=8 project={PROJECT}
   -> returns {manifest_path, slug, available_count}

2. Spawn Agent model:"haiku" with prompt per _common.md IMAGES section:
   - target: 1 (cover image per fact item)
   - haiku reads thumbs via vision, returns {"selected": [idx]}

3. wp_image action=upload_selected slug={slug} selected=[{idx}] alt_text="..." project={PROJECT}
   -> returns {image_ids: [media_id]}
```

**Caption is MANDATORY for every image.** Describe what the photo shows concretely. Max 90 chars.

### 4. COMPOSE

Write JSONL — partial update semantics.

#### JSONL structure for fact items (NO info, NO features, NO cta):

```
wp_temp action=write file=places-ID.jsonl content='{"rank":"lead","text":"Hook sentence, 150-250 chars"}' project={PROJECT}
wp_temp action=write file=places-ID.jsonl content='{"rank":"intro","text":"Context paragraph, 150-350 chars"}' append=true project={PROJECT}
wp_temp action=write file=places-ID.jsonl content='{"rank":N,"name":"Fact/Record Title","paragraphs":["Factual paragraph 200-350 chars with sources and numbers"],"image_caption":"What the photo shows"}' append=true project={PROJECT}
```

Content rules for fact-listicle:
- **Lead**: topic + count + hook, 150-250 chars
- **Intro**: 1-2 paragraphs setting context, 150-350 chars each
- **Item paragraphs**: 1-2 per item, 200-350 chars, factual with sources
- **NO info block** — items are not venues
- **NO features** — items don't have highlight bullets
- **NO CTA** — no booking/reservation links
- **Image caption**: describe what the photo shows, not the fact itself

### 5. VALIDATE

```
wp_temp action=compile file=places-ID.jsonl project={PROJECT}
wp_render_blocks places_file=places-ID.jsonl meta_file=meta-ID.json validate=true validate_level="lenient" save_to=/tmp/go-wp/{PROJECT}/collection-ID-compiled.json project={PROJECT}
```

If errors: fix with `wp_temp action=update rank=N ...` → re-compile → re-render.

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

SEO: title 50-60 chars, description 150-160 chars with CTA verb.

#### Mandatory post-publish audit:

```
wp_audit_article post_id=ID project={PROJECT}
```

**If errors remain** — fix immediately, re-publish, re-audit. Repeat until zero errors.
