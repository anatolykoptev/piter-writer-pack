---
name: update-single
description: This skill should be used when the user asks to "update single article", "update historical date", "update place review", "обновить карточку места", "обновить историческую дату", "обновить обзор", or when the scanner returns content_type "historical-date" or "place-review". Handles single-entity articles that are NOT listicles.
argument-hint: "post_id=ID [project=piter]"
---

## Setup

Load deferred MCP tools (required before any tool calls):

    ToolSearch "+go-wp wp_prd scan temp render image post seo enrich audit research format tags flush check"
    ToolSearch "+go-search research smart web_url"

# Update Single Article

Update a single-entity article: historical date OR place review. Read `_common.md` for shared rules.

**This is NOT a listicle.** Do not use collection pipeline (no JSONL, no brief, no quick-wins). Work directly with Gutenberg blocks.

## Project selection

Project routing (`piter`=RU / `hully`=EN; ASK if ambiguous) and the Hully-specific notes live in `_common.md` (read every run). Pass `project={PROJECT}` to every `wp_*` call.

## Arguments

- `post_id` — WordPress post ID (required)
- `project` — project key (default: `piter`)

## Pipeline

### 1. AUDIT + TYPE DETECTION

```
wp_audit_article post_id=ID project={PROJECT}
wp_post action=get post_id=ID decompile=true project={PROJECT}
wp_seo action=get post_ids=[ID] project={PROJECT}
wp_format_spec category_id=CATEGORY project={PROJECT}
```

Determine the sub-type from decompiled data:
- **historical-date**: single "place" that is actually a date event, category 48 (История)
- **place-review**: single real venue with info (address, phone, website)

### 2. RESEARCH

#### For historical-date:
```
research query="[event] Санкт-Петербург история" depth=medium
```
Key questions:
- Are the historical facts accurate?
- Are there additional details to enrich the text?
- Is the illustration relevant and properly attributed?

#### For place-review:
```
wp_research_get name="Name" post_id=ID project={PROJECT}
wp_enrich mode=places data=[{"name":"Name","url":"https://..."}] project={PROJECT}
research query="Name Санкт-Петербург 2026" depth=medium
wp_research_save post_id=ID name="Name" paragraphs=[...] facts_used=[...] project={PROJECT}
```
Key questions:
- Is the venue still open?
- Current prices, schedule, phone, address?
- Any recent changes, renovations, new programs?

### 3. IMAGE

Every article MUST have at least one image with a caption. Use the three-step haiku-thumbnail flow:

```
1. wp_image action=resolve_candidates place_name="[subject]" query="[subject] Санкт-Петербург" \
       website="https://official-site.ru" max_results=8 project={PROJECT}
   -> returns {manifest_path, slug, available_count}

2. Spawn Agent model:"haiku" with prompt per _common.md IMAGES section:
   - target: 1 (single cover image)
   - haiku reads thumbs via vision, returns {"selected": [idx]}

3. wp_image action=upload_selected slug={slug} selected=[{idx}] alt_text="..." project={PROJECT}
   -> returns {image_ids: [media_id]}
```

**Caption is MANDATORY.** Describe what is specifically visible in the photo. Max 90 chars. Not generic.

### 4. COMPOSE

Build Gutenberg blocks directly (NOT JSONL). Use `wp_post action=update` with `blocks`.

#### Block structure for historical-date:
```json
[
  {"type": "lead", "text": "One sentence summary, 150-250 chars"},
  {"type": "more"},
  {"type": "image", "id": MEDIA_ID, "alt": "...", "caption": "Concrete photo description"},
  {"type": "paragraph", "text": "Main historical narrative, 200-400 chars"},
  {"type": "paragraph", "text": "Additional context or consequences, 200-400 chars"},
  {"type": "paragraph", "text": "Modern relevance or current state, 150-300 chars"}
]
```

Content rules for historical-date:
- **Lead**: what happened, when, where — inverted pyramid, 150-250 chars
- **Paragraphs**: 3-5 total, each 200-400 chars, factual, sourced
- **Tone**: objective historical narrative, no generic praise
- **MUST include**: specific dates, names, numbers
- **Image caption**: describe what the historical photo/illustration shows

#### Block structure for place-review:
```json
[
  {"type": "lead", "text": "What makes this place special, 150-250 chars"},
  {"type": "more"},
  {"type": "image", "id": MEDIA_ID, "alt": "...", "caption": "Concrete photo description"},
  {"type": "paragraph", "text": "First impression and atmosphere, 200-350 chars"},
  {"type": "paragraph", "text": "What to do/see/eat — specifics, 200-350 chars"},
  {"type": "paragraph", "text": "Practical info — when to go, how to get there, 200-350 chars"},
  {"type": "info", "fields": {"address": "...", "phone": "...", "website": "...", "price": "...", "schedule": "...", "metro": "..."}},
  {"type": "faq", "items": [{"q": "...", "a": "..."}]}
]
```

Content rules for place-review:
- **Lead**: unique selling point of the venue, 150-250 chars
- **Paragraphs**: 3-4 total, each 200-350 chars, 4+ information coordinates
- **Info block**: ALL available fields filled (address, phone, website, price, schedule, metro)
- **FAQ**: 2-4 practical questions visitors would ask
- **Image caption**: describe what's visible in the venue photo

### 5. UPDATE

```
wp_post action=update post_id=ID blocks='[...]' project={PROJECT}
wp_seo action=set post_id=ID title="..." description="..." focus_keyword="..." project={PROJECT}
wp_post action=update post_id=ID excerpt="150-200 char summary for search snippets" project={PROJECT}
wp_check_anglicisms post_id=ID project={PROJECT}
wp_manage_tags action=assign_date_tags project={PROJECT}
wp_manage_tags action=assign_by_keywords keywords={"focus_keyword": ["tag1", "tag2"], "city_keyword": ["Петербург"]} project={PROJECT}
# GUARD distinctive keys only (>=4 chars). Short abbr like «КТ»/«УЗИ» substring-pollute 1000s of posts (see _common.md PUBLISH). For a few known posts tag by post_id: wp_cli command = eval "wp_set_post_tags(<id>, ['Тег','Санкт-Петербург'], true);" (3rd arg: true=append, false=replace all).
```

SEO: title 50-60 chars with keyword, description 150-160 chars with CTA verb.

### 6. CONVERT TO PLACE (place-review only)

If this is a place-review (single venue with address in info block):

```
wp_post action=convert_to_place post_id=ID meta={"address":"...","phone":"...","website":"...","price":"...","hours":"..."} project={PROJECT}
```

This automatically:
- Changes post_type from `post` to `place`
- Adds 301 redirect via RankMath (old URL → new /places/ URL)
- Fills ACF fields (place_address, place_phone, etc.)

**Only convert if**: info block has at least address filled. Skip for historical-date.

### 7. AUDIT LOOP

```
wp_audit_article post_id=ID project={PROJECT}
```

**If errors remain** — fix and re-audit. Repeat until zero errors.
After clean audit:
```
wp_flush_cache project={PROJECT}
```
