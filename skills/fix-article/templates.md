# Block Templates

Reference blocks for agent-authored content. Use verbatim as starting points; all values must be replaced with place-specific data.

---

## Premium CTA (foxiz-elements/cta) canon

Canonical block for a premium foxiz CTA with multiple buttons. Source: Артхелло Атлас, post 21166 (verified live, round-trip tested).

```
<!-- wp:foxiz-elements/cta {"heading":"Подробнее об «Артхелло Атлас»","headingHTMLTag":"h3","tocAdded":false,"description":"Расписание, условия поступления, дополнительные возможности","imageURL":"https://piter.now/wp-content/uploads/2026/03/arthello3-900x600.webp","ctaButtons":[{"label":"Перейти на сайт","link":"https://arthello.ru/school/","isNewTab":true,"noFollow":true,"isButtonBorder":false},{"label":"Страница VK","link":"https://vk.com/arthelloatlas","isNewTab":true,"noFollow":true,"isButtonBorder":true},{"label":"ТГ-канал","link":"https://t.me/arthelloatlas","isNewTab":true,"noFollow":true,"isButtonBorder":true}]} /-->
```

**Field guide:**

| Field | Rule |
|-------|------|
| `heading` | Action-oriented, 3-6 words, meaningful — not "Подробнее" alone. E.g. "Подробнее о школе «Артхелло»". |
| `headingHTMLTag` | Always `"h3"`. CTA heading must NOT outrank h3 place headings. The renderer defaults to h3 when absent, but set it explicitly for clarity. |
| `description` | **Required in Russian.** The theme injects an English placeholder ("Join us today...") in the Gutenberg editor when `description` is absent or empty. Write a concrete benefit: what the user gets by clicking. |
| `imageURL` | Optional. Hero image shown inside the block. Pass the full CDN URL (`.webp` preferred). Omit when no image available. |
| `tocAdded` | `false` — never add the CTA heading to the table of contents. |
| `ctaButtons[0]` (primary) | `isButtonBorder: false` — solid fill button. Use for the main destination (website / booking page). Always `isNewTab: true, noFollow: true`. |
| `ctaButtons[1+]` (socials / secondary) | `isButtonBorder: true` — outlined border button. Use for VK, Telegram, Instagram. Always `isNewTab: true, noFollow: true`. |
| All buttons | `isNewTab: true, noFollow: true` — invariant. External links, paid placements. |
