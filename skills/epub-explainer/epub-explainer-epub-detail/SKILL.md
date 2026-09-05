---
name: epub-explainer-epub-detail
description: "Internal per-chapter worker invoked by book-explainer for EPUB input. Resolves a source locator to its native spine range and writes a standalone detail report."
user-invocable: false
---

# EPUB chapter detail

Apply [[explainer-content-workflow-base]] with the `book` profile. This worker must run in a fresh session
from Artifacts alone. Require the exact immutable run request; source identity;
`structured/toc.md`, `epub/source.json`, and `epub/locators.json` paths and
digests; selected source locator range; target report path; and its `create` or
`replace` action. Validate them before reading, and stop with a structured
missing or incompatible-input result rather than inferring anything from
conversation history.

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
media path exists before returning the report path and digest with the AI
acceptance-check result. `create` must fail if the target exists; `replace`
authorizes overwriting only that exact path.
