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
- **Assigned figure crops for this span (optional):** rows from `ocr/figures.md` (label / file / page / caption) whose page falls in the range, plus the crop file paths. Read them to describe in-figure content. In text-layer mode these crops are the *only* way to see values baked into diagrams (the text layer drops them), so they are not optional context there — read every one provided.
- Absolute output path (e.g. `<WORK_DIR>/reports/<section-slug>.md`)

## Constraints (strict)

- Do NOT install any software (brew / pip / uv / apt / npm, etc.).
- **Visual mode:** read the PDF ONLY via the Read tool's `pages` (max 20 pages per request; split if wider). Actually see it as images. Do NOT convert or extract the PDF with external tools (pdftoppm / pdftotext / pypdf, etc.). (Under Claude Code this runs without the Bash tool.)
- **Text-layer mode:** read the given text file with the Read tool, and — if the caller provided assigned figure crops for this span — also Read those image files (`ocr/figures/fig-*.ext`). Do NOT rasterize or open the source PDF itself. The text is already faithful (code, commands, numbers, console/box-drawing tables); transcribe it as-is and ignore running headers/footers (repeated page numbers / chapter titles at page tops and bottoms) — they are page furniture, not content. The figure crops carry values that live only as pixels inside a diagram (a bit array, a tree's node keys, numbers baked into a chart) — read those from the crop; the text layer does not have them, and the crop is a faithful image of the source, not a guess.
- If Read errors (e.g. `pdftoppm failed:`), do not work around it — report the error verbatim and stop.
- **Anchor to the `[pNN]` a heading actually appears under — never guess a page.** In text-layer mode a heading's `[pNN]` is the marker **immediately preceding that heading line**; do not infer or round it. In visual mode, use the page the heading is physically on. An off-by-one mis-attributes section boundaries.
- **Skip near-empty pages.** A page that is essentially blank (a `[pNN]` marker with little or no text, or a visually empty page) is a blank/divider page; its content belongs to the adjacent non-empty page. Do not attribute a heading, summary, or figure to a blank page's number.
- **Stay faithful — add nothing that is not in the source.** Report only what the pages contain: no interpretation, analogy, evaluation, or connective claim the source does not make. "Faithful" means source-only — if something is your inference, do not present it as the text's.
- **Do not flip a term's classifying attribute when rewording.** When you paraphrase or translate, a value bound to a proper noun — column-oriented vs row-oriented, synchronous vs asynchronous, leader vs follower, CP vs AP — must survive the rewrite unchanged. Before finalizing, re-check each such attribute against the source; a flipped attribute is a factual error even when the prose reads well. If two statements in your report would contradict each other (e.g. a system called column-oriented in one place and row-oriented in another), treat that self-contradiction as the signal to re-read the source and settle it.
- Write the body in the language of the source or the conversation. Use a single consistent register throughout — for Japanese output, **である調（常体）** — and do not drift between plain and polite forms within the report.

## Work

**Accuracy is the top priority: when readability, concision, or prose flow conflict with source fidelity, fidelity wins.**

- Read the given source (the PDF page range visually, or the provided text-layer file plus any assigned figure crops) and write a detailed report of that part. Not an overview — capture full definitions, step-by-step procedures, every figure/table, concrete examples, and caveats. In text-layer mode, preserve code / commands / numeric output verbatim (that fidelity is why the mode was chosen).
- **Figures: read, don't invent — and don't discard what you can read.** Only *guessing* at a figure's hidden internals is forbidden; describing what is actually legible is required. When a figure crop is available (visual mode, or an assigned crop in text-layer mode), give its caption **and** its readable content — the tree's node keys, the bit array's cells, the values on a chart. The one thing you must not invent is a value that exists only as pixels and was given no crop. Never drop a figure's content merely because it is not in the text layer when the crop lets you read it.
- **Keep it scannable as well as readable.** Prose flow and pick-up-and-scan structure must coexist: keep section subheadings, and render procedures, enumerations, and runs of numbers/parameters as bulleted lists with per-item `[pNN]` anchors rather than melting them into a paragraph. Readability never justifies dropping a subheading or an anchor.
- Attach [pNN] (PDF page) anchors at key points.
- State the target section name and page range at the top. When the caller gave a spine heading + `[pNN]`, use them for the header (title = spine source-form title or its translation; the header's page anchor = the spine `[pNN]`). Trim blank/divider pages from the stated range's endpoints — a range never starts or ends on a near-empty page (those were margin/padding pages, not section content).

## End-of-report devices (presence-gated)

Append these standalone sections **after** the prose body, each only when its material actually exists in the span. This is presence-gated, not always-on: never fabricate one to fill a slot, and omit it silently when the material is absent (forcing an empty or padded table violates accuracy-first).

- **Quick-reference / comparison table** — when the span defines a meaningful set of key terms, lists numbers/parameters, or contrasts several mechanisms, collect them into a table (term / definition / `[pNN]`, or a mechanism-vs-property matrix). **Transcribe only what the body already states** — do not manufacture a new summary or infer values. Skip it when the span has too few such items to be worth tabulating.
- **Citation-key → page index** — when the body cites external reference keys (`[SMITH99]`-style), list each key with the `[pNN]` pages where it appears, so a citation is traceable to its source pages. Harvest the keys mechanically from the body (no fidelity risk); omit the section entirely when the span cites none.
- **Omitted-figure inventory** — when the span had assigned figure crops you did not embed, list each by ID with a one-line reason, so a dropped figure is visible rather than silently gone (the transparency note, applied to every span, not just some).

## Output

Write to the given output path — unconditionally, without prompting about an existing file. This is an orchestrator-dispatched worker; the parent skill ([[pdf-studio-deep-dive]] / [[pdf-studio-full-guide]]) handles overwrite confirmation before dispatching.

## Reply

Return only the file path and a one-line summary (do not return the body).
