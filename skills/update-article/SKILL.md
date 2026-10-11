---
name: update-article
description: Full refresh of an existing WordPress article or place collection — PRD generates tasks, then research every place, verify status, enrich data, find images, rewrite content. Triggers on "update article", "refresh article", "update collection", "обновить подборку", "актуализировать подборку", "обновить статью", "обновить материал", "obnovit statyu", "obnovit material".
argument-hint: "[post_id=ID] [project=piter]"
---

# Update Article

Full pipeline for updating an existing article. Read `_common.md` for content rules and JSONL data format.

## Project selection

Project routing (`piter`=RU / `hully`=EN; ASK if ambiguous) and the Hully-specific notes live in `_common.md` (read every run). Pass `project={PROJECT}` to every `wp_*` call.

## Arguments

- `post_id` — WordPress post ID (if known)
- `project` — project key (default: `piter`)

If no post_id given, use automated selection.

## Setup

Load deferred MCP tools (required before any tool calls):

    ToolSearch "+go-wp wp_prd wp_scan wp_temp wp_render_blocks wp_image wp_post wp_seo wp_enrich wp_audit_article wp_research wp_research_get wp_research_save wp_format_spec wp_manage_tags wp_flush_cache wp_check_anglicisms"
    ToolSearch "+go-search research web_url_read"

## Pipeline

### 1. SELECT + PRD

**If post_id provided:**
```
wp_prd action=optimize post_id=ID project={PROJECT}
   -> /tmp/go-wp/{PROJECT}/prd-ID.json (prioritized task list)
wp_format_spec category_id=CATEGORY project={PROJECT}
```

**If no post_id — automated selection:**
```
wp_scan action=refresh project={PROJECT}
wp_scan action=next project={PROJECT}
   -> gives post_id, then:
wp_prd action=optimize post_id=ID project={PROJECT}
```

### 2. AUDIT

```
wp_audit_article post_id=ID project={PROJECT}
wp_post action=get post_id=ID decompile=true project={PROJECT}
   -> /tmp/go-wp/{PROJECT}/collection-ID.json
   -> /tmp/go-wp/{PROJECT}/decompiled-places-ID.jsonl
wp_seo action=get post_ids=[ID] project={PROJECT}
```

Read `prd-ID.json` — it lists every task with type (rewrite/add/fix), scope (place/collection), issues, acceptance criteria, priority, and dependencies. **This is your work plan.**

### 3. RESEARCH

The article's existing places may be stale or closed (the Feb-2026 migration left many with 2016-era data). Get the current ground truth from the SPECIALIZED tools before trusting any existing place — do NOT lead with raw `go-search`.

**Step 3a — discover the current canonical set (collection-level, FIRST):**

```
wp_research topic="<collection topic, e.g. аквапарки Санкт-Петербурга>" mode=places count=10 project={PROJECT}
   -> current places with venue_verified + status (status="permanently_closed"/"temporarily_closed",
      from the 2GIS+Yandex maps checker), plus suggested_top + replacement candidates.
```

`wp_research` is the STATUS AUTHORITY: a place it marks `permanently_closed` — or that has simply vanished from every current competitor article — is closed. Drop or replace it (see closed-venue rule below).

**Step 3b — verify + enrich each place you keep:**

```
1. wp_research_get name="Name" post_id=ID project={PROJECT}
   -> L1 (enrich cache) + L2 (agent decisions); skip re-fetch on a fresh hit
2. wp_enrich mode=places data=[{"name":"Name","url":"https://..."}] project={PROJECT}
   -> facts (JSON-LD/regex), phone, price, og:image, lat/lon, and status — resolved via the SAME
      2GIS+Yandex maps checker wp_research uses (go-search primary, scrapers fallback).
3. If enrich is insufficient / no website:
   research query="Name City 2026" depth=medium
   web_url_read url="https://official-site.ru"
4. wp_research_save post_id=ID name="Name" paragraphs=[...] facts_used=[...] facts_rejected={...} project={PROJECT}
```

