---
name: pdf-studio-deep-dive
description: This skill should be used when a PDF has already been digested by pdf-studio-summarize (an outline.md with page anchors exists) and the user now wants a DEEPER, more detailed report on one specific part. Triggers on "1.3節をもっと詳しく", "第2章を深掘りして", "p50-60の詳細レポートが欲しい", "expand the section on X", "drill into chapter 2", "give me the full detail of that part". It resolves the location to source pages via the outline's [pNN] anchors, re-reads only those pages, and writes a standalone detailed report. Should NOT trigger for a first full-document pass (use pdf-studio-summarize) or when no outline / source PDF exists yet.
version: 0.2.0
user-invocable: true
---

# PDF Deep Dive

Produce a detailed, standalone report for one part of an already-digested PDF by zooming back into the original pages. This is the "zoom in" counterpart to [[pdf-studio-summarize]]: the first pass produces a compressed overview and cannot recover detail it dropped, so detail is recovered on demand by re-reading the source — made possible by the `[pNN]` page anchors the pipeline preserved.

## When this applies

Use only when both exist: the source PDF, and a first-pass `outline.md` (or `reports/overview.md`) carrying `[pNN]` anchors. If no digest exists yet, run [[pdf-studio-summarize]] first. If the whole document needs detail, that is a re-run of the pipeline, not this skill.

`<WORK_DIR>` is the digest directory [[pdf-studio-summarize]] created, named after the PDF's basename (`<dir>/<name>/`), holding `structured/outline.md`, `reports/overview.md`, and this skill's own `reports/<section>.md` output. [[pdf-studio-summarize]] collects the source PDF into the work dir as `<WORK_DIR>/<name>.pdf`, so use that as the target PDF. If the source was not collected (the user declined the move), fall back to the original sibling path `<dir>/<name>.pdf`. Do not invent another location.

## Gotchas

- **The Read tool's PDF vision requires system `poppler` (`pdftoppm`).** Same dependency as the pipeline — if reading fails with `pdftoppm failed:`, install poppler (`brew install poppler` / `apt-get install poppler-utils`) rather than working around it.
- **Text-layer option (born-digital PDFs only), symmetric to the summary phase.** By default the span is re-read visually. If the source is a born-digital ebook, reading it through the text layer (`pdftotext -layout`) reproduces its code / commands / numbers / console-and-box-drawing tables far more faithfully than visual reading. Gate it on the born-digital probe and use it only if the user opts in; a scanned/captured PDF has no text layer, so never force it. **Reuse [[pdf-studio-summarize]]'s bundled scripts — do not reimplement or install anything.** They live in that skill's own dir, referenced by skill name: `pdf-studio-summarize/scripts/text_layer.sh` (probe + extraction) run through `pdf-studio-summarize/scripts/preflight.sh`, which resolves poppler from PATH or the bundled `flake.nix` so it works on a nix-only host. If `pdf-studio-summarize` is not installed, read visually rather than guessing a path. Known trade-off (see [[pdf-studio-summarize]]): the text layer is faithful to code/tables/numbers but drops values that exist only as pixels inside a raster figure — visual mode reads those.
- **Anchors are PDF page numbers, not printed page numbers.** Resolve the requested location to `pNN` PDF pages before reading. If the user gives a printed page number, convert it using the `## Page offset` field recorded in `outline.md`.
- **Re-read the source, do not just re-summarize the outline.** The whole point is to recover detail the overview compressed away. Reading only `outline.md` again produces no new information.
- **Add margin pages.** A section rarely starts and ends exactly on the anchored pages. Read a few pages before the first anchor and after the last so the section is captured whole.
- **Don't silently overwrite an existing report.** If `<WORK_DIR>/reports/<section-slug>.md` already exists (a prior deep-dive, possibly hand-edited), confirm before replacing it — overwrite, keep it, or write under a different slug.

## Procedure

