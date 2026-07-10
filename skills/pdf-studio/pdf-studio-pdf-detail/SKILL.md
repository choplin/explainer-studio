---
name: pdf-studio-pdf-detail
description: Internal procedure for the pdf-studio-deep-dive skill — re-read a resolved page span of an already-digested PDF (visually, or from a faithful text layer) and write a thorough, standalone detail report for just that span, with [pNN] anchors. Applied by the deep-dive orchestrator (dispatched to a pdf-studio-pdf-detail subagent under Claude Code, or applied inline otherwise), and by pdf-studio-full-guide once per in-scope chapter. NOT a user-facing skill and NOT triggered directly by user requests.
user-invocable: false
---

# PDF detail drill-down

You re-read the span the caller has resolved — from the source PDF (visually) or from a pre-extracted faithful text layer — and produce a detailed report of just that part.

## When this applies

The `pdf-studio-deep-dive` skill resolves the target page range from the outline's [pNN] anchors and then applies this procedure; `pdf-studio-full-guide` applies it once per in-scope chapter. It is not for direct user requests and is not invoked proactively.

## Inputs provided by the caller

The caller provides the following. If any is missing, report what is missing and stop.

- The source to re-read, in one of two modes:
  - **Visual mode (default):** the absolute path to the target PDF, read over the page range below.
  - **Text-layer mode:** the absolute path to a pre-extracted text file that already holds the resolved span as faithful `[pNN]`-anchored text. Read that file instead of the PDF; the page range is still given for context and anchors.
- Page range to re-read (PDF page numbers, START–END; resolved from the spine's [pNN] anchors with margin pages added on each side)
- Target section: its **spine heading** (source-form title) and the **spine `[pNN]`** for that heading, if the caller resolved from `toc.md`; else a plain section name or range. Use the spine heading + anchor for the report's header when given — do not re-guess the section's starting page.
- Absolute output path (e.g. `<WORK_DIR>/reports/<section-slug>.md`)

## Constraints (strict)

- Do NOT install any software (brew / pip / uv / apt / npm, etc.).
- **Visual mode:** read the PDF ONLY via the Read tool's `pages` (max 20 pages per request; split if wider). Actually see it as images. Do NOT convert or extract the PDF with external tools (pdftoppm / pdftotext / pypdf, etc.). (Under Claude Code this runs without the Bash tool.)
- **Text-layer mode:** read ONLY the given text file with the Read tool. Do NOT also open the PDF. The text is already faithful (code, commands, numbers, console/box-drawing tables); transcribe it as-is and ignore running headers/footers (repeated page numbers / chapter titles at page tops and bottoms) — they are page furniture, not content.
- If Read errors (e.g. `pdftoppm failed:`), do not work around it — report the error verbatim and stop.
- **Anchor to the `[pNN]` a heading actually appears under — never guess a page.** In text-layer mode a heading's `[pNN]` is the marker **immediately preceding that heading line**; do not infer or round it. In visual mode, use the page the heading is physically on. An off-by-one mis-attributes section boundaries.
- **Skip near-empty pages.** A page that is essentially blank (a `[pNN]` marker with little or no text, or a visually empty page) is a blank/divider page; its content belongs to the adjacent non-empty page. Do not attribute a heading, summary, or figure to a blank page's number.
- **Stay faithful — add nothing that is not in the source.** Report only what the pages contain: no interpretation, analogy, evaluation, or connective claim the source does not make. "Faithful" means source-only — if something is your inference, do not present it as the text's.
- Write the body in the language of the source or the conversation.

## Work

- Read the given source (the PDF page range visually, or the provided text-layer file) and write a detailed report of that part. Not an overview — capture full definitions, step-by-step procedures, every figure/table, concrete examples, and caveats. In text-layer mode, preserve code / commands / numeric output verbatim (that fidelity is why the mode was chosen); values that live only inside a raster figure are absent from the text layer — do not invent them.
- Attach [pNN] (PDF page) anchors at key points.
- State the target section name and page range at the top. When the caller gave a spine heading + `[pNN]`, use them for the header (title = spine source-form title or its translation; the header's page anchor = the spine `[pNN]`). Trim blank/divider pages from the stated range's endpoints — a range never starts or ends on a near-empty page (those were margin/padding pages, not section content).

## Output

Write to the given output path — unconditionally, without prompting about an existing file. This is an orchestrator-dispatched worker; the parent skill ([[pdf-studio-deep-dive]] / [[pdf-studio-full-guide]]) handles overwrite confirmation before dispatching.

## Reply

Return only the file path and a one-line summary (do not return the body).
