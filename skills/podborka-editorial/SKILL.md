---
name: podborka-editorial
description: SINGLE SOURCE OF TRUTH for the piter.now / hully.day podborka editorial standard — hook lead (social-post opener), context-ladder intro, «Коротко о главном» brief axes. Content agents (wp-copywriter, wp-reviewer) and go-wp pipeline docs point here; nothing may restate this prose.
---

# Podborka editorial standard (single source of truth)

**This file is the only home of the editorial canon.** go-wp (`wp_format_spec`, `wp_prd` data_rules, workflow step messages), agent definitions, and skill docs POINT here and never restate the prose. Found a copy of these rules elsewhere? That is a bug — replace it with a pointer to this file. To change the standard: edit this file, commit, push (claude-config syncs mac↔krolik via git; no build, no deploy).

Applies to place/event listicles (подборки) on **piter.now** (RU) and **hully.day** (EN — same structure and bans, English prose). Structural gates (lead 150–250 chars no spaces, lead+`more` placement, block schema) are enforced by the go-wp validator and are NOT relaxed by anything below.

## 1. Lead — hook opener (social-post test)

The lead is a social-post opener, not a search snippet. Its one job: stop the scroll of a reader who was NOT searching for this topic. Sentence one must add what the headline could not — ONE concrete, checkable, surprising fact, scene, or tension taken from the strongest card in the collection.

Hard rules:
- Never restate the headline.
- Never open sentence one with the «{категория} — {N} мест от {X}₽» skeleton.
- Never enumerate 3+ venues through commas — the list and «Коротко о главном» do that job.
- Count and price range belong in the CLOSING sentence of the lead, not the opener.
- The hook must be cashable by a specific card below — verified фактура only, never invented drama. If no card backs the hook, it does not run.
- The category key phrase should appear naturally somewhere in the lead (any sentence) for search; the snippet job itself belongs to seo.description.
- Still banned: atmosphere/feelings openers, vague praise, «лучшие места города» water, rhetorical questions that defer facts, season/weather throat-clearing («Июль — пик лета», «Петербург умеет удивлять»).

Self-test: read sentence one alone as a Telegram post — would it stop a scroll? If it reads like the headline again, rewrite.

Size: validator enforces 150–250 chars (no spaces); stylistic target 150–200.

### Hook patterns

| id | pattern | example |
|---|---|---|
| shock-fact | {самый громкий проверяемый факт коллекции}. {разворот: что это за подборка}. {хвост: число/диапазон цен, без перечисления} | Музей Банка России не берёт за вход ни рубля — никогда, это не акция. И таких мест в Петербурге 17: собрали, куда пускают даром постоянно, а куда — по особым дням, от Горного музея до Мозаичного дворика. |
| scene | {одна визуальная деталь из сильнейшей карточки — как кадр}. {разворот к подборке с числом/ценой в конце} | Пишущая машинка Зощенко так и стоит на его столе — а билет туда дешевле чашки кофе. В городе 13 музеев со входом до 300 ₽, в Петропавловке и на Елагином — вообще по 100. |
| tension | {дефицит или социальное доказательство}. {почему — конкретика}. {раскрытие подборки} | Столики здесь бронируют за две недели — и не ради интерьера. Омакасе за 4500 ₽, камчатский краб за 890 ₽, тирамису на 400 граммов: 10 новых мест, где очередь настоящая. |
| myth-bust | {что все думают про категорию}, {проверяемый факт, который это ломает}. {подборка} | Художественную гимнастику считают дорогим спортом, но в СШОР Петербурга занимаются бесплатно — если пройти отбор. Как он устроен и где берут без отбора: 11 школ, частные — от 600 ₽ за занятие. |
| stakes | {конкретная ситуация читателя одной строкой, без «вам»/«каждому»}. {выход через подборку} | Записаться «на сегодня» к нормальному барберу почти нереально: либо салон у дома, либо центр по цене ужина. Прошли 13 барбершопов по районам — стрижка от 900 ₽ и куда реально попасть в день записи. |
| insider | {факт, который знают только свои}. {подборка с диапазоном в конце} | В «Ленрезерв» с его танками и фронтовыми полуторками вход бесплатный — нужно только записаться заранее. 10 военных музеев Петербурга: от «Авроры» до диорамы под Кировском, билеты от 0 до 600 ₽. |

## 2. Intro — context ladder

Open on the reader's concrete stake — the situation that makes this list matter to them right now — then widen to the landscape and how it was chosen. The stake is the hinge between the lead's hook and the list; an intro that opens on the category landscape, skipping the stake, reads as a disconnected second exercise.

Ladder:
1. **Stake** — the reader's concrete, checkable situation that makes this collection matter («год до экзамена, по профильной тройка»), turned into the selection criterion the article actually uses.
2. **Landscape** — the state of the category (range, numbers, federal-vs-small, price spread).
3. **Method** — how chosen, what «проверенных» means, how verified.

The opening is ONE descent, not two exercises: lead and intro are two rendered blocks (lead sits before the `more` cut), but write them as one continuous opening and cut at the natural reasoning joint.

### Intent-based intro approaches

| id | reader intention | content balance | when to use |
|---|---|---|---|
| discovery | Find something new and unknown | 70% atmosphere, 20% practical, 10% facts | New places, lesser-known venues, hidden gems |
| upgrade | Upgrade from a familiar option | 40% comparison, 40% detail, 20% atmosphere | Alternatives, no-queue options, better-than-the-famous |
| solution | Get a quick factual answer | 80% facts, 15% convenience, 5% emotion | Urgent task, specific need, simple query |
| event | Organize a specific occasion | 50% atmosphere, 30% logistics, 20% facts | Birthday, celebration, date |
| restriction | Hard filter (dietary, accessibility, budget) | 60% criteria match, 40% quality | Allergies, convictions, strict requirements |
| community | Find your people | 40% in-group signals, 40% practical, 20% acceptance | Diaspora, subcultures, interest groups |

