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
- **Anchors are PDF page numbers, not printed page numbers.** Resolve the requested location to `pNN` PDF pages before reading. If the user gives a printed page number, convert it using the `## Page offset` field recorded in `outline.md`.
- **Re-read the source, do not just re-summarize the outline.** The whole point is to recover detail the overview compressed away. Reading only `outline.md` again produces no new information.
- **Add margin pages.** A section rarely starts and ends exactly on the anchored pages. Read a few pages before the first anchor and after the last so the section is captured whole.
- **Don't silently overwrite an existing report.** If `<WORK_DIR>/reports/<section-slug>.md` already exists (a prior deep-dive, possibly hand-edited), confirm before replacing it — overwrite, keep it, or write under a different slug.

## Procedure

1. **Resolve the location to source pages.** Read `<WORK_DIR>/structured/outline.md`. Find the requested section (by heading name) or accept an explicit page range. Collect its `[pNN]` anchors and take the min/max, then pad by ~2 pages each side. If the user gave a section name, also read the adjacent headings' anchors to bound the range.
2. **Confirm scope if ambiguous.** If the location matches multiple sections or is vague, confirm the exact section/range before spending a read.
3. **Re-read the source pages and write the detail report.** Apply the **`pdf-studio-pdf-detail`** skill to Read the resolved PDF page span visually and write a thorough, faithful report of just that span — full definitions, step-by-step explanations, every figure/table, examples, and caveats — with `[pNN]` anchors throughout. Its procedure already carries the constraints (no software installs, Read tool `pages` only, no PDF conversion, report Read errors instead of working around them).
   - **Under Claude Code**, dispatch the `pdf-studio-pdf-detail` subagent so the page reads stay out of this orchestrator's context (the subagent has no Bash tool).
   - **Otherwise**, apply the `pdf-studio-pdf-detail` skill inline.
   Pass in the call message only: the PDF absolute path, the resolved page range (START–END, margins included), the target section name/range, and the output path `<WORK_DIR>/reports/<section-slug>.md`. It returns only the file path and a one-line summary.

## Success criteria

- [ ] The report re-reads the source PDF pages (not just the outline) and contains at least one concrete element (full definition, worked example, figure/table caption, or step) not present in the corresponding outline.md section.
- [ ] The resolved page range fully contains the requested section (margins included; not cut off at an anchor).
- [ ] `[pNN]` anchors are present so the detail remains traceable.
- [ ] The output is a standalone file under `reports/` (a `<section>.md`, not `overview.md`), leaving the first-pass `reports/overview.md` untouched.
