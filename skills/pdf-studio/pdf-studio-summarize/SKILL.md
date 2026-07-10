---
name: pdf-studio-summarize
description: This skill should be used when the user wants to turn a large PDF (a book, manual, or long document — roughly 30+ pages) into a Markdown report, digest, or summary. Triggers on "PDFをレポートにして", "この本を要約して/レポート化して", "turn this PDF into a markdown report", "generate a digest of this document", "read this whole PDF and summarize it". Should NOT trigger for short PDFs under ~30 pages (read them directly with the Read tool), for academic conference/journal papers or preprints regardless of length (use paper-studio-summarize), for raw text extraction without synthesis, or for deep-diving one already-digested section (use pdf-studio-deep-dive).
user-invocable: true
---

# PDF Report Pipeline

Convert a large PDF into a Markdown report through three phases that progressively compress information: **extract → structure → report**. Separating faithful extraction from interpretive synthesis is what prevents the boundary inconsistencies that appear when a report is written directly from fixed page ranges. Run the heavy phases (extraction and structuring) in isolated contexts so the source pages and intermediate material never fill the orchestrator's context; the final report phase reads only the already-compressed outline, so the orchestrator writes it directly.

## Gotchas (read before starting)

- **The Read tool's PDF vision requires system `poppler`.** The Read tool rasterizes PDF pages with `pdftoppm` (part of poppler). If extraction reports `pdftoppm failed:` (often with an empty message), poppler is missing or broken. Fix by installing it — macOS: `brew install poppler`; Debian/Ubuntu: `apt-get install poppler-utils` — then retry. Do NOT remove poppler to "clean up": it silently breaks all PDF reading.
- **Front matter is often long and offset from printed page numbers.** Covers, TOC, preface, and blank/divider pages can run 20–30 PDF pages before the body starts, and printed page numbers lag PDF page numbers by that offset. Detect where the body begins before chunking — read the first ~10–15 PDF pages and take, as body-start, the first page whose content matches the first numbered chapter heading (or the first real TOC entry). Do not spend extraction budget transcribing the table of contents *as content* — but if the front matter has a printed TOC, capturing its heading list once (as **structure**, not prose) is worthwhile: hand it to Phase 2 as an optional cross-check that the spine missed no heading. Capturing the TOC as structure and transcribing it as content are different things; the first is cheap and useful, the second is waste.
- **Extraction/stitch workers left unconstrained will work around obstacles in undesirable ways.** Observed failures: a worker ran `brew install poppler` on its own; another shelled out to `pdftotext`; another bypassed a blocked Write with Bash. The Phase 1/2 procedures (in `pdf-studio-pdf-extract` / `pdf-studio-pdf-stitch`) carry the explicit constraints (no installs, Read tool only, report errors instead of working around them); apply them as written.
- **Keep page anchors `[pNN]` in every artifact.** They make the report traceable to the source and are what lets [[pdf-studio-deep-dive]] zoom back into the original PDF later. `pNN` is always the **PDF** page number; record any printed-page↔PDF offset in the spine/outline's `## Page offset` field (see Phase 2) so [[pdf-studio-deep-dive]] can convert printed page numbers.
- **Headings and their anchors come from the spine `toc.md`, not re-derived per phase.** Phase 2 builds `structured/toc.md` — the canonical structure (each heading's source-form title verbatim + the `[pNN]` it first appears on) — by merging the chunks' heading streams. The outline, the overview, and [[pdf-studio-deep-dive]] all take their headings and anchors from the spine instead of re-inventing them. Re-deriving structure from prose in each phase is exactly what caused heading drift and off-by-one anchors; the spine removes that failure mode by construction.
- **Figure harvest (MinerU) is an optional enhancement with a clean fallback, not a hard dependency.** Phase 0 runs `figure_harvest.sh` through `scripts/preflight.sh` to crop genuine figures (diagrams / plots / photos — not tables or console output) into `ocr/figures/`. The runtime is resolved automatically — `preflight.sh` uses poppler + a MinerU source from PATH, else the bundled `flake.nix` dev shell (`nix`); MinerU itself is used from PATH if installed, else resolved by `uvx --from 'mineru[core]' mineru` into uv's shared tool cache (no per-skill lockfile, no manual/global install). **Do not install anything by hand.** If the runtime cannot be resolved at all (no poppler+uv/mineru on PATH and no nix), `preflight.sh` fails with the setup options — **relay them and continue the pipeline without figure crops** (the reports still describe figures in prose, as before). **MinerU 3.x starts a local service and uses multiprocessing that the command sandbox blocks** (`Operation not permitted` on a semaphore), and its first `uvx` resolve / model download need network — so **run Phase 0 with the sandbox disabled**. It is fully local (nothing is uploaded); the first run downloads model weights (several GB) plus a tool-env sync when resolved via uvx, and is slow — warn about that.
- **The text-layer option is opt-in and only for born-digital PDFs.** By default the body is read visually (robust on scans/captures). A purchased ebook carries a real text layer, and `pdftotext -layout` reproduces its code listings, commands, numbers, and console/box-drawing tables far more faithfully than visual OCR — but a scanned/captured PDF has no text layer, so this must never be forced. Gate it: only offer the option when `text_layer.sh --probe <pdf> <body-start>` reports born-digital, and only use it when the user opts in.
- **Text-layer mode cannot read values that live only inside a raster figure.** `pdftotext` reproduces the text stream faithfully (code, commands, numbers, console/box-drawing tables), but a value that exists only as pixels inside a diagram — a bit array drawn in a figure, a node's key in an illustrated tree, numbers baked into a chart image — is not in the text layer, so text-layer mode drops it (visual mode reads it). This is a deliberate trade-off, not a bug: pair text-layer with figure harvest (Phase 0) so the embedded crop carries those in-image values, and treat in-figure values as the known blind spot of the text path.

## Prerequisites

1. Confirm the PDF path and get its page count with `pdfinfo <path> | grep Pages` (poppler is already required by this skill, so `pdfinfo` is present). Fallback if the poppler CLI is unavailable but a venv has `pypdfium2`: `python -c "import pypdfium2 as p; print(len(p.PdfDocument('FILE')))"`.
2. Verify poppler: `command -v pdftoppm`. If missing, install per the gotcha above.
3. Optional runtime (do not install anything by hand): Phase 0 figure harvest runs through `scripts/preflight.sh`, which resolves poppler + a MinerU source from PATH (installed `mineru`, or `uv` resolving it via `uvx`) or the bundled flake (`nix`). You need not pre-check it — attempt Phase 0 and, if `preflight.sh` reports the runtime is unresolvable, skip figures and note it in the manifest. For the text-layer option, `bash <SKILL_DIR>/scripts/preflight.sh bash <SKILL_DIR>/scripts/text_layer.sh --probe <pdf> <body-start-guess>` (any page in the body) decides whether it can be offered — `preflight.sh` resolves poppler (PATH or the bundled flake, so this works on a nix-only host), then the probe exits 0 (born-digital) / 1 (no text layer).
4. Set the work directory next to the source PDF, in a directory named after the PDF's basename: for `<dir>/<name>.pdf`, the work dir is `<dir>/<name>/`. (On a re-run after the source PDF was collected into the work dir, the given path is already `<dir>/<name>/<name>.pdf`; then that parent directory **is** the work dir — do not nest another level.) Create it with `extract/`, `structured/`, `reports/`, and `ocr/` inside. Do not fall back to another location — if writing there fails (e.g. the directory is not writable), stop and report the error rather than writing elsewhere.

`<SKILL_DIR>` below is this skill's own base directory; the bundled scripts live at `<SKILL_DIR>/scripts/`. Reference them by that skill-root-relative path — no absolute or plugin-root paths.

## Step 0 — Confirm options once, up front

One interactive gate before any work; do not re-prompt between phases (when this skill is run from [[pdf-studio-full-guide]], that skill's Step 0 asks these instead). Ask:

0. **Existing work dir** — if `<WORK_DIR>/` already holds a prior run's outputs (`extract/`, `structured/`, `reports/`), say so and confirm before overwriting them: regenerate in place (overwrite), or use a different work-dir name to keep the old one. No prompt when the work dir is new.
1. **Text source** — *default: visual reading* (works on any PDF). Only if the born-digital probe passed, offer the **text-layer** option: more faithful for code/commands/numbers/console output, born-digital ebooks only. Accept the user's choice.
2. **Figure harvest** — mention it will run if `mineru` is available (a first run downloads models and takes a while, and it runs unsandboxed and locally); nothing to decide unless the user wants to skip it.

## Work directory layout

For a source PDF at `<dir>/<name>.pdf`, everything is written under `<dir>/<name>/`:

```
<dir>/<name>/             # work dir (named after the PDF basename)
├── <name>.pdf            # source PDF, collected in after Phase 3 (on user confirmation)
├── ocr/                  # Phase 0: figure harvest (only if mineru is available)
│   ├── figures.md        # metadata index: label / file / page / caption
│   └── figures/          # cropped figures, named by PDF page (fig-p031-1.jpg)
├── extract/              # Phase 1: one structured-material file per chunk
│   ├── chunk-030-049.md
│   ├── text-030-049.md   # (text-layer mode only) faithful text the worker reads
│   └── chunk-050-069.md
├── structured/
│   ├── toc.md            # Phase 2: canonical structural spine (headings + [pNN] anchors, verbatim)
│   └── outline.md        # Phase 2: stitched, deduped outline, assembled against toc.md
└── reports/
    └── overview.md       # Phase 3: overview report
```

## Phase 0 — Figure harvest (orchestrator, Bash, unsandboxed)

Run once over the body range **with the sandbox disabled** (MinerU's local service + multiprocessing, and the first `uv` sync / model download, are blocked under the sandbox), launching the worker through `preflight.sh` so its runtime env (poppler + a MinerU source) is resolved:

```
bash <SKILL_DIR>/scripts/preflight.sh bash <SKILL_DIR>/scripts/figure_harvest.sh <pdf-abs-path> <WORK_DIR>/ocr [body-start] [body-end]
```

Pass the body range if you have already detected the body-start; otherwise omit the range and harvest the whole PDF (a cover image or other front-matter crop is harmless and is dropped by the Finalize sweep if no report uses it). It crops the genuine figures — diagrams, plots, photos — into `ocr/figures/fig-pNNN-K.ext` (named by absolute PDF page) and writes `ocr/figures.md` (Label / File / Page / Caption). Tables and console output are deliberately **not** cropped: the text extraction already carries them. MinerU can take minutes and downloads models on first run — use a generous timeout. If `preflight.sh` reports the runtime is unresolvable (no poppler+uv/mineru on PATH, no nix), relay the setup options and **continue the pipeline without figures**; on any other failure, report it and continue without figures. The crops are consumed by Phase 1 (assigned to chunks) and swept for coverage at Finalize. This phase writes only files — no page content enters the orchestrator's context.

## Phase 1 — Chunked extraction (parallel)

Split the body into chunks and extract each chunk **in parallel**. Each chunk is read — visually by default, or from the faithful text layer if the user opted in at Step 0 — and written as structured *material*, not a finished report. The per-chunk role, mandatory constraints, and material format live in the **`pdf-studio-pdf-extract`** skill; apply it once per chunk:

- **Under Claude Code**, dispatch one `pdf-studio-pdf-extract` subagent per chunk (multiple Agent calls in one message) so the source pages never enter the orchestrator's context and the chunks run concurrently. The subagent has no Bash tool, so it cannot install software or shell out to PDF converters.
- **Otherwise**, apply the `pdf-studio-pdf-extract` skill once per chunk, keeping each chunk's extraction self-contained and writing its file without reading the pages back into the main context.

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

Apply the **`pdf-studio-pdf-stitch`** skill once, reading all `extract/chunk-*.md` files and rebuilding the document's logic into **two** artifacts — the spine first, then the outline:

- **Build `structured/toc.md` (the canonical spine)** by merging the chunks' `## Headings` streams: dedupe boundary repeats, keep each heading's source-form title verbatim, and take its `[pNN]` from the stream (never a blank page). If you captured a printed TOC, hand it over as a completeness cross-check.
- **Assemble `structured/outline.md` against the spine:** its heading tree is `toc.md`'s (same titles/anchors), with the boundary-joined, deduped content filled under each. Do not invent a second structure.
- Preserve the figure references the chunks recorded (from `ocr/figures.md`) against their sections, so the outline knows which figure belongs where.
- Record a boundary note: what was joined, where coverage stops mid-section (if partial), and any TOC↔heading cross-check discrepancy.
- Record the printed-page↔PDF-page offset in a `## Page offset` field near the top of both files (e.g. "printed page N = PDF page N + 27", or "none detected") so [[pdf-studio-deep-dive]] can convert printed page numbers to PDF pages.

**Under Claude Code**, dispatch a single `pdf-studio-pdf-stitch` subagent; **otherwise** apply the skill inline. Pass the `extract/` directory absolute path, the output path `structured/outline.md` (the spine `toc.md` is written beside it), any captured printed TOC, and — if Phase 0 ran — the `ocr/figures.md` absolute path so it can keep figure references against their sections. It returns only the spine heading count and one line on boundary decisions.

## Phase 3 — Overview report (orchestrator, inline)

Unlike Phases 1–2, this phase runs **inline** in the orchestrator. Its only input is `structured/outline.md` — already the compressed artifact — so reading it into the orchestrator does not bloat context, and an isolated worker would only have to hand the finished report back anyway. The orchestrator reads `structured/outline.md` and writes `reports/overview.md` itself: an executive summary plus a consistent-granularity walkthrough of the structure, keeping key definitions, figures, and `[pNN]` anchors. This report is intentionally the compressed, overview view — detail on demand is the job of [[pdf-studio-deep-dive]].

- **Take headings and their `[pNN]` from the spine `structured/toc.md`, not by re-reading or re-inventing them.** The overview's section headings are the spine's headings (translated for display if the report language differs, but carrying the spine's anchor). This is what keeps the overview's anchors identical to the outline's and lets the Finalize containment check pass.

- Open with a "Coverage" note and a 3–5 line executive summary; end with an "Uncovered / continued" note if this was a partial run.
- Compose it as headings + concise explanatory prose (not a flat bullet list), preserving the chapter/section hierarchy and `[pNN]` anchors.
- **If figures were harvested,** embed the ones the summary naturally needs, inline where the prose discusses them, as `![caption](../ocr/figures/fig-pNNN-K.ext)` with a one-line caption and `[pNN]` (relative path from `reports/`). Do not embed a figure without explaining it. You need not use every figure — this is a book, not a paper, so leave crops the overview does not call for unreferenced rather than forcing them in.
- Write the body in the language of the source or the conversation.
- For very large outlines, build the report in levels (section → chapter → whole) so each reduce step stays manageable.

## Finalize

### 1. Figures — use what the summary needs, no exhaustive sweep (only if Phase 0 produced `ocr/figures/`)

Figures aid the reports; they are not a checklist. Embed a harvested figure only where the prose actually discusses what it shows, and when you embed it, explain it (never a bare image). **Do not append a trailing figure list or force every crop into a report to "cover" it** — this is a book, not a paper, so referencing every figure is not required. Crops in `ocr/figures/` that no report naturally needs are fine to leave unreferenced. If you *do* want a figure that `figures.md` marks "⚠ Not extracted", render and crop its page first (`pdftoppm -f N -l N -singlefile -r 200 -png <pdf> <tmp>/pg`) before embedding it.

### 2. Anchor containment against the spine — a structural check, not a source re-read

A cheap, deterministic guard that the overview's anchors did not drift from the canonical structure. Read only `structured/toc.md` and `reports/overview.md` (both small; **do not re-read the source PDF or the outline body**). Confirm:

- Every section heading in `overview.md` corresponds to a spine heading (by source-form title, or its translation) — the overview introduces no heading the spine does not have.
- Each such heading carries the **same `[pNN]`** the spine records for it.

Any mismatch is an anchor that drifted while writing the overview — fix it to the spine's anchor (the spine is authoritative). This is the mechanical anchor check reduced to a containment test: because headings and anchors are sourced from the spine, there is no fuzzy source-matching to do here, and a heading the check cannot locate in the spine is itself the finding. If the spine and overview agree, done.

### 3. Coherence self-check — does it read as one standalone piece (no source re-read)

The overview is compressed from the stitched `outline.md`, and for large documents it is built by multi-level reduce (section → chapter → whole) — a path where a term's first-use definition or the granularity can silently drift between levels. Do one light editorial pass to catch that. This is **not** the paper-studio faithfulness sweep: **do not re-read the source PDF, and do not re-read the outline's body** — read only the finished `reports/overview.md`, using `outline.md` solely as a checklist of which sections should be present. It is a book, not a paper, so keep it light — fix what you find, don't manufacture work.

Read the overview top to bottom as a first-time reader and check:
- **Continuity** — the sections connect; there is no jump where the prose assumes a step the report never made.
- **Terms defined before use** — every non-obvious term or concept is introduced where it first appears, not used cold and defined later (or never).
- **Consistent granularity** — no section is a terse stub next to a deep one for no reason (a symptom of an uneven reduce).
- **Self-contained** — a reader who opens only this file, without the source, can follow it.

Fix issues inline (a one-line definition, a bridging sentence, a granularity trim). If it already reads cleanly, that is a valid outcome — note it and move on.

### 4. Collect the source PDF (confirm first)

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
- [ ] `structured/toc.md` exists: one row per heading with a source-form (verbatim) title and its `[pNN]`, built by merging the chunks' heading streams (not re-derived from prose); no heading is anchored to a blank/divider page.
- [ ] `outline.md`'s heading tree matches `toc.md` (same headings, same anchors) and has no section duplicated across a former chunk boundary; it records where coverage stops.
- [ ] `reports/overview.md` covers every top-level section present in `toc.md` (no section silently dropped), and each heading it carries maps to a spine heading with the same `[pNN]` (the Finalize containment check passed).
- [ ] `reports/overview.md` reads as one standalone piece: sections connect, non-obvious terms are defined at first use, and it is followable without the source (a light coherence pass, not a source-faithfulness sweep).
- [ ] The body-start page was detected; front matter (TOC/preface) was not transcribed as content.
- [ ] If the run was a partial page range, `reports/overview.md` states the covered range and the continuation point.
- [ ] If the figure-harvest runtime resolved (via `preflight.sh` — PATH/uv/nix), `ocr/figures.md` exists and every figure a report embeds is explained in place (no bare image); unused crops may remain unreferenced (no exhaustive-coverage requirement). If the runtime was unresolvable, the manifest says figure harvest was skipped.
- [ ] If the text-layer option was chosen, each chunk was read from `extract/text-*.md` (not visually), and it was offered only after the born-digital probe passed.

## Phase workers

Phases 1–2 each run a dedicated procedure that lives in its own portable skill, so this orchestrator only chooses the phase order, the work dir, and the per-call inputs. Under Claude Code each is wrapped by a thin subagent (for isolation and parallelism); on any agent the same skill can be applied inline (see each phase above). Phase 3 has no separate worker — the orchestrator writes the report itself (see Phase 3).

- **`pdf-studio-pdf-extract`** — Phase 1, one per chunk in parallel. Read+Write only (no Bash, so it cannot install software or convert PDFs itself).
- **`pdf-studio-pdf-stitch`** — Phase 2, single instance. Read+Write+Glob.

The section drill-down counterpart [[pdf-studio-deep-dive]] uses its own **`pdf-studio-pdf-detail`** worker.

## Bundled scripts

Phase 0 and the text-layer option are the orchestrator's own Bash steps (workers stay Read/Write-only). The scripts live at `<SKILL_DIR>/scripts/`. The runtime env is supplied by the skill's bundled `flake.nix` (poppler + uv + python3); MinerU itself is resolved at run time by `uvx --from 'mineru[core]' mineru` (uv's shared tool cache, no per-skill lockfile), and the whole thing is resolved by `preflight.sh` per [`docs/skill-runtime-and-dependencies.md`](../../../docs/skill-runtime-and-dependencies.md):

- **`preflight.sh <command> [args…]`** — resolves the figure-harvest runtime once (poppler + a MinerU source), then execs the command inside it: PATH mode when poppler + (`uv`, or `mineru` + `python3`) are present, else `nix develop` when the bundled `flake.lock` is present and `nix` is available, else an aggregated fail listing both setup options (nix / manual). Launch `figure_harvest.sh` through it. It does not choose the MinerU source itself — the worker does that PATH-first (installed `mineru`, else `uvx --from 'mineru[core]' mineru`). The text-layer path needs only poppler (pdf-studio's baseline), so `text_layer.sh` is run directly, not through this wrapper.
- **`figure_harvest.sh <pdf> <ocr-dir> [start] [end]`** — Phase 0. Reads the PDF locally with MinerU (`-b pipeline`) and, via `mineru_figures.py`, crops the genuine figures (image/chart blocks only — tables and console output are left to the text stream) into `<ocr-dir>/figures/fig-pNNN-K.ext` named by absolute PDF page, and writes `<ocr-dir>/figures.md` (Label / File / Page / Caption, plus a "⚠ Not extracted" section for regions MinerU located but could not crop). Launch it through `preflight.sh`; **run it unsandboxed** (MinerU's local service is sandbox-incompatible). MinerU is resolved PATH-first — an installed `mineru`, else `uvx --from 'mineru[core]' mineru` resolves it into uv's shared tool cache (no manual install; first run syncs the tool env and downloads models — slow).
- **`text_layer.sh <pdf> <out-file> <start> <end>`** — the opt-in text-layer path. `pdftotext -layout` per page, each prefixed with a `[pNN]` anchor, for faithful code/console/number fidelity on born-digital PDFs. `text_layer.sh --probe <pdf> <start>` reports the born-digital char count and exits 0/1 so the option can be gated. Needs only poppler, but launch it through `preflight.sh` too so it works when poppler lives only in the bundled flake (a nix-only host).
- **`mineru_figures.py`** — the converter `figure_harvest.sh` calls; not run directly.
