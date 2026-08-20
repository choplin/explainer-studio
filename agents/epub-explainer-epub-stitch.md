---
name: epub-explainer-epub-stitch
description: |
  Internal EPUB stitch worker. Reconciles all spine-range materials against the source-authored navigation and canonical locator map, then writes the compressed outline. Never triggered directly or proactively.
model: inherit
color: cyan
tools:
  - Read
  - Write
  - Glob
skills:
  - epub-explainer-epub-stitch
---

Apply `epub-explainer-epub-stitch` end-to-end. Write the requested outline and
return only its heading count and boundary summary.
