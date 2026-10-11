# Common Rules

Shared rules for all content skills. Each skill includes this file by reference.

## Setup

**Pass `project={PROJECT}` to every `wp_*` tool call.** Temp files: `/tmp/go-wp/{PROJECT}/`.

| Server | Tools | Note |
|--------|-------|------|
| **go-wp** | `wp_post`, `wp_scan`, `wp_prd`, `wp_format_spec`, `wp_research`, `wp_enrich`, `wp_image`, `wp_temp`, `wp_render_blocks`, `wp_seo`, `wp_audit_article`, `wp_research_get`, `wp_research_save`, `wp_check_anglicisms`, `wp_flush_cache`, `wp_manage_tags` | All require `project={PROJECT}` |
| **go-search** | `research`, `web_url_read` | No `project` needed |

## Project selection

This skill supports multiple WordPress projects. Pick the right one before proceeding:

- **`project=piter`** — Russian content for piter.now. Triggered by: Russian-language prompt, mentions of Санкт-Петербург / СПб / Петербург / Москва / Россия / Russian topics.
- **`project=hully`** — English content for hully.day (California travel). Triggered by: English-language prompt, mentions of California / SF / LA / San Francisco / New York / US travel.

If the prompt is ambiguous, ASK the user before proceeding — do not silently pick a default.

## Hully-specific notes

- `wp_post` for hully ALWAYS creates draft (status=draft) during the first 30 days of hully content pipeline. Do not override.
- No SSH available on hully — tools requiring SSH (convert_to_place, ACF autofill, RankMath SSH actions) will return CapabilityError. Skip those steps on hully.
- Image search uses Openverse + Pexels only (no oxbrowser / no 2GIS / no Yandex).

## Content Type Routing

The scanner classifies articles by `content_type`. Use the matching skill:

| content_type | Skill | When |
|-------------|-------|------|
| `place-listicle` | `/update-article` or `/fix-article` | Collection of 2+ places with venue info |
| `fact-listicle` | `/update-facts` | Collection of tips/facts/records without venue info |
| `historical-date` | `/update-single` | Historical date article (category: История) |
| `place-review` | `/update-single` | Review of a single venue |
| `news` | `/news-pipeline` | News article |
| `advertorial` | Skip | Sponsored content — do not auto-update |

## Role

You write content that makes people want to go outside. No cliches, no generic praise — concrete facts with numbers, names, and insider details.

**Formula**: 60% facts + 20% specific details + 20% local flavor.

## Content Rules

### Paragraphs

Each paragraph: **150-350 chars** (no spaces).

**Paragraph count norm: 2–3 per place.** A 4th paragraph is allowed only when it carries a load-bearing fact that cannot be condensed into the first three — never as split-overflow of a long paragraph (condense instead). More than 4 is always a defect; the validator blocks it (`E2b`, vHigh).

**Compose each place as one coherent take, then split** into 2-3 paragraphs where the thought naturally turns — not into fixed "opener / logistics" roles. Output is still 2-3 paragraph strings, each 150-350 no-space; the split falls differently for each place.

**Must contain 4+ of 6 information coordinates** (≥2 for pure-service items). Coordinate check is **advisory/non-blocking** — the validator emits a medium warning (W5) but never blocks publish.

> The validator detects coordinates **semantically** (embedding similarity). Its 6
> internal types are `factual, practical, sensory, dynamic, contextual, narrative`
> — that is what `wp_audit_article` reports as "missing". The table below is a
> writing heuristic: pack each paragraph with concrete, varied dimensions (place,
> time, price, quantity, sensory detail, outcome) and you clear 4+ naturally.

| Coordinate | Example |
|-----------|---------|
| Spatial | "7 min walk from Nevsky Prospekt" |
| Temporal | "Free entry on Wednesdays after 18:00" |
| Economic | "Business lunch 1200 rub on weekdays" |
| Quantitative | "Groups up to 8 kids" |
| Dynamic | "Terrace in summer, fireplace in winter" |
| Resultative | "After a month kids perform on stage" |

**Forbidden in paragraphs** (goes to info block): addresses, phones, websites, schedule, exact prices that duplicate info block.

> **Hard defect (vHigh, blocks strict render):** repeating phone, address, website, or exact price from the info block verbatim in paragraph text. The validator flags this as `W12`. Allowed: price mentions for context ("from 180 rub"), numbers ("7 minutes", "15 kids"). Paragraph content spec (6 coordinates, 60/20/20, honest minus for TOP-3) is in `docs/project/COLLECTION.xml` + `templates.md`.

### Features

**2–4 per place** (the validator `validate.go` enforces min 2, max 4; 3 is the house default — never pad to a count). Format: `<strong>Label:</strong> concrete fact`.
- 40-70 chars each (max 100 runes)
- Must be specific: name, number, or unique detail
- Bad: "Experienced teachers" -> Good: "Teacher Maria Ivanova — European championship medalist"

### Info block keys

| Key | What | Example |
|-----|------|---------|
| `address` | Street address | "Nevsky pr., 28" |
| `phone` | Phone with country code | "+7 (812) 602-23-46" |
| `website` | URL | "https://example.ru" |
| `price` | Price or range | "Adults 600 rub, kids 300 rub" |
| `schedule` | Working hours | "10:00-18:00, Mon closed" |
| `metro` | Nearest metro | "Nevsky Prospekt" |

