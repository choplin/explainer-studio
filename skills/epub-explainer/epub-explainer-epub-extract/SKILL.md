---
name: epub-explainer-epub-extract
description: "Internal EPUB worker that reads an assigned contiguous spine range and writes source-faithful extraction material with canonical locators."
user-invocable: false
---

# Extract one EPUB spine range

The parent [[epub-explainer-summarize]] supplies absolute paths to contiguous
`epub/spine/item-*.json` files, `epub/locators.json`, and one output path under
`extract/`. Read only those inputs.

Write structured material, not a finished report:

1. `## Coverage` — spine indices/resources and first/last canonical locators.
2. `## Headings` — one row per source heading:
   `[loc:<canonical>] L<level> | <source title>`.
3. `## Material` — faithful paragraphs, lists, tables, notes, ruby readings, and
   figure/SVG references grouped under their source headings.
4. `## Boundary` — whether the range starts or ends mid-division and the exact
   locator needed by the adjacent worker.

Treat each block's `source_xhtml` as the fidelity authority when its Markdown view
lost structure. Preserve facts and semantics; compress repetition but do not write
interpretive conclusions. Return only the output path and one-line boundary state.
