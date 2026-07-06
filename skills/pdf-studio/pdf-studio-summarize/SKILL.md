---
name: pdf-studio-summarize
description: This skill should be used when the user wants to turn a large PDF (a book, manual, or long document — roughly 30+ pages) into a Markdown report, digest, or summary. Triggers on requests like "PDFをレポートにして", "この本を要約して/レポート化して", "turn this PDF into a markdown report", "generate a digest of this document", "read this whole PDF and summarize it". It runs a phased, subagent-orchestrated extract→structure→report pipeline that avoids page-boundary inconsistencies and keeps the orchestrator's context small enough to scale to hundreds of pages. Should NOT trigger for short PDFs under ~30 pages (read them directly with the Read tool), for academic conference/journal papers or preprints regardless of length (use paper-studio-summarize if installed — it produces the Ochiai-format overview and dblp-verified bibliography this pipeline does not), for raw text extraction without synthesis, or for deep-diving one already-identified section of a document that has already been digested (use pdf-studio-deep-dive).
version: 0.1.0
user-invocable: true
---

# PDF Report Pipeline

Convert a large PDF into a Markdown report through three phases that progressively compress information: **extract → structure → report**. Separating faithful extraction from interpretive synthesis is what prevents the boundary inconsistencies that appear when a report is written directly from fixed page ranges. Run the heavy phases (extraction and structuring) in isolated contexts so the source pages and intermediate material never fill the orchestrator's context; the final report phase reads only the already-compressed outline, so the orchestrator writes it directly.

## Gotchas (read before starting)

- **The Read tool's PDF vision requires system `poppler`.** The Read tool rasterizes PDF pages with `pdftoppm` (part of poppler). If extraction reports `pdftoppm failed:` (often with an empty message), poppler is missing or broken. Fix by installing it — macOS: `brew install poppler`; Debian/Ubuntu: `apt-get install poppler-utils` — then retry. Do NOT remove poppler to "clean up": it silently breaks all PDF reading.
- **Front matter is often long and offset from printed page numbers.** Covers, TOC, preface, and blank/divider pages can run 20–30 PDF pages before the body starts, and printed page numbers lag PDF page numbers by that offset. Detect where the body begins before chunking — read the first ~10–15 PDF pages and take, as body-start, the first page whose content matches the first numbered chapter heading (or the first real TOC entry). Do not spend extraction budget transcribing the table of contents.
- **Extraction/stitch workers left unconstrained will work around obstacles in undesirable ways.** Observed failures: a worker ran `brew install poppler` on its own; another shelled out to `pdftotext`; another bypassed a blocked Write with Bash. The Phase 1/2 procedures (in `pdf-studio-pdf-extract` / `pdf-studio-pdf-stitch`) carry the explicit constraints (no installs, Read tool only, report errors instead of working around them); apply them as written.
- **Keep page anchors `[pNN]` in every artifact.** They make the report traceable to the source and are what lets [[pdf-studio-deep-dive]] zoom back into the original PDF later. `pNN` is always the **PDF** page number; record any printed-page↔PDF offset in the outline's `## Page offset` field (see Phase 2) so [[pdf-studio-deep-dive]] can convert printed page numbers.

## Prerequisites

1. Confirm the PDF path and get its page count with `pdfinfo <path> | grep Pages` (poppler is already required by this skill, so `pdfinfo` is present). Fallback if the poppler CLI is unavailable but a venv has `pypdfium2`: `python -c "import pypdfium2 as p; print(len(p.PdfDocument('FILE')))"`.
2. Verify poppler: `command -v pdftoppm`. If missing, install per the gotcha above.
3. Set the work directory next to the source PDF, in a directory named after the PDF's basename: for `<dir>/<name>.pdf`, the work dir is `<dir>/<name>/`. (On a re-run after the source PDF was collected into the work dir, the given path is already `<dir>/<name>/<name>.pdf`; then that parent directory **is** the work dir — do not nest another level.) Create it with `extract/`, `structured/`, and `reports/` inside. Do not fall back to another location — if writing there fails (e.g. the directory is not writable), stop and report the error rather than writing elsewhere.

## Work directory layout

For a source PDF at `<dir>/<name>.pdf`, everything is written under `<dir>/<name>/`:

```
<dir>/<name>/             # work dir (named after the PDF basename)
├── <name>.pdf            # source PDF, collected in after Phase 3 (on user confirmation)
├── extract/              # Phase 1: one structured-material file per chunk
│   ├── chunk-030-049.md
│   └── chunk-050-069.md
├── structured/
│   └── outline.md        # Phase 2: stitched, deduped, re-structured outline
└── reports/
    └── overview.md       # Phase 3: overview report
```

## Phase 1 — Chunked visual extraction (parallel)

Split the body into chunks and extract each chunk **in parallel**. Each chunk is read visually and written as structured *material*, not a finished report. The per-chunk role, mandatory constraints, and material format live in the **`pdf-studio-pdf-extract`** skill; apply it once per chunk:

- **Under Claude Code**, dispatch one `pdf-studio-pdf-extract` subagent per chunk (multiple Agent calls in one message) so the source pages never enter the orchestrator's context and the chunks run concurrently. The subagent has no Bash tool, so it cannot install software or shell out to PDF converters.
- **Otherwise**, apply the `pdf-studio-pdf-extract` skill once per chunk, keeping each chunk's extraction self-contained and writing its file without reading the pages back into the main context.

