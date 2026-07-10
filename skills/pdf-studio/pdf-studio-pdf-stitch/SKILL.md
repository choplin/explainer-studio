---
name: pdf-studio-pdf-stitch
description: Internal Phase 2 procedure for the pdf-studio-summarize skill — read all Phase 1 extraction chunks, join sections split across chunk boundaries, dedupe, build the canonical structural spine toc.md from the chunks' verbatim heading streams, and assemble the outline.md against it. Applied once (single pass) by the summarize orchestrator (dispatched to a pdf-studio-pdf-stitch subagent under Claude Code, or applied inline otherwise). NOT a user-facing skill and NOT triggered directly by user requests.
user-invocable: false
---

# PDF stitch & structure (Phase 2)

You read the multiple chunk materials from Phase 1, join them across boundaries, and rebuild the document's logical structure. You do NOT yet write the final report.

You produce **two** artifacts, in this order:
1. **`toc.md` — the canonical structural spine.** Built by *merging the chunks' `## Headings` streams*, not by re-deriving structure from the prose. It is the single source of truth for what the headings are and which `[pNN]` each sits on; every downstream phase draws headings and anchors from it. This is what prevents heading drift and off-by-one anchors, because nothing downstream re-invents the structure.
2. **`outline.md` — the content outline**, whose headings are taken *from `toc.md`* (same source-form titles, same anchors), with the compressed content filled under them.

## When this applies

The `pdf-studio-summarize` skill applies this procedure once, after all Phase 1 chunk extraction completes. It is not for direct user requests and is not invoked proactively.

## Inputs provided by the caller

The caller provides the following. If any is missing, report what is missing and stop.

- Absolute path to the input directory (the extract directory containing `chunk-*.md`)
- Absolute output path for the outline (e.g. `<WORK_DIR>/structured/outline.md`); write the spine as `toc.md` beside it (`<WORK_DIR>/structured/toc.md`)
- Optional: absolute path to `ocr/figures.md` (present only when figure harvest ran). Use it to keep each figure reference attached to the section it belongs to.
- Optional: a captured printed table of contents (if the orchestrator extracted one). Use it only to **cross-check** the spine's completeness and nesting — never as the anchor source (printed page numbers are not PDF pages).

## Constraints (strict)

- Do NOT install any software (brew / pip / uv / apt / npm, etc.).
- Read all input via the Read tool. You may use Glob to enumerate `chunk-*.md`.
- Write output to the file and return only a short status to the caller. Do NOT echo the reconstructed body in your reply (to conserve the caller's context).
- Write the content in the language of the source or the conversation. Keep the structural field names below (## Page offset, ## Headings, ## Boundary notes) as written — the `pdf-studio-deep-dive` skill locates the spine's headings and the offset field by name.

## Work

1. Enumerate `chunk-*.md` in the input directory with Glob, and read every chunk with Read.
2. **Build the spine `toc.md` from the chunks' `## Headings` streams — merge, do not re-derive.** Concatenate the streams in page order, then:
   - **Dedupe boundary repeats:** the same heading may appear at the end of one chunk's stream and the start of the next; keep one entry (the one whose `[pNN]` is where the heading actually first appears).
   - **Keep source-form titles verbatim** — do not translate or reword them here (that is the report's job). This verbatim form is what makes each heading locatable in the source later.
   - **Take each heading's anchor from its stream `[pNN]`** (the marker immediately preceding the heading). Do not infer, round, or re-derive it from the prose; never anchor a heading to a blank/divider page — a trailing blank is never a heading's page.
   - **Cross-check against the captured printed TOC if one was provided:** confirm no heading is missing and the nesting matches. A disagreement (a TOC entry with no matching heading, or vice versa) is a signal of a missed/mis-read heading — note it rather than silently trusting either side. Do **not** take anchors from the printed TOC's page numbers.
3. **Assemble `outline.md` against the spine.** Its heading tree **is** `toc.md`'s (same source-form titles, same `[pNN]` anchors) — do not invent a second structure. Under each heading, join the boundary-split content, remove duplicate descriptions, and fill the compressed material. Where the report will be in another language, the outline may show the translated heading, but it must carry the same `[pNN]` as the spine entry it maps to.
4. Compress information, but do not drop definitions, important numbers, figures/tables, or key concepts. This is a cleaned-up structured outline, not a report.
5. If `ocr/figures.md` was provided (or the chunks carry a `## Figures` block), keep each figure reference — its `figures/…` path, page, and caption — under the section whose pages contain it, so Phase 3 and the Finalize sweep know where each figure belongs.

## Output

Write both files — unconditionally, without prompting about an existing file (this is an orchestrator-dispatched worker; the parent [[pdf-studio-summarize]] / [[pdf-studio-full-guide]] handles overwrite confirmation at the work-dir level).

**`toc.md`** — the canonical structural spine, one row per heading in reading order:

```
# Structure (canonical spine)

## Page offset
printed page N = PDF page N + <offset>   (or "none detected")

## Headings
- [pNN] L<level> | <source-form title, verbatim> | printed <printed-page or ->
(level: 1 = chapter/part, 2 = section, 3 = subsection, …; [pNN] is the PDF page the heading first appears on, never a blank page)
```

**`outline.md`** — the content outline. Near the top, place a `## Page offset` field (same value as the spine). Its headings match `toc.md` (source-form title or its translation, with the spine's `[pNN]`), with the compressed content under each. At the end, place a `## Boundary notes` field (what was joined, where coverage is cut off, and any TOC↔heading cross-check discrepancies).

Keep the field names `## Page offset`, `## Headings`, and `## Boundary notes` as written — downstream skills locate them by name.

## Reply

Return only: the two file paths (`toc.md`, `outline.md`), the count of spine headings, and one or two sentences on boundary decisions and any TOC cross-check discrepancy.
