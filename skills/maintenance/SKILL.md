---
name: maintenance
description: Periodic maintenance tasks for WordPress site - link checking, tag management, SEO audit, batch operations. Use when asked to check links, audit tags, fix broken links, SEO review, batch update. Triggers on "maintenance", "check links", "audit tags", "broken links", "obsluzhivanie".
argument-hint: "[category_id=ID] [project=piter]"
---

# Site Maintenance

Periodic maintenance tasks that run across articles, not per-article.

## Project selection

Project routing (`piter`=RU / `hully`=EN; ASK if ambiguous) and the Hully-specific notes live in `_common.md` (read every run). Pass `project={PROJECT}` to every `wp_*` call.

## Arguments

- `category_id` — limit to specific category (optional)
- `project` — project key (default: `piter`)

## Tasks

### Link Audit

Find and fix broken or redirected links:
```
1. wp_link_audit category_id=ID project={PROJECT}
   -> reports broken, redirected, and suspicious links
2. wp_fix_links audit_file=latest dry_run=true project={PROJECT}
   -> preview fixes
3. wp_fix_links audit_file=latest project={PROJECT}
   -> apply fixes
```

### Tag Management

```
wp_manage_tags action=audit project={PROJECT}
   -> check tag health (orphaned, duplicate, missing)
wp_manage_tags action=assign_date_tags project={PROJECT}
   -> auto-assign month/year tags to recent posts
```

### SEO Batch Audit

```
wp_post action=list category_id=ID project={PROJECT}
   -> get post IDs
wp_seo action=audit post_ids=[ID1,ID2,...] project={PROJECT}
   -> batch SEO check (missing titles, short descriptions, no keywords)
```

Fix issues per post:
```
wp_seo action=set post_id=ID title="..." description="..." focus_keyword="..." project={PROJECT}
```

### Batch Deduplication

Find duplicate places across articles in a category:
```
wp_dedup_batch category_id=ID project={PROJECT}
```

### Content Scan

Refresh priority scores and process queue:
```
wp_scan action=refresh project={PROJECT}
   -> rescore all collections, rebuild priority queue
```

Review the queue to see which articles need attention most.

### Cache

```
wp_flush_cache project={PROJECT}
```

Run after any batch of changes.
