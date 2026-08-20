---
name: epub-explainer-epub-stitch
description: "Internal EPUB worker that stitches spine-range material into one compressed outline governed by the canonical source structure and locator map."
user-invocable: false
---

# Stitch EPUB material

Read every assigned `extract/chunk-*.md`, `structured/toc.md`, and
`epub/locators.json`. Write `structured/outline.md`.

- The heading tree is exactly `toc.md`'s source-authored tree. Do not derive a
  second table of contents from chunk prose.
- Join boundary continuations and remove duplicated overlap.
- Preserve canonical `[loc:...]` values and source-form titles. A translated
  display title may accompany, but never replace, the source title or locator.
- Retain tables, footnotes/endnotes, ruby readings, figure/SVG references, and
  explicit EPUB semantics when they affect meaning.
- End with `## Boundary notes`, recording joins, coverage gaps, and any nav versus
  XHTML discrepancy. A discrepancy remains visible; do not silently choose one.

Return only the heading count and one line describing boundary decisions.