Do NOT use `hours` — always `schedule`. Custom keys allowed.

Schedule: plain text, no sub-labels. Bad: "park: 9:00-20:00, palace: 10:00-18:00". Good: "9:00-20:00 (park), 10:00-18:00 (palace, Mon closed)".

### Antipatterns

| Bad | Good |
|-----|------|
| "Convenient location" | "7 min from Nevsky Prospekt metro on foot" |
| "Experienced teachers" | "Teacher Maria Ivanova — European medalist" |
| "Cozy atmosphere" | "6 tables, window seats face Fontanka" |
| "Wide selection" | "42 craft beers on tap, 12 local breweries" |
| "Unique place" | "The only husky nursery within city limits — 23 dogs" |

### Warmth — value-led, concrete, never a promised result

Write to the reader's stake, not the spec sheet. Frame each fact through what the reader fears or hopes, then anchor it in the number/name. **Warmth is a reporting act, not a tone — it comes from naming the reader's situation in concrete, checkable words, never from adjectives about the venue's or your own virtue** («с заботой к каждому», «лучшие центры города» = water). Show the situation, don't narrate the reader's feelings («родителю важно одно» ✗); ground abstract warmth in real фактура («видно по пробникам», not «видно, что движется»). Test any warm phrase: delete it — if no checkable fact is lost, it was water. Warmth lives in the SELECTION and ORDER of facts, not decoration; it relaxes no gate above (char counts, hook lead, banned mood-openers all still bind).

**Every example below shows the SHAPE of warm copy, NOT pre-approved facts — every concrete value still requires research (see the RESEARCH stage).**

