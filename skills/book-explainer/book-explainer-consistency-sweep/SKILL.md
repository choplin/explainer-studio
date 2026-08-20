---
name: book-explainer-consistency-sweep
description: "Internal cross-chapter review for PDF and EPUB book reports that checks factual, terminology, register, and source-locator consistency before site generation."
user-invocable: false
---

# Cross-chapter consistency sweep

Read all finished `reports/*.md`, the consumer's canonical source structure, and
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