1. **Resolve the location to source pages.** Read `<WORK_DIR>/structured/outline.md`. Find the requested section (by heading name) or accept an explicit page range. Collect its `[pNN]` anchors and take the min/max, then pad by ~2 pages each side. If the user gave a section name, also read the adjacent headings' anchors to bound the range.
2. **Confirm scope if ambiguous.** If the location matches multiple sections or is vague, confirm the exact section/range before spending a read.
3. **Choose the text source.** If invoked from [[pdf-studio-full-guide]], use the text-source choice it already made in its Step 0 — do not re-ask. Otherwise decide here: probe born-digital once with `bash pdf-studio-summarize/scripts/preflight.sh bash pdf-studio-summarize/scripts/text_layer.sh --probe <pdf> <span-start>` (any page in the resolved span). If it passes, offer the **text-layer** option (more faithful for code / commands / numbers / console output, born-digital only) and honor the user's choice; if it fails or the user declines, read visually. Default: visual.
   - **Text-layer mode only:** materialize the span's faithful text before dispatching — `bash pdf-studio-summarize/scripts/preflight.sh bash pdf-studio-summarize/scripts/text_layer.sh <pdf> <WORK_DIR>/extract/text-<START>-<END>.md <START> <END>` (create `<WORK_DIR>/extract/` if the summary run's copy is gone). This writes a file, so no page content enters this orchestrator's context. Pass the worker that text file's path instead of a page range.
4. **Re-read the source and write the detail report.** Apply the **`pdf-studio-pdf-detail`** skill to Read the resolved span — visually, or from the materialized text-layer file — and write a thorough, faithful report of just that span: full definitions, step-by-step explanations, every figure/table, examples, and caveats, with `[pNN]` anchors throughout. Its procedure already carries the constraints (no software installs, Read tool only, no ad-hoc PDF conversion, faithful/source-only, report Read errors instead of working around them).
   - **Under Claude Code**, dispatch the `pdf-studio-pdf-detail` subagent so the reads stay out of this orchestrator's context (the subagent has no Bash tool).
   - **Otherwise**, apply the `pdf-studio-pdf-detail` skill inline.
   Pass in the call message only: the source (**visual mode** — the PDF absolute path and the resolved page range START–END, margins included; **text-layer mode** — the absolute path to `<WORK_DIR>/extract/text-<START>-<END>.md`, still noting the START–END range for anchors), the target section name/range, and the output path `<WORK_DIR>/reports/<section-slug>.md`. It returns only the file path and a one-line summary.
5. **Coherence self-check — does it stand alone as a readable piece (no source re-read).** The worker wrote the report and returned only a one-line summary, so read the finished `<WORK_DIR>/reports/<section-slug>.md` back once and confirm it works as a self-contained read: top to bottom the explanation connects, every term or concept is introduced before it is used (nothing appears undefined), and a reader who opens only this file — without the overview or the source — can follow it. This is a light editorial pass on the produced report only: **do not re-read the source PDF** (the faithful re-read already happened in step 4) and do not reconcile against sibling reports. Fix small gaps inline (a one-line definition, a bridging sentence); if it already reads cleanly, leave it.

## Success criteria

- [ ] The report re-reads the source (the PDF pages visually, or the materialized text layer — not just the outline) and contains at least one concrete element (full definition, worked example, figure/table caption, or step) not present in the corresponding outline.md section.
- [ ] If the text-layer option was used, it was offered only after the born-digital probe passed, the span's text was materialized via [[pdf-studio-summarize]]'s `text_layer.sh`, and the worker read that file (not the PDF).
- [ ] The resolved page range fully contains the requested section (margins included; not cut off at an anchor).
- [ ] `[pNN]` anchors are present so the detail remains traceable.
- [ ] The output is a standalone file under `reports/` (a `<section>.md`, not `overview.md`), leaving the first-pass `reports/overview.md` untouched.
- [ ] The report reads as a standalone piece: opening only that file, a reader can follow it (terms introduced before use, explanation connects) — a light coherence pass, not a source re-read.