**Enrich match caution (wrong-entity trap):** `wp_enrich` matches by NAME, so an ambiguous name can match the WRONG venue and return ITS (often "active") status — e.g. querying "Аквапарк в ЛДМ" can return "LDM. Новая сцена, театр". If `facts.low_confidence` is set, or `facts.place_name` diverges from the name you queried, DO NOT trust the status/address — re-query with a more specific name (+ address), cross-check against the `wp_research` result, or drop the place. Never publish facts from a low-confidence match.

**Key questions per place:** Open right now? Moved / renamed / closed? Current price, schedule, phone, address? Anything new (renovation, new program)?

**If a place is CLOSED** — replace it from `wp_research`'s `suggested_top` / candidate list (verified, current), reusing the same rank. Only fall back to `research query="альтернатива Name City"` if `wp_research` has no suitable replacement. Never invent a replacement; an empty field you flag beats a fabricated one.

### 4. IMAGES (per place)

Every place needs an image. Check existing `image_id` — if 0 or audit warns about external/narrow image, run the three-step haiku-thumbnail flow:

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

Images from `collection-ID.json` auto-merge by place name. Only provide `image_id` if replacing.

### 5. COMPOSE

Write JSONL to `/tmp/go-wp/{PROJECT}/places-ID.jsonl` based on PRD tasks and research results.

**Read TWO references BEFORE composing and apply them WHILE writing:**

1. `~/.claude/skills/humanizer/SKILL.md` — kill AI-tells (vary sentence length, no em-dash overuse, no rule-of-three, no inflated symbolism, no vague attributions, no filler, no stacked promotional adjectives).
2. `_common.md` sections "Russian-language hygiene" and "Foreign proper nouns: examples" — six rules: prefer Russian when it means the same (ивент→мероприятие, локация→место, лук→образ, вайб→атмосфера); keep long-loans (концерт, ресторан); refuse marketing slang; prefix foreign names with a Russian descriptor (фестиваль Stereoleto); keep domain terms without a Russian equivalent; don't truncate foreign roots.

`wp_check_style` runs at PUBLISH and catches what slipped through, but writing AI-tells / anglicisms and patching them afterwards leaves stylistic seams. Compose clean Russian prose from the first draft.

**This is a partial update** — omit unchanged fields, they inherit from decompiled original.

**Point fixes** (change one place without rewriting entire file):

    wp_temp action=update rank=5 file=places-ID.jsonl content='{"paragraphs":["new p1","new p2"]}' project={PROJECT}

#### Meta blocks (write first):

```
wp_temp action=write file=places-ID.jsonl content='{"rank":"lead","text":"..."}' project={PROJECT}
wp_temp action=write file=places-ID.jsonl content='{"rank":"intro","text":"...","heading":"Optional H2 keyword slot (podborka-editorial skill covers what to put here); omit for no heading. Set on ONE intro line — if several carry it, the last non-empty one silently wins."}' append=true project={PROJECT}
wp_temp action=write file=places-ID.jsonl content='{"rank":"quick-wins","heading":"Коротко о главном","items":["...","...","...","..."]}' append=true project={PROJECT}
```

#### Place blocks (append, one per place):

```
wp_temp action=write file=places-ID.jsonl append=true content='{"rank":N,"name":"...","feature":"...","paragraphs":["...","..."],"features":["<strong>Label:</strong> fact","...","..."],"info":{"price":"...","schedule":"..."},"image_id":MEDIA_ID,"image_caption":"Concrete description of what is in the photo"}' project={PROJECT}
```

#### FAQ block (append last):

```
wp_temp action=write file=places-ID.jsonl append=true content='{"rank":"faq","heading":"...","items":[{"q":"...","a":"..."},{"q":"...","a":"..."}]}' project={PROJECT}
```

