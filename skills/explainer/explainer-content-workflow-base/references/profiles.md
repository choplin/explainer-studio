# Workflow profiles

## Book

- Coordinator: [[book-explainer]]
- Adapters: PDF and DRM-free reflowable EPUB
- PDF structure: `structured/toc.md`, `structured/outline.md`
- EPUB structure/evidence: `structured/toc.md`, `structured/outline.md`,
  `epub/source.json`, `epub/locators.json`
- Reports: `reports/overview.md` and selected source-division reports
- PDF report owners: [[pdf-explainer-summarize]],
  [[pdf-explainer-pdf-detail]]
- EPUB report owners: [[epub-explainer-summarize]],
  [[epub-explainer-epub-detail]]
- Report consistency: [[book-explainer-consistency-sweep]]
- Reading site: [[book-explainer-generate-site]]

Keep the authored book divisions and order as the canonical navigation and
explanatory backbone. Never classify a report as a separate design hierarchy
merely because it is detailed.

## Paper

- Coordinator: [[paper-explainer]]
- Adapter: PDF through local paper extraction
- Structure authority: `source-structure.md`
- Evidence authority: `spine.md`, `paper.bib`, and `ocr/` source artifacts
- Reports: `reports/overview.md` plus selected `background`, `method`,
  `experiments`, `discussion`, and `related-work` reports
- Report owner: [[paper-explainer-summarize]], which delegates perspective work
  to [[paper-explainer-paper-detail]]
- Report consistency: [[paper-explainer-consistency-sweep]]; the summary owner
  invokes it during Finalize
- Reading site: [[paper-explainer-generate-site]]

For a new source, perform only the read-only bibliographic inspection needed to
resolve the `{year}-{venue}-{short-title}` citation slug before creating the run
request. Record the resulting final work-directory path there; the report phase
must not rename it afterward. Direct standalone use of the report owner may keep
its existing provisional-directory procedure.

Keep the paper's authored section topology distinct from the editorial
perspective report set. The Content brief may connect them but must not present
perspectives as source-authored sections.

## Shared downstream owners

- Content model: [[explainer-content-model]]
- Planning: [[explainer-run-plan]]
- Dialogue: [[explainer-audio-dialogue]]
- Narration: [[explainer-audio-narrate]]
- Cross-medium consistency: [[explainer-cross-medium-consistency]]
- Publishing: [[explainer-reading-site-deploy]], only after a separate explicit
  request
