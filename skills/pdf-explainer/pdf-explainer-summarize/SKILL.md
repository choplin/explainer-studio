---
name: pdf-explainer-summarize
description: This skill should be used when the user wants to turn a large PDF (a book, manual, or long document — roughly 30+ pages) into a Markdown report, digest, or summary. Triggers on "PDFをレポートにして", "この本を要約して/レポート化して", "turn this PDF into a markdown report", "generate a digest of this document", "read this whole PDF and summarize it". Should NOT trigger for short PDFs under ~30 pages (read them directly with the Read tool), for academic conference/journal papers or preprints regardless of length (use paper-explainer-summarize), or for raw text extraction without synthesis.
user-invocable: true
---

# PDF Report Pipeline

Convert a large PDF into a Markdown report through three phases that progressively compress information: **extract → structure → report**. Separating faithful extraction from interpretive synthesis is what prevents the boundary inconsistencies that appear when a report is written directly from fixed page ranges. Run the heavy phases (extraction and structuring) in isolated contexts so the source pages and intermediate material never fill the orchestrator's context; the final report phase reads only the already-compressed outline, so the orchestrator writes it directly.

## Before starting — read the runtime and option contract

Read [`references/runtime-and-options.md`](references/runtime-and-options.md) completely before running any command or creating the work directory. It contains the original Gotchas, Prerequisites, Step 0 option gate, and work-directory layout without abridgment.

## Phase 0 — Figure harvest (orchestrator, Bash, unsandboxed)

