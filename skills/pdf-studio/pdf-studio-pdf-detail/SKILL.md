---
name: pdf-studio-pdf-detail
description: Internal procedure for the pdf-studio-deep-dive skill — re-read a resolved page span of an already-digested PDF visually and write a thorough, standalone detail report for just that span, with [pNN] anchors. Applied by the deep-dive orchestrator (dispatched to a pdf-studio-pdf-detail subagent under Claude Code, or applied inline otherwise), and by pdf-studio-full-guide once per in-scope chapter. NOT a user-facing skill and NOT triggered directly by user requests.
version: 0.2.0
user-invocable: false
---

# PDF detail drill-down

You re-read the page range the caller has resolved, from the source PDF, and produce a detailed report of just that part.

## When this applies

The `pdf-studio-deep-dive` skill resolves the target page range from the outline's [pNN] anchors and then applies this procedure; `pdf-studio-full-guide` applies it once per in-scope chapter. It is not for direct user requests and is not invoked proactively.

## Inputs provided by the caller

The caller provides the following. If any is missing, report what is missing and stop.

- Absolute path to the target PDF
- Page range to re-read (PDF page numbers, START–END; resolved from the outline's [pNN] anchors with margin pages added on each side)
- Target section name or range
- Absolute output path (e.g. `<WORK_DIR>/reports/<section-slug>.md`)

## Constraints (strict)

- Do NOT install any software (brew / pip / uv / apt / npm, etc.).
- Read the PDF ONLY via the Read tool's `pages` (max 20 pages per request; split if wider). Actually see it as images.
- Do NOT convert or extract the PDF with external tools (pdftoppm / pdftotext / pypdf, etc.). (Under Claude Code this runs without the Bash tool.)
- If Read errors (e.g. `pdftoppm failed:`), do not work around it — report the error verbatim and stop.
- Write the body in the language of the source or the conversation.

## Work

- Read the given range visually and write a detailed report of that part. Not an overview — capture full definitions, step-by-step procedures, every figure/table, concrete examples, and caveats.
- Attach [pNN] (PDF page) anchors at key points.
- State the target section name and page range at the top.

## Output

Write to the given output path — unconditionally, without prompting about an existing file. This is an orchestrator-dispatched worker; the parent skill ([[pdf-studio-deep-dive]] / [[pdf-studio-full-guide]]) handles overwrite confirmation before dispatching.

## Reply

Return only the file path and a one-line summary (do not return the body).