- **Frame through the reader's GOAL/STAKE, never a promised RESULT.** «когда до ЕГЭ год, а по профильной тройка» ✓ names the stake; «поступит без репетиторов» / «избавит от стеснения» ✗ promise an unverifiable result (fabrication-adjacent).
- **Vary the entry across places — choose the opening move by the place's single most distinctive fact, not a house template.** A dozen-plus openers in the same mould («Если…», «Когда…») read as a machine. Rotate by what's distinctive: a stake-condition (who it's for / what problem), a hard number (cheapest / biggest / oldest), the named subject (a specialization), a contrast with the category, or a concrete practice. Can't pick a move → you haven't found what's distinctive (the failure the template hides). No move more than ~3-4 in a row; never the same first word twice running.

**Reviews → facts.** Reviews often bury a concrete, checkable detail under a vague rating. LIFT the detail the reviewer actually states and drop the vague summary — never manufacture a detail the source does not give. If a review only says «отлично», you have no fact; leave it. (The arrow below means "extract from the review text", NOT "render the sentiment as a plausible scene".)

- review says «чисто, дети в сменке, зал светлый» → write «занятия в сменной обуви, светлый зал» (not the bare «чисто»)
- review says «дочка после занятия не уходила, дорепетировала» → write «дети остаются дорепетировать после занятия»
- review says «логопед разговорил молчавшего сына» → write «работает с неговорящими детьми» — the verifiable specialty, NOT «разговорит вашего» (a promised result)
- one vague «хорошее обслуживание» with nothing concrete behind it → no fact, write nothing

**Cliché → concrete.** Replace every stock phrase with a concrete, checkable detail (a concrete sensory detail IS a fact — allowed; a mood adjective is not):

| Instead of | Write a concrete detail like |
|---|---|
| удобное расположение | «7 минут пешком от метро» · «первый этаж — заходите с коляской» · «во дворе тихо, но до Невского 3 минуты» |
| опытные педагоги | named person + credential: «логопед-дефектолог, стаж 12 лет» · «тренер воспитал 3 КМС» |
| современное оборудование | «зеркальные стены на всю высоту» · «тёплый пол — занимаются босиком» · «интерактивные доски» |
| интересные занятия | «запись на 2 месяца вперёд» · «группы набраны до сентября» · «у педагога лист ожидания» |
| уютная атмосфера | «мягкие пуфы, где родители ждут за капучино» · «стены расписаны героями мультфильмов» · «живой камин с октября по март» |
| качественная еда | «тесто замешивают каждое утро» · «рыбу привозят из Мурманска дважды в неделю» · «шеф пробует каждое блюдо перед подачей» |

**Warm place example (children's centre) — stake-led, two paragraphs, every claim sourced:**

- «В центре «Умка» малыши от года занимаются по системе Монтессори: деревянные игрушки, сенсорные коробки, тёплый пол и ни одного экрана. Педагог раскладывает материалы по росту ребёнка, в группе не больше шести человек, занятие идёт сорок пять минут без спешки и очередей.»
- «Есть утренние группы для тех, кто работает, и продлёнка до семи вечера. Все материалы входят в стоимость, докупать ничего не нужно, а сменную обувь выдают на месте. Начать можно с пробного занятия — посмотреть, как ребёнок входит в группу и идёт ли на контакт.»

### Humanizer (write-time, not post-hoc)

Read `~/.claude/skills/humanizer/SKILL.md` once per session before writing any place paragraph. Its rules apply WHILE you compose, not after — fixing AI-tells in a second pass leaves stylistic residue that readers and Google still detect.

Quick checklist (full version in the skill):
- vary sentence length (don't write 3 sentences of similar size in a row)
- no em-dash overuse (one per paragraph max)
- no rule-of-three lists for emphasis ("концерты, фестивали, выставки")
- no inflated symbolism ("в самом сердце города", "настоящая жемчужина")
- no vague attributions ("многие считают", "по мнению экспертов")
- no filler phrases ("стоит отметить, что", "важно понимать")
- no stacked promotional adjectives ("уникальный, незабываемый, потрясающий")
- write the kind of paragraph a senior journalist would write on the first pass

This is COMPLEMENTARY to `wp_check_style` (FZ-168 anglicism / passive voice linter) which runs at PUBLISH. Style-linter catches foreign loanwords; humanizer prevents AI-tells from being written at all.

### Russian-language hygiene

Six rules to follow while composing — keep prose clean Russian, don't
patch later:

1. **When a Russian word means the same thing, use it.**
   Test: would a regular reader without marketing exposure understand
   the Russian version equally? If yes, use Russian. "ивент" loses to
   "мероприятие". "локация" loses to "место". "лук" loses to "образ".
   "вайб" loses to "атмосфера". "хайп" loses to "ажиотаж".

2. **Long-loans that are normal Russian — keep.**
   Концерт, ресторан, фестиваль, спектакль, музей, кафе, метро,
   театр — these read as Russian. Don't try to "translate" them.

3. **Refuse marketing slang and recent English calques.**
   Words that exist only because someone copied an English marketing
   term: ивент, лайн-ап, букинг, нейм, кейс, гайд, лайфхак, челлендж,
   мейк, лук, хайп, кэжуал, фуд-корт, опен-эйр, ритейл, юзер,
   топ-N. Each has a normal Russian equivalent — write that.

4. **Foreign proper nouns: prefix with a Russian descriptor.**
   "Stereoleto" → "фестиваль Stereoleto". "Queen" → "группа Queen".
   "Joe Lynn Turner" → "вокалист Джо Линн Тёрнер". "Dance Open" →
   "фестиваль Dance Open". The reader must learn what kind of thing
   it is from the Russian word; the foreign name then identifies it.

5. **Domain term with no Russian equivalent — keep.**
   "Перформанс" in contemporary-art context, "софт" / "фреймворк" in
   IT, "DJ-сет" in club coverage. Test: would translating lose
   precision or sound silly? Then keep the foreign term.

6. **Don't truncate foreign roots.**
   Write "фестиваль", not "фест". "Макияж", not "мейк". Short forms
   read as slang.

`wp_check_style` runs at publish and catches violations against the
~10K-entry dictionary (`gigiena-teksta/dictdata/anglicisms.json`) —
but post-fixing leaves stylistic seams. Apply the six rules during
the first draft.

### Foreign proper nouns: examples

Concrete applications of rule #4 above.

| Bad | Good |
|-----|------|
| "Dance Open" | "Фестиваль Dance Open" |
| "White Nights Film Festival" | "Кинофестиваль White Nights Film Festival" |
| "Queen" | "Группа Queen" |
| "Joe Lynn Turner" | "Вокалист Джо Линн Тёрнер" |

- Russian descriptor (фестиваль, концерт, группа, спектакль) always precedes the foreign name.
- Latin script is allowed after the descriptor — no need to transliterate established names.
- Applies in H3 headings too: "Фестиваль Dance Open", not just "Dance Open".

### Quality test

Before finishing each place:
1. Would the reader want to go there after reading?
2. Are there 4+ information coordinates?
3. Is there at least one insider detail or surprising fact?
4. Does the text follow the 60/20/20 formula?

## Opening Structure Standard

<!-- EDITORIAL_STANDARD_REF: ~/.claude/skills/podborka-editorial/SKILL.md — do not duplicate prose here -->

The **single source of truth** for the opening-structure editorial standard (lead hook,
intro context ladder, «Коротко о главном» brief routing axes) is the **`podborka-editorial`
skill**, at `~/.claude/skills/podborka-editorial/SKILL.md`. It does not live in this repo —
load it locally before writing any place-listicle opening. Do not write the opening from
memory or restate its prose here or anywhere else in go-wp.

`wp_format_spec` returns `editorial_standard_ref` and `wp_prd`'s `data_rules` surfaces
`lead_rule` / `intro_rule` / `brief_axes` — all four are the same pointer string to the
skill above, not the rules themselves.

**The opening is one descent, not two exercises.** Lead and intro are two rendered blocks
(the lead sits before the `wp:more` cut), but write them as one continuous opening and cut
at the natural reasoning joint — see the skill for the descent order and the stake hinge.

## JSONL Data Format

### Meta blocks (string ranks)

```jsonl
{"rank":"lead","text":"150-250 chars no spaces. See Opening Structure Standard above for formulas."}
{"rank":"intro","text":"First intro paragraph, aim 150-350 chars (writing heuristic — not validator-enforced; only the lead has a hard 250-char ceiling). See Opening Structure Standard above for the context ladder.","heading":"Optional H2 keyword slot, rendered between more and the intro paragraphs. Empty/omitted = no heading. What to put here is covered by the podborka-editorial skill, not restated here. Set it on ONE intro line — if multiple intro lines carry a heading, the last non-empty one silently wins."}
{"rank":"intro","text":"Second intro paragraph, aim 150-350 chars (writing heuristic, not enforced)."}
{"rank":"quick-wins","heading":"Korotko o glavnom","items":["🏆 Лучшее: Place — reason","💰 Доступное: Place от N₽","🌟 Новинка: Place открылось когда","📍 У метро: Place в N минутах от Станция"]}
{"rank":"faq","heading":"FAQ heading","items":[{"q":"Question?","a":"Answer 120-300 chars (no spaces). Aim ~150-250 for quality."}]}
```

### Place blocks (numeric ranks)

```jsonl
{"rank":1,"name":"Place Name","feature":"descriptor","paragraphs":["p1","p2"],"features":["<strong>Label:</strong> fact","<strong>Label:</strong> fact","<strong>Label:</strong> fact"],"info":{"address":"...","phone":"+7...","website":"https://...","price":"...","schedule":"..."},"image_id":54419,"cta_text":"Button text","cta_url":"https://..."}
```

### Field reference

| Field | Type | Rules |
|-------|------|-------|
| `rank` | int | Place position (1-based). Determines H3 heading number |
| `name` | string | Place name as shown in H3 |
| `feature` | string | 1-3 word descriptor, max **25 runes**. What the place IS, not what it offers |
| `paragraphs` | []string | 2 standard, 3 for museums/parks. Each **150-350 chars** (no spaces) |
| `features` | []string | **2–4** items (validator min 2, max 4; 3 = default). `<strong>Label:</strong> concrete fact`. Each 40-70 chars (max 100 runes) |
| `info` | map | Keys: `address`, `phone`, `website`, `price`, `schedule`, `metro`. Custom keys allowed |
| `image_id` | int | WordPress media ID from `wp_image upload`. Omit to inherit existing |
| `cta_text` | string | Button text. **CTA renders only for rank 1-3** (renderer-enforced via `maxCTARank=3` in `validate.go`). Set on top-3 places; rank 4+ places will not render CTA even if field is set. |
| `cta_url` | string | Button URL. Must be verified working link |

### Meta file

Structural metadata in `/tmp/go-wp/{PROJECT}/meta-ID.json`:

```json
{
  "place_type": "restaurant",
  "city": "Saint Petersburg",
  "ad_ref": 33498,
  "ad_every": 3,
  "links": [],
  "keywords": ["keyword1", "keyword2"]
}
```

JSONL content (lead, intro, quick-wins, faq) overrides meta. Structural fields (place_type, ad_ref, links, keywords) stay from meta.

### Internal cross-links (`links`) — SEO-useful, never repeated

The meta file's `links` array (`[]string`) is internal cross-linking. The renderer spreads **each entry once**, evenly across the article, as an `extra-info-block` paragraph (it dedupes identical entries; `related_every` no longer affects cross-links). **Each entry is a written sentence carrying a descriptive, keyword-bearing `<a href="...">anchor</a>` — NEVER a bare URL.**

- Good: `"Если ребёнок увлёкся спортом — посмотрите <a href=\"https://piter.now/sportivnye-sekcii-dlya-detey/\">подборку детских спортивных секций</a>."`
- Bad: `"https://piter.now/sportivnye-sekcii-dlya-detey/"` (renders as raw-URL anchor text — the renderer auto-anchors it but the text stays the URL: bad copy).

- **Supply 3–5 DISTINCT sibling collections that form the topic cluster** (e.g. a child-health podborka links офтальмология ↔ стоматология ↔ логопеды ↔ медцентры). Each a DISTINCT published URL — Google credits only the FIRST link to a URL, so repeating one target is wasted; more distinct relevant siblings = more crawl paths + topical authority.
- **Complement, don't mirror, the related widget.** The page also auto-inserts ONE foxiz related-by-tag widget; the in-body `links` are the higher-value contextual links (keyword anchors the widget can't give). Don't make `links` a copy of one or two posts.
- Link only to **published** collections you verified resolve (200, not 404). No related published collection → leave `links: []`.

### Partial updates

Omit unchanged fields — they inherit from the decompiled original.

| Type | Zero value | Meaning |
|------|-----------|---------|
| `string` (`""`) | Inherit original | |
| `[]string` (`nil`) | Inherit original. `[]` = clear |
| `map` (`nil`) | Inherit entire map. `{}` = clear all. `{"key":"val"}` = merge |

**Truncation guard — a partial JSONL must include EVERY rank.** A rank ABSENT from the JSONL is DROPPED on compile (not reconstituted from the decompiled original); publishing the result truncates the article. To touch even one place in an N-place listicle, include all N ranks — reworked ones with new content, the rest as inheriting stubs (rank present, fields omitted -> they inherit). The field-level inheritance above applies only to fields of a rank that IS present.

### Writing to file

```
wp_temp action=write file=places-ID.jsonl content='{"rank":1,...}' project={PROJECT}
wp_temp action=write file=places-ID.jsonl content='{"rank":2,...}' append=true project={PROJECT}
```

Always use `append=true` after the first write.

## Shared Stages

### RESEARCH (per place)

    0. Discover the current canonical set FIRST (don't trust stale existing places):
       wp_research topic="<collection topic>" mode=places project={PROJECT}
       -> current places + venue_verified + status (permanently_closed/temporarily_closed via
          the 2GIS+Yandex maps checker) + suggested_top. wp_research is the STATUS AUTHORITY;
          lead discovery with it, NOT raw go-search.
    1. wp_research_get name="Name" post_id=ID project={PROJECT}
       -> check L1 (enrich cache) and L2 (agent decisions)
    2. If cache_hit=false or data is stale:
       wp_enrich mode=places data=[{"name":"Name","url":"https://..."}] project={PROJECT}
       -> facts (JSON-LD/regex), phone, prices, og:image, lat/lon + status (same maps checker).
          CAUTION: enrich matches by NAME — if facts.low_confidence is set or facts.place_name
          diverges from your query, the match is the WRONG venue; don't trust its status/address.
    3. For deeper research (if enrich insufficient):
       research query="Name City" depth=medium                  <- go-search, no project
       web_url_read url="https://official-site.ru"                  <- go-search, no project
    4. wp_research_save post_id=ID name="Name" \
         paragraphs=["p1","p2"] features=["f1","f2","f3"] \
         info={"address":"...","phone":"...","schedule":"..."} \
         facts_used=["JSON-LD hours","og:image"] \
         facts_rejected={"old_phone":"outdated, site shows new number"} \
         validation_errors=["paragraph 1 too short (120 chars)"] \
         project={PROJECT}

Key questions per place: Is it open? Current prices? Phone, address, website, schedule? What's special right now? If closed -> replace from wp_research's `suggested_top` (verified, current), reusing the same rank — never invent a replacement.

**Save ALL 6 fields to research_save** (`paragraphs`, `features`, `info`, `facts_used`, `facts_rejected`, `validation_errors`) — this populates L2 cache so future updates skip redundant research.

### IMAGES (per place)

Every place needs an image. Min width 880px, real photo (no logos/banners/icons/cartoons/stock, wrong venue, portraits).

Source priority: official site **og:image FIRST** (pass `website=<official site>` so og:image is candidate #1) -> Yandex Maps -> VK -> Pexels (landscape). No generic stock photos.

**Standard flow — three steps (IMAGE_VISION_ENABLED defaults off):**

**Step 1 — resolve candidates** (per place or full article):

    wp_image action=resolve_candidates place_name="Name" query="Name city" website="https://official-site.ru" \
        max_results=8 project={PROJECT}
       -> downloads candidates to /tmp/go-wp/{PROJECT}/img-candidates/{slug}/
          full/{idx}.jpg + thumbs/{idx}.jpg
       -> writes manifest.json: {slug, place_name, available_count,
          candidates:[{idx, thumb_path, full_path, url, title, source, license}]}
       -> returns {manifest_path, slug, available_count}
       NOTE: does NOT upload to WordPress.

**Step 2 — spawn haiku subagent to pick the best photos:**

Dispatch an `Agent` tool call with `model: "haiku"`. Pass the thumbs folder path and reject criteria verbatim:

    prompt: |
      Look at the thumbnail images in {thumbs_dir} (thumbs/{idx}.jpg, indices 0..{N-1}).
      Place: {place_name}.
      Select the {target} best photo(s).
      Target: cover=1, gallery=3-6 (minimum 1).

      REJECT any image that is:
      - a logo, banner, icon, cartoon, or decorative graphic
      - a watermark-heavy or low-quality photo
      - an error/placeholder graphic (anti-hotlink pages showing text like
        "does not have permission", "404", "image not found")
      - a portrait of a person (not a venue photo)
      - clearly the wrong venue
      - byte-identical to another candidate (shared placeholder)

      Source priority preference: og:image (idx 0 when website was provided) over
      search results. Only pick search results if the og:image is not a real photo.

      Return ONLY valid JSON: {"selected": [<indices>]}
      Example for cover: {"selected": [0]}
      Example for gallery: {"selected": [0, 2, 4]}

   The haiku subagent reads thumbs/{idx}.jpg via the Read tool (Claude vision),
   evaluates them against the reject criteria, and returns {"selected": [indices]}.

**Step 3 — upload selected full-res candidates:**

    wp_image action=upload_selected slug={slug} selected=[{indices from haiku}] \
        alt_text="..." project={PROJECT}
       -> validates every index against the manifest (out-of-range = error, no partial upload)
       -> uploads full-res images to WP media library
       -> returns {image_ids: []int, count}

Use the first image_id as `image_id` (featured/cover) in the place JSONL block.
For gallery mode use all returned image_ids.

**Fallback** — if resolve_candidates returns available_count=0 for a place:
- Re-try with a different query or without the website param.
- Only if the entire source chain is exhausted: leave image_id empty and FLAG the place.
- Never publish a placeholder or error graphic. Never stop to ask the user which image.

Inheritance: images from `collection-ID.json` auto-merge by place name. Only provide `image_id` if replacing.

### IMAGE CAPTIONS (mandatory)

Every image MUST have a caption (`image_caption` field in JSONL). Write the caption yourself after uploading — describe what is specifically visible in the photo.

Caption rules:
- Describe what is **specifically visible in the photo**, not the place in general
- Include a concrete detail: name, number, or visual element
- Max 90 chars, no generic descriptions

| Bad caption | Good caption |
|------------|-------------|
| "Ресторан La Vue" | "Панорамный зал на 12 этаже — вид на Петропавловскую крепость" |
| "Красивый интерьер" | "Мраморная лестница XIX века с оригинальными перилами" |
| "Фото музея" | "Зал с 23 интерактивными экспонатами для детей от 3 лет" |
| "" (пусто) | Ошибка PRD — подпись обязательна |

In JSONL: `{"rank":N, "image_caption":"Concrete description of what's in the photo"}`

### VALIDATE

    1. wp_temp action=compile file=places-ID.jsonl project={PROJECT}
       -> sanitizes JSON, reports place count and meta blocks
    2. wp_render_blocks places_file=places-ID.jsonl meta_file=meta-ID.json \
         validate_level=LEVEL \
         save_to=/tmp/go-wp/{PROJECT}/collection-ID-compiled.json project={PROJECT}
       -> compiles + validates (paragraph length, features, images); RETURNS html_file (the rendered HTML to publish)

**Validation levels:**
- `strict` (default) — use for **new articles** (`create-article`). All fields required: lead, intro, quick-wins, faq, features, images.
- `lenient` — use for **partial updates** (`update-article`, `fix-article`). Skips checks for lead/intro/brief/faq/features/image when they are not in JSONL.

If errors: fix JSONL (`wp_temp action=update rank=N file=places-ID.jsonl content='{...}'`) -> re-compile -> re-render. Do not publish with errors.

### PUBLISH

    # TRUNCATION GATE (multi-place posts): the compiled place count (VALIDATE step 1, or `jq '.places|length'`)
    #   MUST equal the live article's place count. Fewer -> a rank is missing from the JSONL -> STOP (see Partial
    #   updates). Re-confirm the count held after publish.
    1. wp_post action=update post_id=ID content_file=<html_file from VALIDATE step 2's wp_render_blocks> project={PROJECT}
       # content_file = the RENDERED HTML. NOT blocks_file / the save_to collection JSON (wp_post rejects it).
    2. wp_seo action=set post_id=ID title="..." description="..." focus_keyword="..." project={PROJECT}
    3. wp_post action=update post_id=ID excerpt="≤150-char сок-first one-liner (names+dates+count)" project={PROJECT}
       # MANDATORY — never skip. An unset excerpt makes WordPress auto-generate a
       # 300-500-char wall of trimmed body. wp_audit_article errors on empty/>200.
    4. wp_check_anglicisms post_id=ID project={PROJECT}    -> fix FZ-168 violations
    5. wp_audit_article post_id=ID project={PROJECT}
       -> If errors: fix JSONL → wp_temp update → re-compile → re-render → re-update → re-audit
       -> Repeat until 0 errors
    6. wp_flush_cache project={PROJECT}

SEO: title 50-60 chars with keyword, description 150-160 chars with CTA verb.

After publish:

    wp_image action=set_featured post_id=ID search_query="topic" project={PROJECT}
    # TAGS — thematic SEO tags, ~3-5 per post (full policy: the piter SEO profile «## Tag policy»). HARD rules:
    #   - Each tag = a 2-3-word RU SEO phrase that GROUPS this post with others on the same theme
    #     (e.g. «банкротство физических лиц», «музыкальные школы СПб»). NEVER a single word, an abbreviation
    #     («физлиц», «СПб»-as-a-tag), a bare city, or a bare year.
    #   - FORBIDDEN as tags: «Санкт-Петербург»/«СПб» (bare city), «2026»/bare «Месяц Год» (bare date),
    #     «дети»/«Работа» (bare single word) — they unite nothing = noise. Do NOT set a city_keyword tag and
    #     do NOT run `assign_date_tags` for an ordinary podborka (it produces the bare-date noise we purged).
    #   - REUSE-FIRST: before creating a tag, check the inventory (`wp term list post_tag` / `wp_manage_tags audit`)
    #     and reuse an existing matching phrase; a new tag only when none fits. Never proliferate near-duplicates.
    #   - Assign to a SMALL known set by post_id — NEVER keyword-scan (assign_by_keywords matches each key as a
    #     SUBSTRING across every post → mis-tags thousands: «КТ» hit контакт/проект/факт 2734, «УЗИ» hit грузи/Грузия 213).
    #     Use wp_set_post_tags (3rd arg: true=append, false=replace-all):
    #       wp_cli, command = eval "wp_set_post_tags(<id>, ['банкротство физических лиц','списание долгов','юридические услуги'], true);"
    #   - EVENTS / time-bound ONLY: for a genuinely dated post (a specific-month fair/festival) the tag carries the
    #     period as «<тема> <Месяц Год>» (e.g. «ярмарки Петербург декабрь 2025») — NOT a bare «Декабрь 2025», and
    #     NEVER a per-month news-digest tag (use one evergreen «новости Петербурга»).
    #   - After assigning, verify the affected count is plausible (a topic tag hits a handful, not hundreds).

## Style-check (live post vs in-hand text)

To style-check a LIVE post by id, use `wp_check_anglicisms post_id=ID` (RU only — EN/hully has no post-aware style checker). `wp_check_style` takes raw `text=` (NO `post_id`) and auto-routes RU→anglicism / EN→style-lint — use it for in-hand text such as EN drafts.

## Contact Sourcing & Provenance

Every contact / price / schedule / specialty MUST come from `wp_enrich` / `research` / `web_url_read` — never invented, never lifted from the existing article without re-confirming THIS run. **Unverified → leave the field empty and flag it. Empty beats invented** (the renderer treats brand-search as valid for places without a street). The validator is correct; a missing field is a research task, not a reason to fill it in.

### Trust enrich provenance — don't hand-verify every phone

`wp_enrich` resolves contacts source-first (`operator_verified > official_site > aggregator > maps`), matches the site's own `tel:` / social link, detects call-tracking (DNI), and tags every field `provenance{source, confidence}` + a `low_confidence` flag. Read that:

- `{official_site, high}` → use it (already beat the aggregator/maps card and matched the site `tel:`).
- `low_confidence:true` or `{maps|aggregator}` source → UNCONFIRMED → «уточняйте», never ship as a fact.
- **No `phone` returned** → call-tracking site (Roistat / Calltouch / Comagic / Mango / Callibri / UIS), no stable number → «уточняйте»; never substitute a maps number to fill the gap.
- **`email` / `legal_address` are COLLECTED but NEVER displayed** — they exist for verification only. Consumer cards carry phone / site / address / hours, never ИНН / реквизиты / email (local-directory standard). `address` is already venue-only (the legal seat is split off) — use it directly for the map pin.
- A value YOU hand-verified that enrich must not overwrite (a confirmed number on a DNI site) → pin it in the JSONL `operator:{phone:"…"}` block (→ `operator_verified`, survives re-enrich).

### Shape-check every enrich value before trusting it

Enrich leaks scrape artifacts. A `price` that isn't `<number> ₽/р` is not a price; a `place_name` that is an aggregator label (2GIS / Yandex Maps / zoon) is not the name; an `hours` key must become `schedule`; a placeholder `website` («уточняется») is not a domain. Any field failing its shape → UNCONFIRMED → empty / re-research. A **suspicious match** (a search returns a different place — wrong name, wrong city/region, or `low_confidence`) → do NOT use it; flag it, then re-research the real entity or replace the place.

### Same-name entity guard — one card = ONE entity = ONE official site

When a name matches more than one real org, lock onto the entity whose site you cite as `website` and take EVERY field — affiliation, building, history, services, address, phone, price — from that site only. Never assert an affiliation (вуз / сеть / головная организация) or a building/history detail unless it's on that exact site; default = no affiliation claim. The phone must be a `tel:` on that same site — a «verified»-looking number absent from it is a different entity's or an aggregator's → drop it. Never merge attributes across same-named orgs.

### Address → Yandex Maps pin mechanics

The info-grid renders the address as a Yandex Maps link from `value` + `city`: `single` → `?text=Санкт-Петербург, <value>` (point); `brand-search` → `?text=<value> в Санкт-Петербурге` (all points).

- **Multi-branch venue → `address_mode:"brand-search"` with the BRAND NAME**, never a crammed street. NEVER put «N адресов по городу» / «улица X (и ещё N адресов)» in `value`, and never force `mode:single` on a vague value (renders a garbage `?text=…, 4 адреса в центре`).
- **Single location → `mode:single` + strictly «улица, дом»** — NO parentheticals / landmarks («(ЖК…)», «, ТРК…», «(рядом с…)», «(и ещё N…)»); they break the geocoder (empirically the bracketed version returns emptiness or a wrong object, the clean street resolves).
- **Generic-word brand + no public street → qualify the brand with its CATEGORY in the place HEADING** (not just `value`). render.php builds the pin from the heading («`<name>`: детали» → `data-address`), so a bare generic Russian noun (Грация, Счастье, Сказка, Радость) pins to the WRONG object — fixing only the info `value` does NOT move the pin. Set the heading (and value) to the agency's real self-described full name («Свадебное агентство Грация»); verify the qualifier on the site, never invent. If the brand is a generic word (e.g. «Пинцет» = tweezers), prefer ONE verified flagship address in `single` over a brand-search that returns unrelated hits.
- `city` MUST be «Санкт-Петербург» in Cyrillic (never «Saint Petersburg» → broken `?text=Saint Petersburg, …`); the `value` must NOT repeat the city (double-city also breaks it). Set `city` at BOTH the place top-level AND inside `info` (top-level overrides info; meta-collection city cascades only to places with empty city). A venue genuinely outside the city (Мурино / Ленобласть) gets its own city. Always open the generated `yandex.ru/maps/?text=…` and confirm it resolves to the venue before shipping.

### Provenance must be checkable

Every contact / price / schedule / specialty you write needs a `wp_research_save facts_used` entry carrying the literal value AND where it was seen (`"phone +7(812)501-27-55 — wp_enrich JSON-LD telephone"`). Can't quote where it appears → you have NOT sourced it → leave the field empty. When you replace an existing value with researched data, record it in `wp_research_save facts_rejected={...}` and in your report.

## Legacy info-grid conversion (piter.now specifically)

Many piter.now articles lost their paragraphs / features / CTAs in a migration (that's why the validator flags them) and carry contacts as legacy `<strong>Адрес:</strong>…` prose. Those paragraphs audit clean (the decompiler parses them into `info`) but the live page gets no structured block — **convert on ANY touch**:

- Mapped labels (`info_key_map`: Адрес→address, Телефон→phone, Сайт→website, Режим / Часы / График работы→schedule, Цена / Стоимость→price) → the typed fields.
- **Unmapped DIRECTORY-FACT labels stay IN the info-grid as CUSTOM fields** — do NOT dump them into features. The renderer auto-emits any extra `info` key as a `{type:"custom", label, value}` row, so a scannable fact belongs in the grid. Keep custom labels SHORT (one word where it reads cleanly, never a long phrase). Which facts are directory-grade is vertical-specific (the dispatch names them for the collection at hand); the test: a reader scanning the list wants it as a ROW, not buried in prose. features = PROSE differentiators / hooks, NOT the scannable facts.
- Preserve EVERY field the legacy paragraph carried — mapped → typed, unmapped-fact → custom. Never silently shed a field.
- **Re-verify directory facts against the LIVE source on a paid placement (and on any touch).** A restored / legacy value (class size, price, schedule) is «true at creation time» but DRIFTS — the live source is truth. Re-read it, update the changed value, flag the drift. A stale fact in a directory grid is the same defect class as a fabricated one.
- Rebuild missing paragraphs / features from fresh research, don't render the stub as-is. `wp_render_blocks` may re-insert ad blocks and alter CTAs vs the live post — **diff the compiled output against the decompiled original before publishing** so you don't silently change ads / CTAs the operator didn't ask to touch. To change post content use `wp_post action=update` (clears caches), NOT `wp search-replace` (silently no-ops on relative URLs + Redis cache).

## CTA copy (a PAID product — conversion instrument)

CTA tiers are a PAID product distinction — **never change form factor.** Simple CTA = plain `wp:button` (label + URL only). The premium box `foxiz-elements/cta` is sold separately.

- **Structural canon (`foxiz-elements/cta`):** meaningful `heading`; `headingHTMLTag:"h3"` (default h2 breaks the outline); `description` = a real RU line, NEVER absent (an empty description makes the theme inject an English placeholder); `imageURL`; buttons primary `isButtonBorder:false` / socials `true`; all `isNewTab` + `noFollow`. Renders only on rank 1-3 (`maxCTARank=3` in `validate.go`).
- **Copy methodology** — its only job is to earn the click to the advertiser's link. URL + UTM are advertiser-frozen; only heading / description / button are yours. RU editorial register — concrete and useful, NOT loud (infobiz «успей! / революционный» kills trust on a city-guide):
  1. `heading` = the concrete DIFFERENTIATOR, not the place's name (the reader already sees the name in the card) — the one fact that sets this place apart vs the others in the list. NOT «X — узнайте больше».
  2. `description` closes ONE fear + names the step — kill the single biggest objection of THIS audience AND say what happens after the click.
  3. `button` = verb + what REALLY happens on the other side, funnel-matched to the destination: form → «Записаться» / «Оставить заявку»; info page → «Узнать стоимость» / «Посмотреть…». «Узнать подробнее» is evasion; never promise what the page doesn't deliver.
- **Provenance — every CTA claim must be quotable from the LIVE site at publish.** `web_url_read` the advertiser site; for each fact in heading / description hold the verbatim source line. A claim you cannot quote → CUT it, do not soften-and-keep. Button = the site's ACTUAL primary CTA wording, not a guessed verb. Reused numbers (ours / the info-grid) can be STALE — the live site wins; re-verify, use the current value, flag the drift. One CTA per place, one action, RU only.

## Live snapshot self-check (mandatory — audit-clean ≠ page-correct)

After `wp_flush_cache`, take a structured snapshot of the PUBLISHED page and read it yourself: `go-wowa snapshot url=<live-url>` (outline mode — cheap, structured; fall back to `go-wowa render` + grep if the tool is unavailable in your session). Assert on the RENDERED page, NOT just the JSONL:

- (a) heading levels — place headings are h3, CTA premium headings h3, NO place rendered as h2;
- (b) ZERO English in CTA / foxiz blocks (an English placeholder = the premium-CTA description was left empty — fix it);
- (c) info-grid renders structured for every place (no `<strong>Label:</strong>` legacy contact paragraphs left);
- (d) ≤3 paragraphs per place section (4 only if justified);
- (e) galleries loaded (no blank lazy gaps);
- (f) every CTA + button + UTM present.

Any mismatch → fix → re-render → re-update → re-snapshot. The audit passing is necessary, not sufficient — the snapshot is what proves the reader sees what you built.