## 3. Brief — «Коротко о главном» (routing block)

Each bullet = bolded superlatival label + named specific place + concrete number or reason. No generic praise; every item must be verifiable (price, time, distance). 4 items; routing «куда за чем», never educational tips.

| axis | label | template |
|---|---|---|
| 🏆 | Лучшее в городе | [place] — [concrete_reason] |
| 💰 | Самое доступное | [place] от [exact_price]₽ |
| 🌟 | Новинка сезона | [place] открылось [when_exactly] |
| 📍 | У метро | [place] в [time] минутах от [station] |

## 4. Place cards — content rules recovered from the v4.1 spec (2026-07-08)

- **`place_type` is MANDATORY in collection meta.** The renderer keys type-adaptive feature-block headings, CTA labels, and required info fields off it (go-wp `place_type.go`); unset → everything degrades to generic «{name}: подробнее». Valid keys: restaurant, bar, cafe, museum, exhibition, walk, route, hotel, resort, active, quest, vr, kids, workshop, spa, theater, concert, space, farm, park, delivery, shop, sport_section, monument, landmark, viewpoint. Pick the closest (спортшколы/секции → sport_section, детские студии → kids, мастер-классы → workshop). An unset or wrong place_type is a defect the reviewer must flag.
- **`intro_heading`** (JSONL intro line, `heading` field): the H2 rendered between the `more` cut and the intro paragraphs — a keyword-bearing slot («Как выбрать школу художественной гимнастики»), phrased naturally, never a headline repeat.

- **Heading descriptor** («Name — descriptor»): a UNIQUE hook per place, never repeated across cards in the same collection («Бюджетная СШОР» + «Бюджетная СШ» back-to-back = defect). Concrete beats categorical: «Сеть, 16 филиалов» ✓, «Известная школа» ✗.
- **Features for restaurants/cafes/bars** = the menu variant: «Что попробовать» — 3 dishes, each `**[Dish]** — [price]₽`. Not generic coordinate features.
- **Image caption = a fact about the PLACE, not a description of the photo.** «Юные гимнастки на тренировке» carries zero information; «Тренер — мастер спорта, набор с 4 лет» works. Max 90 chars.
- **Info-field checklists by place type** — what research must try to fill (empty beats invented still binds; these are targets, not fabrication licenses):
  - education/kids: цена, адрес, возраст, размер групп, педагоги (имя+регалия), как записаться
  - restaurants/cafes/bars: средний чек, адрес, часы, кухня, бронирование, парковка
  - events: билеты/цена, площадка/адрес, дата и время, длительность, возрастной ценз, сайт (за билетами), где купить
  - delivery: мин. заказ, зона, время доставки, приложения, промокод, кухня
  - secret/hidden places: правила входа, как найти, сложность, лучшее время, что взять с собой
- **Phone = the GENERAL public line, never a department.** The card's contact number must be the reception / справочная / general customer line — NOT a departmental contact («аренда торговых мест», отдел кадров, бухгалтерия, факс, для СМИ). If a site lists several, take the one for customers/visitors. wp_verify tags each site number role=general|departmental and refuses to auto-apply a departmental one (`correctable=false`); a leasing/HR number on a card is a defect the reviewer flags.
- **Event JSON-LD contract (info-block → schema.org `Event`).** The info-block renderer auto-builds an `Event` from the card's fields, so author them machine-parseably — a good value renders rich SERP results, a sloppy one silently fails Google's validator:
  - `date` — the renderer ISO-8601-parses it: «15–16 августа», «с 15 по 16 августа», time «12:00–20:00», overnight «23:00–07:00» (end rolls to next day). **Include the year whenever the event is not clearly this season** («15–16 августа 2026») — otherwise the year is *inferred* from the render date and can drift. Ongoing exhibition → «до 6 сентября» / «по 16 августа» (renders as сегодня→дата закрытия). Recurring («каждую субботу») can't be a schema date — give the concrete next date if one exists; otherwise it stays a raw string (no date in SERP).
  - `price`/`tickets` — the renderer extracts the NUMBER (schema.org rejects text prices): «от 1300 ₽» → floor, «500–1500 ₽» → range, «1500 ₽» → flat, «бесплатно» → free. An age/duration in the same string («детям до 7 лет») is ignored, but keep the price legible — don't bury it in prose.
  - `website` unlocks `offers.url` + `sameAs` — fill it when known. `address`/`venue` → the event's `location`.
  - `organizer` / `performer` / `image` are schema-recommended but NOT auto-derived from the card — name the organizer/performer in the card text and rely on the post's featured image for the schema image (fill-when-known, never fabricate).
- **FAQ for collections**: 5-7 items (floor 5, not 3); heading carries the topic AND the city («Частые вопросы о [topic] в Петербурге»); answer structure = direct answer → detail with numbers → mention of 1-2 places from the list → practical tip.

## Shared bans (all three zones)

Warmth is a reporting act, not a tone: it comes from naming the reader's situation in concrete, checkable words — never from adjectives about the venue's or your own virtue («с заботой к каждому», «лучшие центры города» = water). Test any warm phrase: delete it — if no checkable fact is lost, it was water. Anti-fabrication binds everywhere: empty beats invented; a hook, number, or superlative that no verified card backs does not run.
