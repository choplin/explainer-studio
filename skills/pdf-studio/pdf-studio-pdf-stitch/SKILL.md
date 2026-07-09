---
name: pdf-studio-pdf-stitch
description: Internal Phase 2 procedure for the pdf-studio-summarize skill — read all Phase 1 extraction chunks, join sections split across chunk boundaries, dedupe, and rebuild the chapter→section hierarchy into a structured outline.md. Applied once (single pass) by the summarize orchestrator (dispatched to a pdf-studio-pdf-stitch subagent under Claude Code, or applied inline otherwise). NOT a user-facing skill and NOT triggered directly by user requests.
version: 0.2.0
user-invocable: false
---

# PDF stitch & structure (Phase 2)

You read the multiple chunk materials from Phase 1, join them across boundaries, and rebuild the document's logical structure. You do NOT yet write the final report.

## When this applies

The `pdf-studio-summarize` skill applies this procedure once, after all Phase 1 chunk extraction completes. It is not for direct user requests and is not invoked proactively.

## Inputs provided by the caller

The caller provides the following. If any is missing, report what is missing and stop.

- Absolute path to the input directory (the extract directory containing `chunk-*.md`)
- Absolute output path (e.g. `<WORK_DIR>/structured/outline.md`)
- Optional: absolute path to `ocr/figures.md` (present only when figure harvest ran). Use it to keep each figure reference attached to the section it belongs to.

## Constraints (strict)

- Do NOT install any software (brew / pip / uv / apt / npm, etc.).
- Read all input via the Read tool. You may use Glob to enumerate `chunk-*.md`.
- Write output to the file and return only a short status to the caller. Do NOT echo the reconstructed body in your reply (to conserve the caller's context).
- Write the content in the language of the source or the conversation. Keep the structural field names below (## Page offset, ## Boundary notes) as written — the `pdf-studio-deep-dive` skill locates the offset field by name.

## Work

1. Enumerate `chunk-*.md` in the input directory with Glob, and read every chunk with Read.
2. Join boundaries: connect a section cut off at the end of one chunk with the section continuing at the start of the next. Remove duplicate descriptions. Unify translation/heading variance by noting both.
3. Rebuild the logical structure: reorganize the scattered extracted content into chapter > section > subsection.
4. Preserve page anchors [pNN] (PDF pages). Note printed page numbers too if known.
5. Compress information, but do not drop definitions, important numbers, figures/tables, or key concepts. This is a cleaned-up structured outline, not a report.
6. If `ocr/figures.md` was provided (or the chunks carry a `## Figures` block), keep each figure reference — its `figures/…` path, page, and caption — under the section whose pages contain it, so Phase 3 and the Finalize sweep know where each figure belongs.

## Output

Write to the given output path — unconditionally, without prompting about an existing file (this is an orchestrator-dispatched worker; the parent [[pdf-studio-summarize]] / [[pdf-studio-full-guide]] handles overwrite confirmation at the work-dir level). Near the top, place a `## Page offset` field recording the correspondence between printed and PDF page numbers (e.g. "printed page N = PDF page N + 27", or "none detected"). At the end, place a `## Boundary notes` field (what was joined, and where coverage is cut off).

## Reply

Return only: the file path, a bulleted list of the reconstructed chapter/section headings, and one or two sentences on boundary decisions.