- **Chunk size:** the Read tool reads at most 20 pages per request. A worker may make several Read calls, so a chunk can span more than 20 pages with seamless internal boundaries — only chunk-to-chunk boundaries need stitching in Phase 2. Default to 20-page chunks unless larger spans reduce boundary count usefully.
- **Skip front matter:** start chunking at the detected body-start page.
- **Output:** each chunk writes `extract/chunk-<start>-<end>.md` and returns only a short status (file path, end state complete/continued, one-line boundary context). The extracted body never enters the orchestrator's context.

Pass in the call message only the per-chunk inputs: the PDF absolute path, the page range (START–END), and the output path `extract/chunk-<START>-<END>.md`. Give absolute paths.

## Phase 2 — Stitch & structure (single pass)

Apply the **`pdf-studio-pdf-stitch`** skill once, reading all `extract/chunk-*.md` files and rebuilding the document's logic:

- Join sections split across chunk boundaries; dedupe repeated descriptions; reconcile translation/heading variance.
- Rebuild the chapter → section → subsection hierarchy into `structured/outline.md`, preserving `[pNN]` anchors.
- Record a boundary note: what was joined, and where coverage stops mid-section (if the run was a partial slice).
- Record the printed-page↔PDF-page offset in a `## Page offset` field near the top of `outline.md` (e.g. "printed page N = PDF page N + 27", or "none detected") so [[pdf-studio-deep-dive]] can convert printed page numbers to PDF pages.

**Under Claude Code**, dispatch a single `pdf-studio-pdf-stitch` subagent; **otherwise** apply the skill inline. Pass the `extract/` directory absolute path and the output path `structured/outline.md`. It returns only the reconstructed heading list and one line on boundary decisions.

## Phase 3 — Overview report (orchestrator, inline)

Unlike Phases 1–2, this phase runs **inline** in the orchestrator. Its only input is `structured/outline.md` — already the compressed artifact — so reading it into the orchestrator does not bloat context, and an isolated worker would only have to hand the finished report back anyway. The orchestrator reads `structured/outline.md` and writes `reports/overview.md` itself: an executive summary plus a consistent-granularity walkthrough of the structure, keeping key definitions, figures, and `[pNN]` anchors. This report is intentionally the compressed, overview view — detail on demand is the job of [[pdf-studio-deep-dive]].

- Open with a "Coverage" note and a 3–5 line executive summary; end with an "Uncovered / continued" note if this was a partial run.
- Compose it as headings + concise explanatory prose (not a flat bullet list), preserving the chapter/section hierarchy and `[pNN]` anchors.
- Write the body in the language of the source or the conversation.
- For very large outlines, build the report in levels (section → chapter → whole) so each reduce step stays manageable.

## Finalize — collect the source PDF (confirm first)

To make the work dir a single self-contained folder, move the source PDF into it as `<WORK_DIR>/<name>.pdf` as the last step.

- **This relocates the user's original file, so confirm first.** Ask the user before moving; if they decline, leave the PDF where it is — the digest is already complete either way. Never move without an explicit yes.
- If the PDF is already inside the work dir (a re-run, or the user moved it earlier), there is nothing to do.
- Once collected, the source for any later [[pdf-studio-deep-dive]] is `<WORK_DIR>/<name>.pdf`.

## Orchestration rules (context hygiene)

- Extraction/stitch workers write outputs to files and return only a short status. Never have a worker echo extracted body text back to the orchestrator — that defeats the point.
- Do not Read the PDF pages or the large chunk files into the orchestrator's own context. Trust the file-based hand-off.
- Parallelize Phase 1 (chunks are independent); then run Phase 2 and Phase 3 sequentially — each depends on the prior file.
- For very large documents, build Phase 3 in levels (section → chapter → whole) so each reduce step stays within context.

## Success criteria (verify the deliverable, not the steps)

- [ ] Every `extract/chunk-*.md` and `outline.md` carries `[pNN]` PDF-page anchors.
- [ ] `outline.md` has no section duplicated across a former chunk boundary, and records where coverage stops.
- [ ] `reports/overview.md` covers every top-level section present in `outline.md` (no section silently dropped).
- [ ] The body-start page was detected; front matter (TOC/preface) was not transcribed as content.
- [ ] If the run was a partial page range, `reports/overview.md` states the covered range and the continuation point.

## Phase workers

Phases 1–2 each run a dedicated procedure that lives in its own portable skill, so this orchestrator only chooses the phase order, the work dir, and the per-call inputs. Under Claude Code each is wrapped by a thin subagent (for isolation and parallelism); on any agent the same skill can be applied inline (see each phase above). Phase 3 has no separate worker — the orchestrator writes the report itself (see Phase 3).

- **`pdf-studio-pdf-extract`** — Phase 1, one per chunk in parallel. Read+Write only (no Bash, so it cannot install software or convert PDFs itself).
- **`pdf-studio-pdf-stitch`** — Phase 2, single instance. Read+Write+Glob.

The section drill-down counterpart [[pdf-studio-deep-dive]] uses its own **`pdf-studio-pdf-detail`** worker.
