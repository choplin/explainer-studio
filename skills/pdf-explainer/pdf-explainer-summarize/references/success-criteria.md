## Success criteria (verify the deliverable, not the steps)

- [ ] Every `extract/chunk-*.md` and `outline.md` carries `[pNN]` PDF-page anchors.
- [ ] `structured/toc.md` exists: one row per heading with a source-form (verbatim) title and its `[pNN]`, built by merging the chunks' heading streams (not re-derived from prose); no heading is anchored to a blank/divider page.
- [ ] `outline.md`'s heading tree matches `toc.md` (same headings, same anchors) and has no section duplicated across a former chunk boundary; it records where coverage stops.
- [ ] `reports/overview.md` covers every top-level section present in `toc.md` (no section silently dropped), and each heading it carries maps to a spine heading with the same `[pNN]` (the Finalize containment check passed).
- [ ] `reports/overview.md` held the **altitude cap**: its headings are top-level (chapter) spine headings only — no h3/h4 section-by-section summaries — each chapter is 2–4 sentences with at most one representative figure, and section-level `[pNN]` indexing lives in the navigation table rather than in enumerated section headings.
- [ ] `reports/overview.md` reads as one standalone piece: sections connect, non-obvious terms are defined at first use, and it is followable without the source (a light coherence pass, not a source-faithfulness sweep).
- [ ] The body-start page was detected; front matter (TOC/preface) was not transcribed as content.
- [ ] If the run was a partial page range, `reports/overview.md` states the covered range and the continuation point.
- [ ] If the figure-harvest runtime resolved (via `preflight.sh` — PATH/uv/nix), `ocr/figures.md` exists and every figure a report embeds is explained in place (no bare image); unused crops may remain unreferenced (no exhaustive-coverage requirement). If the runtime was unresolvable, the handoff inventory says figure harvest was skipped.
- [ ] If the text-layer option was chosen, each chunk was read from `extract/text-*.md` (not visually), and it was offered only after the born-digital probe passed.
