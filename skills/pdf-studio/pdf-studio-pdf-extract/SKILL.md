---
name: pdf-studio-pdf-extract
description: Internal Phase 1 procedure for the pdf-studio-summarize skill — read one page range of a PDF visually and write structured extraction material (not a finished report) to a file. Applied once per chunk, in parallel, by the summarize orchestrator (dispatched to a pdf-studio-pdf-extract subagent under Claude Code, or applied inline otherwise). NOT a user-facing skill and NOT triggered directly by user requests.
version: 0.1.0
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
- If the Read tool errors (e.g. `pdftoppm failed:`), do not work around it — report the error verbatim and stop.
- Write output to the file and return only a short status to the caller. Do NOT include the extracted body itself in your reply (to conserve the caller's context).
- Write the extracted content in the language of the source PDF or the conversation. Keep the structural field names in the format below (## Meta, ## Extracted content) as written.

## Steps

1. Read the source: **visual mode** — the PDF with the Read tool, `pages="<START>-<END>"` (max 20 pages per request; split into several requests if the range is wider); **text-layer mode** — the given `extract/text-<START>-<END>.md` file (already `[pNN]`-anchored faithful text).
2. Transcribe each page's content as structured Markdown in the format below. Do not over-summarize; keep enough information density that the later phase can rebuild the chapter structure. Do not drop definitions, numbers, figures/tables, or key terms. In text-layer mode, preserve code / commands / numeric output verbatim (that fidelity is the reason the mode was chosen).
3. If assigned figures were provided, add each to the `## Figures` block (see format) — its `figures/…` path, page, and caption — so no harvested figure is lost.
4. Write the output to the given output path.

## Output format

```
# Chunk (PDF pages <START>-<END>)

## Meta
- Start state: document start / mid-section
- End state: complete / may continue into next chunk mid-section
- Opening context: 1–2 sentences on the heading/topic at the start of <START>
- Ending context: 1–2 sentences on the heading/topic at the end of <END> (so the next chunk's handler can connect)

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
