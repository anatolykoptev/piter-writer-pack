---
name: news-pipeline
description: Run the news discovery and publishing pipeline. Use when asked to find news, discover news, publish news, check for new stories. Triggers on "news", "novosti", "find news", "news pipeline".
argument-hint: "news_project=\"...\" [project=piter]"
---

# News Pipeline

Discover, filter, and manage news articles. Note: `news_project` is a pipeline key within news-config.json (e.g., "piter.now"), separate from the multi-tenant `project` parameter.

## Project selection

Project routing (`piter`=RU / `hully`=EN; ASK if ambiguous) and the Hully-specific notes live in `_common.md` (read every run). Pass `project={PROJECT}` to every `wp_*` call.

## Arguments

- `news_project` — news pipeline key (e.g., "piter.now")
- `project` — multi-tenant project key (default: `piter`)

## Pipeline

**Substitute `{NEWS_PROJECT}` with the `news_project` arg value** (`piter.now` for piter, `hully.day` for hully) before executing each step below. The workflow engine does NOT resolve this variable — you (the agent) must substitute it literally.

### 1. DISCOVER

```
wp_news action=discover news_project="{NEWS_PROJECT}" project={PROJECT}
```

Returns raw news items from configured sources.

### 2. FILTER

```
wp_news action=filter news_project="{NEWS_PROJECT}" project={PROJECT}
```

Filters by relevance, deduplicates against existing articles.

### 3. LIST

```
wp_news action=list news_project="{NEWS_PROJECT}" project={PROJECT}
```

Review filtered candidates. Pick stories worth publishing.

### 4. COMPOSE

For each selected news item, write content following content rules in `_common.md`.

News articles are typically shorter — fewer places, more focus on the event/announcement.

### 5. UPDATE

```
wp_news action=update news_project="{NEWS_PROJECT}" item_id=ID status=published project={PROJECT}
```

Mark processed items to avoid re-processing.

### 6. CLEAN

Periodic cleanup of old news state:
```
wp_news action=clean news_project="{NEWS_PROJECT}" project={PROJECT}
```