#### Content rules:
- **Opening-structure standard** (lead / intro / brief): single source of truth is the
  `~/.claude/skills/podborka-editorial/SKILL.md` skill — load it locally before writing.
  `wp_format_spec.editorial_standard_ref` and PRD `data_rules.lead_rule` / `.intro_rule` /
  `.brief_axes` all point here, they are not the rules themselves. See also
  `_common.md` "Opening Structure Standard" (pointer only, same doctrine).
- **Lead**: 150-250 chars (no spaces). Hook opener — sentence one carries a fact/scene/tension the
  headline could not; full doctrine and the 6 named hook patterns live in the
  podborka-editorial skill — do not restate them here.
- **Intro**: 1-2 paragraphs, 150-350 chars each. Context ladder: landscape → what collected → methodology.
  See the podborka-editorial skill for the ladder and intent-based approaches.
- **Brief** (quick-wins): 4 items, routing axes 🏆/💰/🌟/📍 per the podborka-editorial skill.
  Every item = named place + concrete number or reason.
- **Paragraphs**: 2 per place (3 for museums/parks), 150-350 chars, 4+ information coordinates
- **Features**: 2-4 per place (validator min 2, max 4; 3 = default, never pad), `<strong>Label:</strong> fact`, 40-70 chars (max 100 runes)
- **Feature descriptor** (`feature` field): max 25 runes, what the place IS
- **Info**: address, phone, website, price, schedule, metro. No `hours` — always `schedule`
- **FAQ**: 3-6 items, answers 120-300 chars (no spaces)
- **Forbidden in paragraphs**: addresses, phones, websites, exact prices duplicating info block
- **Antipatterns**: no generic praise — concrete facts with numbers or names

### 6. VALIDATE

```
wp_temp action=compile file=places-ID.jsonl project={PROJECT}
wp_render_blocks places_file=places-ID.jsonl meta_file=meta-ID.json validate_level="lenient" save_to=/tmp/go-wp/{PROJECT}/collection-ID-compiled.json project={PROJECT}
```

If errors: fix JSONL (`wp_temp action=update rank=N ...`) -> re-compile -> re-render. Do not publish with errors.

### 7. PUBLISH

```
wp_post action=update post_id=ID content_file=<html_file returned by wp_render_blocks> project={PROJECT}   # RENDERED HTML, not blocks_file/collection JSON (wp_post rejects it). TRUNCATION: JSONL must hold ALL ranks; verify place_count before/after (see _common.md Partial updates).
wp_seo action=set post_id=ID title="..." description="..." focus_keyword="..." project={PROJECT}
wp_post action=update post_id=ID excerpt="≤150-char сок-first one-liner (names+dates+count)" project={PROJECT}
# MANDATORY — never skip. Unset excerpt → WordPress auto-bloats a 300-500-char dek; wp_audit_article errors on empty/>200.
wp_check_anglicisms post_id=ID project={PROJECT}
wp_audit_article post_id=ID project={PROJECT}
   -> If errors: fix JSONL → wp_temp update → re-compile → re-render → re-update → re-audit
   -> Repeat until 0 errors
wp_flush_cache project={PROJECT}
```

SEO: title 50-60 chars with keyword, description 150-160 chars with CTA verb.

After publish:
```
wp_image action=set_featured post_id=ID search_query="topic" project={PROJECT}
wp_manage_tags action=assign_date_tags project={PROJECT}
wp_manage_tags action=assign_by_keywords keywords={"focus_keyword": ["tag1", "tag2"], "city_keyword": ["Петербург"]} project={PROJECT}
# GUARD distinctive keys only (>=4 chars). Short abbr like «КТ»/«УЗИ» substring-pollute 1000s of posts (see _common.md PUBLISH). For a few known posts tag by post_id: wp_cli command = eval "wp_set_post_tags(<id>, ['Тег','Санкт-Петербург'], true);" (3rd arg: true=append, false=replace all).
```
