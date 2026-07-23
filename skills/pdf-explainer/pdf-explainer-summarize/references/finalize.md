## Finalize

### 1. Figures — use what the summary needs, no exhaustive sweep (only if Phase 0 produced `ocr/figures/`)

Figures aid the reports; they are not a checklist. Embed a harvested figure only where the prose actually discusses what it shows, and when you embed it, explain it (never a bare image). **Do not force every crop into the report to "cover" it** — this is a book, not a paper, so referencing every figure is not required. But do not make an omission invisible either: when the span had harvested figures you chose not to embed, **list them once at the end by ID with a one-line reason** — a transparency inventory, not a padded gallery — so a dropped figure is visible rather than silently gone. If you *do* want a figure that `figures.md` marks "⚠ Not extracted", render and crop its page first (`pdftoppm -f N -l N -singlefile -r 200 -png <pdf> <tmp>/pg`) before embedding it.

### 2. Anchor containment against the spine — a structural check, not a source re-read

A cheap, deterministic guard that the overview's anchors did not drift from the canonical structure. Read only `structured/toc.md` and `reports/overview.md` (both small; **do not re-read the source PDF or the outline body**). Confirm:

- Every section heading in `overview.md` corresponds to a spine heading (by source-form title, or its translation) — the overview introduces no heading the spine does not have.
- Each such heading carries the **same `[pNN]`** the spine records for it.

Any mismatch is an anchor that drifted while writing the overview — fix it to the spine's anchor (the spine is authoritative). This is the mechanical anchor check reduced to a containment test: because headings and anchors are sourced from the spine, there is no fuzzy source-matching to do here, and a heading the check cannot locate in the spine is itself the finding. If the spine and overview agree, done.

### 3. Coherence self-check — does it read as one standalone piece (no source re-read)

The overview is compressed from the stitched `outline.md`, and for large documents it is built by multi-level reduce (section → chapter → whole) — a path where a term's first-use definition or the granularity can silently drift between levels, and a proper noun's classifying attribute (column- vs row-oriented, etc.) can flip during rewording. Do one light editorial pass to catch that. This is **not** the paper-explainer faithfulness sweep: **do not re-read the source PDF, and do not re-read the outline's body** — read only the finished `reports/overview.md`, using `outline.md` solely as a checklist of which sections should be present. It is a book, not a paper, so keep it light — fix what you find, don't manufacture work.

Read the overview top to bottom as a first-time reader and check:
- **Continuity** — the sections connect; there is no jump where the prose assumes a step the report never made.
- **Terms defined before use** — every non-obvious term or concept is introduced where it first appears, not used cold and defined later (or never).
- **Consistent altitude** — every chapter is treated at the same level (a 2–4 sentence chapter summary), and no chapter is a terse stub next to a deep one for no reason (a symptom of an uneven reduce). Check the cap held: **no h3/h4 section-by-section summaries crept in**. A section-level tree means the overview has drifted into being a second digest — cut it back to chapter level and move that indexing into the navigation table. Note this check is about *altitude*, not uniform coverage: it must never be read as "give every section equal treatment."
- **Self-contained** — a reader who opens only this file, without the source, can follow it.

Fix issues inline (a one-line definition, a bridging sentence, a granularity trim). If it already reads cleanly, that is a valid outcome — note it and move on.

### 4. Collect the source PDF (confirm first)

To make the work dir a single self-contained folder, move the source PDF into it as `<WORK_DIR>/<name>.pdf` as the last step.

- **This relocates the user's original file, so confirm first.** Ask the user before moving; if they decline, leave the PDF where it is — the digest is already complete either way. Never move without an explicit yes.
- If the PDF is already inside the work dir (a re-run, or the user moved it earlier), there is nothing to do.
- Once collected, the source for later full-guide chapter-detail workers is `<WORK_DIR>/<name>.pdf`.
