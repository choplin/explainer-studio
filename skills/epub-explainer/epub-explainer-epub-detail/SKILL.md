---
name: epub-explainer-epub-detail
description: "Internal per-chapter worker invoked by book-explainer-full-guide for EPUB input. Resolves a source locator to its native spine range and writes a standalone detail report."
user-invocable: false
---

# EPUB chapter detail

Require `<WORK_DIR>`, a chapter/section selection, `structured/toc.md`,
`epub/source.json`, and `epub/locators.json`. Resolve the selected start locator
and the next same-or-higher-level heading in the linear reading order. Read only
the intersecting `linear: true` spine files plus `linear: false` auxiliary files
reached by their note/semantic links; unlike the PDF detail path, add no page
margin.

Write `reports/<chapter-slug>.md` as a standalone explanation. Every source claim
uses `[display]{.source-locator data-locator="canonical"}`. Preserve tables,
notes, ruby, and original media needed by the explanation. Source headings retain
their source topology; headings added by the explainer are editorial and must not
masquerade as source divisions. Use one uniform register across sibling reports
(Japanese default: である調). Verify that every emitted locator resolves and every
media path exists before returning the report path.
