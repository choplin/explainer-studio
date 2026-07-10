---
name: pdf-studio-pdf-extract
description: Internal Phase 1 procedure for the pdf-studio-summarize skill — read one page range of a PDF visually and write structured extraction material (not a finished report) to a file, including a verbatim heading stream for the structural spine. Applied once per chunk, in parallel, by the summarize orchestrator (dispatched to a pdf-studio-pdf-extract subagent under Claude Code, or applied inline otherwise). NOT a user-facing skill and NOT triggered directly by user requests.
user-invocable: false
---

# PDF chunk extraction (Phase 1)

You are the extraction phase of a book/PDF pipeline. You do NOT write a finished report. Your job is to faithfully transcribe, in structured form, what appears on the page range you are assigned, into a single file.

## When this applies

The `pdf-studio-summarize` skill splits a large PDF into chunks and applies this procedure once per chunk, in parallel. It is not for direct user requests and is not invoked proactively.

## Inputs provided by the caller

The caller provides the following. If any is missing, do not guess — report what is missing and stop.

- The source to read, in one of two modes:
  - **Visual mode (default):** the absolute path to the target PDF, plus the assigned page range (PDF page numbers, START–END).
  - **Text-layer mode:** the absolute path to a pre-extracted text file (`extract/text-<START>-<END>.md`) that already holds the assigned pages as faithful `[pNN]`-anchored text. Read that file instead of the PDF; the page range is still given for context.
- Assigned page range (PDF page numbers, START–END).
- Absolute output path (e.g. `<WORK_DIR>/extract/chunk-<START>-<END>.md`).
- **Assigned figures (optional):** rows from `ocr/figures.md` (label / file / page / caption) for figures whose page falls in this range. Record each in the material (see the format) so none is dropped downstream.

## Constraints (strict)

- Do NOT install any software (brew / pip / uv / apt / npm, etc.). poppler and similar tools are assumed to be pre-installed in the environment.
- **Visual mode:** read the PDF ONLY via the Read tool's `pages` parameter. Actually "see" the PDF as images. Do NOT convert or extract the PDF with external tools (pdftoppm / pdftotext / pypdf, etc.). (Under Claude Code this runs without the Bash tool, so no workaround is possible anyway.)
- **Text-layer mode:** read ONLY the given text file with the Read tool. Do NOT also open the PDF. The text is already faithful (code, commands, numbers, console/box-drawing tables); transcribe it as-is and ignore running headers/footers (page numbers, chapter titles repeated at page tops/bottoms) — they are page furniture, not content.
- **Anchor each heading to the `[pNN]` it actually appears under — never guess a page.** In text-layer mode every page is prefixed with its own `[pNN]` marker; a heading's `[pNN]` is the marker **immediately preceding that heading line**, not an inferred or rounded number. In visual mode, use the page the heading is physically on. An off-by-one here mis-attributes chapter/section boundaries in every downstream artifact.
- **Skip near-empty pages — do not attribute content to a blank.** A page whose text-layer body is essentially empty (a `[pNN]` marker followed by little or no alphanumeric text) is a blank or divider page; its heading/summary/figure belongs to the adjacent non-empty page, not to the blank page's number.
- **Record every document heading verbatim in the `## Headings` stream — do not translate or reword it there.** The document's own chapter/section/subsection titles are captured, exactly as printed (source form), as the canonical structural stream that Phase 2 merges into `toc.md`. Translation and rewording happen later in the report, never in this stream: a heading's source form is what makes it locatable in the source afterward. Capture only real document headings — not running headers/footers, not figure/table captions.
- If the Read tool errors (e.g. `pdftoppm failed:`), do not work around it — report the error verbatim and stop.
- Write output to the file and return only a short status to the caller. Do NOT include the extracted body itself in your reply (to conserve the caller's context).
- Write the extracted content in the language of the source PDF or the conversation. Keep the structural field names in the format below (## Meta, ## Headings, ## Extracted content) as written.

## Steps

1. Read the source: **visual mode** — the PDF with the Read tool, `pages="<START>-<END>"` (max 20 pages per request; split into several requests if the range is wider); **text-layer mode** — the given `extract/text-<START>-<END>.md` file (already `[pNN]`-anchored faithful text).
2. Transcribe each page's content as structured Markdown in the format below. Do not over-summarize; keep enough information density that the later phase can rebuild the chapter structure. Do not drop definitions, numbers, figures/tables, or key terms. In text-layer mode, preserve code / commands / numeric output verbatim (that fidelity is the reason the mode was chosen).
3. As you go, list every document heading you cross in the `## Headings` stream (see format): its level, its **source-form title verbatim** (untranslated, unreworded), and the `[pNN]` immediately preceding it. This stream is structure only — the prose transcription still lives in `## Extracted content`.
4. If assigned figures were provided, add each to the `## Figures` block (see format) — its `figures/…` path, page, and caption — so no harvested figure is lost.
5. Write the output to the given output path. This is an orchestrator-dispatched worker: write unconditionally and do **not** prompt about an existing file — overwrite confirmation is handled once by the parent skill ([[pdf-studio-summarize]] / [[pdf-studio-full-guide]]) at the work-dir level.

## Output format

```
# Chunk (PDF pages <START>-<END>)

## Meta
- Start state: document start / mid-section
- End state: complete / may continue into next chunk mid-section
- Opening context: 1–2 sentences on the heading/topic at the start of <START>
- Ending context: 1–2 sentences on the heading/topic at the end of <END> (so the next chunk's handler can connect)

## Headings
(the document's own structure crossed in this range, in reading order — the canonical structural stream Phase 2 merges into toc.md. Source-form titles verbatim; no translation, no rewording. One row per heading.)
- [pNN] L<level> | <source-form heading title, exactly as printed> | printed <printed-page-number or ->
(level: 1 = chapter/part, 2 = section, 3 = subsection, …; the heading's `[pNN]` follows the anchoring rule in Constraints — text-layer: the marker immediately preceding the heading line; visual: the page the heading is physically on)

## Extracted content
### [pNN] Heading / section name
- Key points: ...
- Important definitions / facts / numbers: ...
- Figures/tables: [pNN] caption and summary
(repeat per page and heading. [pNN] is the actual PDF page number; also note the printed page number if present)

## Figures
(only if assigned figures were provided; one row per harvested figure so downstream reports can reference and explain it)
- [pNN] `figures/fig-pNNN-K.ext` — <label>: <caption> — <one-line note on what it shows>
```

## Reply

Return only: the path written, the end state (complete / continued), and one sentence each of opening and ending context.