Run once over the body range **with the sandbox disabled** (MinerU's local service + multiprocessing, and the first `uv` sync / model download, are blocked under the sandbox), launching the worker through `preflight.sh` so its runtime env (poppler + a MinerU source) is resolved:

```
bash <SKILL_DIR>/scripts/preflight.sh bash <SKILL_DIR>/scripts/figure_harvest.sh <pdf-abs-path> <WORK_DIR>/ocr [body-start] [body-end]
```

Pass the body range if you have already detected the body-start; otherwise omit the range and harvest the whole PDF (a cover image or other front-matter crop is harmless and is dropped by the Finalize sweep if no report uses it). It crops the genuine figures — diagrams, plots, photos — into `ocr/figures/fig-pNNN-K.ext` (named by absolute PDF page) and writes `ocr/figures.md` (Label / File / Page / Caption). Tables and console output are deliberately **not** cropped: the text extraction already carries them. MinerU can take minutes and downloads models on first run — use a generous timeout. If `preflight.sh` reports the runtime is unresolvable (no poppler+uv/mineru on PATH, no nix), relay the setup options and **continue the pipeline without figures**; on any other failure, report it and continue without figures. The crops are consumed by Phase 1 (assigned to chunks) and swept for coverage at Finalize. This phase writes only files — no page content enters the orchestrator's context.

## Phase 1 — Chunked extraction (parallel)

Split the body into chunks and extract each chunk **in parallel**. Each chunk is read — visually by default, or from the faithful text layer if the user opted in at Step 0 — and written as structured *material*, not a finished report. The per-chunk role, mandatory constraints, and material format live in the **`pdf-explainer-pdf-extract`** skill; apply it once per chunk:

- **Under Claude Code**, dispatch one `pdf-explainer-pdf-extract` subagent per chunk (multiple Agent calls in one message) so the source pages never enter the orchestrator's context and the chunks run concurrently. The subagent has no Bash tool, so it cannot install software or shell out to PDF converters.
- **Otherwise**, apply the `pdf-explainer-pdf-extract` skill once per chunk, keeping each chunk's extraction self-contained and writing its file without reading the pages back into the main context.

- **Chunk size:** the Read tool reads at most 20 pages per request. A worker may make several Read calls, so a chunk can span more than 20 pages with seamless internal boundaries — only chunk-to-chunk boundaries need stitching in Phase 2. Default to 20-page chunks unless larger spans reduce boundary count usefully.
- **Skip front matter:** start chunking at the detected body-start page.
- **Text-layer mode (opt-in):** before dispatching each chunk, materialize its faithful text — `bash <SKILL_DIR>/scripts/preflight.sh bash <SKILL_DIR>/scripts/text_layer.sh <pdf-abs-path> <WORK_DIR>/extract/text-<START>-<END>.md <START> <END>` (`preflight.sh` resolves poppler from PATH or the bundled flake) — and pass the worker that text file's path instead of a visual page range. The worker reads the `[pNN]`-anchored text (no PDF rasterization). One `pdftotext` per page is cheap; do this in the orchestrator (it writes a file, so no page content enters context).
- **Output:** each chunk writes `extract/chunk-<start>-<end>.md` and returns only a short status (file path, end state complete/continued, one-line boundary context). The extracted body never enters the orchestrator's context.

Pass in the call message only the per-chunk inputs:
- The source to read: **visual mode** — the PDF absolute path and the page range (START–END); **text-layer mode** — the absolute path to `extract/text-<START>-<END>.md` (still note the START–END range for anchors).
- The output path `extract/chunk-<START>-<END>.md`.
- **Assigned figures (if Phase 0 ran):** the rows of `ocr/figures.md` whose `[pNN]` page falls in this chunk's range, so the worker catalogs each figure (by its `figures/…` relative path, page, and caption) in the material — a menu the report phase can draw from, not a mandate to use every figure.

Give absolute paths.

## Phase 2 — Stitch & structure (single pass)

Apply the **`pdf-explainer-pdf-stitch`** skill once, reading all `extract/chunk-*.md` files and rebuilding the document's logic into **two** artifacts — the spine first, then the outline:

- **Build `structured/toc.md` (the canonical spine)** by merging the chunks' `## Headings` streams: dedupe boundary repeats, keep each heading's source-form title verbatim, and take its `[pNN]` from the stream (never a blank page). If you captured a printed TOC, hand it over as a completeness cross-check.
- **Assemble `structured/outline.md` against the spine:** its heading tree is `toc.md`'s (same titles/anchors), with the boundary-joined, deduped content filled under each. Do not invent a second structure.
- Preserve the figure references the chunks recorded (from `ocr/figures.md`) against their sections, so the outline knows which figure belongs where.
- Record a boundary note: what was joined, where coverage stops mid-section (if partial), and any TOC↔heading cross-check discrepancy.
- Record the printed-page↔PDF-page offset in a `## Page offset` field near the top of both files (e.g. "printed page N = PDF page N + 27", or "none detected") so the full-guide's chapter-detail workers can convert printed page numbers to PDF pages.

**Under Claude Code**, dispatch a single `pdf-explainer-pdf-stitch` subagent; **otherwise** apply the skill inline. Pass the `extract/` directory absolute path, the output path `structured/outline.md` (the spine `toc.md` is written beside it), any captured printed TOC, and — if Phase 0 ran — the `ocr/figures.md` absolute path so it can keep figure references against their sections. It returns only the spine heading count and one line on boundary decisions.

## Phase 3 — Overview report (orchestrator, inline)

Read [`references/overview-report.md`](references/overview-report.md) completely at the start of Phase 3 and follow it end-to-end. It contains the original overview procedure and altitude cap without abridgment.

## Finalize

Read [`references/finalize.md`](references/finalize.md) completely after Phase 3 and follow it end-to-end. Before declaring the pipeline complete, read [`references/success-criteria.md`](references/success-criteria.md) completely and verify every applicable item.

## Orchestration rules (context hygiene)

- Extraction/stitch workers write outputs to files and return only a short status. Never have a worker echo extracted body text back to the orchestrator — that defeats the point.
- Do not Read the PDF pages or the large chunk files into the orchestrator's own context. Trust the file-based hand-off.
- Parallelize Phase 1 (chunks are independent); then run Phase 2 and Phase 3 sequentially — each depends on the prior file.
- For very large documents, build Phase 3 in levels (section → chapter → whole) so each reduce step stays within context.

## Phase workers

Phases 1–2 each run a dedicated procedure that lives in its own portable skill, so this orchestrator only chooses the phase order, the work dir, and the per-call inputs. Under Claude Code each is wrapped by a thin subagent (for isolation and parallelism); on any agent the same skill can be applied inline (see each phase above). Phase 3 has no separate worker — the orchestrator writes the report itself (see Phase 3).

- **`pdf-explainer-pdf-extract`** — Phase 1, one per chunk in parallel. Read+Write only (no Bash, so it cannot install software or convert PDFs itself).
- **`pdf-explainer-pdf-stitch`** — Phase 2, single instance. Read+Write+Glob.

When per-chapter detail reports are needed, [[pdf-explainer-full-guide]] applies the internal **`pdf-explainer-pdf-detail`** worker.

## Bundled scripts

Before running Phase 0 or any text-layer command, read [`references/bundled-scripts.md`](references/bundled-scripts.md) completely. It contains the original script and runtime details without abridgment.
