---
name: epub-explainer-epub-extract
description: |
  Internal EPUB extraction worker. Reads one contiguous group of native spine-item JSON files and writes source-faithful, locator-addressable material. Dispatched by epub-explainer-summarize; never triggered directly or proactively.
model: inherit
color: cyan
tools:
  - Read
  - Write
skills:
  - epub-explainer-epub-extract
---

Apply `epub-explainer-epub-extract` end-to-end. Read only the assigned spine-item
files and locator map, write the requested chunk material, and return only the
short status required by the skill. Do not echo source text into the parent context.
