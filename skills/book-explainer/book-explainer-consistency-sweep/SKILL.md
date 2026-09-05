---
name: book-explainer-consistency-sweep
description: "Internal report-consistency phase for PDF and EPUB books. Check all in-scope reports against canonical source structure and typed source locators before shared content modeling."
user-invocable: false
---

# Book consistency sweep

Apply [[explainer-content-workflow-base]], read its Artifact contract, and
require the `book` profile. Use only exact Artifacts supplied by the coordinator;
do not infer current inputs from conversation or version numbers.

Require the run request, all in-scope finished reports, the canonical source
structure, and
its locator authority (`structured/toc.md` for PDF; `structured/toc.md` plus
`epub/locators.json` for EPUB). Check:

- contradictory classifications, names, quantities, or relationships;
- terminology and prose-register drift;
- headings attributed to the source that are absent from the canonical structure;
- malformed or missing source references: PDF `.p` anchors or EPUB
  `.source-locator` spans;
- EPUB locators absent from the map and referenced media absent from disk.

For a factual conflict, reread the narrow source locus and align every affected
report to the source. Apply targeted edits; do not regenerate reports or merely
make them agree. Return a concise list of fixes and any unresolved source gap.
