## Gotchas (read before starting)

- **The Read tool's PDF vision requires system `poppler`.** The Read tool rasterizes PDF pages with `pdftoppm` (part of poppler). If extraction reports `pdftoppm failed:` (often with an empty message), poppler is missing or broken. Fix by installing it — macOS: `brew install poppler`; Debian/Ubuntu: `apt-get install poppler-utils` — then retry. Do NOT remove poppler to "clean up": it silently breaks all PDF reading.
- **Front matter is often long and offset from printed page numbers.** Covers, TOC, preface, and blank/divider pages can run 20–30 PDF pages before the body starts, and printed page numbers lag PDF page numbers by that offset. Detect where the body begins before chunking — read the first ~10–15 PDF pages and take, as body-start, the first page whose content matches the first numbered chapter heading (or the first real TOC entry). Do not spend extraction budget transcribing the table of contents *as content* — but if the front matter has a printed TOC, capturing its heading list once (as **structure**, not prose) is worthwhile: hand it to Phase 2 as an optional cross-check that the spine missed no heading. Capturing the TOC as structure and transcribing it as content are different things; the first is cheap and useful, the second is waste.
- **Extraction/stitch workers left unconstrained will work around obstacles in undesirable ways.** Observed failures: a worker ran `brew install poppler` on its own; another shelled out to `pdftotext`; another bypassed a blocked Write with Bash. The Phase 1/2 procedures (in `pdf-explainer-pdf-extract` / `pdf-explainer-pdf-stitch`) carry the explicit constraints (no installs, Read tool only, report errors instead of working around them); apply them as written.
- **Keep page anchors `[pNN]` in every artifact.** They make the report traceable to the source. `pNN` is always the **PDF** page number; record any printed-page↔PDF offset in the spine/outline's `## Page offset` field (see Phase 2) so `book-explainer` can resolve chapter-detail source pages precisely.
- **Headings and their anchors come from the spine `toc.md`, not re-derived per phase.** Phase 2 builds `structured/toc.md` — the canonical structure (each heading's source-form title verbatim + the `[pNN]` it first appears on) — by merging the chunks' heading streams. The outline, overview, and `book-explainer` chapter-detail workers take their headings and anchors from the spine instead of re-inventing them. Re-deriving structure from prose in each phase is exactly what caused heading drift and off-by-one anchors; the spine removes that failure mode by construction.
- **Figure harvest (MinerU) is an optional enhancement with a clean fallback, not a hard dependency.** Phase 0 runs `figure_harvest.sh` through `scripts/preflight.sh` to crop genuine figures (diagrams / plots / photos — not tables or console output) into `ocr/figures/`. The runtime is resolved automatically — `preflight.sh` uses poppler + a MinerU source from PATH, else the bundled `flake.nix` dev shell (`nix`); MinerU itself is used from PATH if installed, else resolved by `uvx --from 'mineru[core]' mineru` into uv's shared tool cache (no per-skill lockfile, no manual/global install). **Do not install anything by hand.** If the runtime cannot be resolved at all (no poppler+uv/mineru on PATH and no nix), `preflight.sh` fails with the setup options — **relay them and continue the pipeline without figure crops** (the reports still describe figures in prose, as before). **MinerU 3.x starts a local service and uses multiprocessing that the command sandbox blocks** (`Operation not permitted` on a semaphore), and its first `uvx` resolve / model download need network — so **run Phase 0 with the sandbox disabled**. It is fully local (nothing is uploaded); the first run downloads model weights (several GB) plus a tool-env sync when resolved via uvx, and is slow — warn about that.
- **The text-layer option is opt-in and only for born-digital PDFs.** By default the body is read visually (robust on scans/captures). A purchased ebook carries a real text layer, and `pdftotext -layout` reproduces its code listings, commands, numbers, and console/box-drawing tables far more faithfully than visual OCR — but a scanned/captured PDF has no text layer, so this must never be forced. Gate it: only offer the option when `text_layer.sh --probe <pdf> <body-start>` reports born-digital, and only use it when the user opts in.
- **Text-layer mode cannot read values that live only inside a raster figure.** `pdftotext` reproduces the text stream faithfully (code, commands, numbers, console/box-drawing tables), but a value that exists only as pixels inside a diagram — a bit array drawn in a figure, a node's key in an illustrated tree, numbers baked into a chart image — is not in the text layer, so text-layer mode drops it (visual mode reads it). This is a deliberate trade-off, not a bug: pair text-layer with figure harvest (Phase 0) so the embedded crop carries those in-image values, and treat in-figure values as the known blind spot of the text path.

## Prerequisites

1. Confirm the PDF path and get its page count with `pdfinfo <path> | grep Pages` (poppler is already required by this skill, so `pdfinfo` is present). Fallback if the poppler CLI is unavailable but a venv has `pypdfium2`: `python -c "import pypdfium2 as p; print(len(p.PdfDocument('FILE')))"`.
2. Verify poppler: `command -v pdftoppm`. If missing, install per the gotcha above.
3. Optional runtime (do not install anything by hand): Phase 0 figure harvest runs through `scripts/preflight.sh`, which resolves poppler + a MinerU source from PATH (installed `mineru`, or `uv` resolving it via `uvx`) or the bundled flake (`nix`). You need not pre-check it — attempt Phase 0 and, if `preflight.sh` reports the runtime is unresolvable, skip figures and note it in the handoff inventory. For the text-layer option, `bash <SKILL_DIR>/scripts/preflight.sh bash <SKILL_DIR>/scripts/text_layer.sh --probe <pdf> <body-start-guess>` (any page in the body) decides whether it can be offered — `preflight.sh` resolves poppler (PATH or the bundled flake, so this works on a nix-only host), then the probe exits 0 (born-digital) / 1 (no text layer).
4. Set the work directory next to the source PDF, in a directory named after the PDF's basename: for `<dir>/<name>.pdf`, the work dir is `<dir>/<name>/`. (On a re-run after the source PDF was collected into the work dir, the given path is already `<dir>/<name>/<name>.pdf`; then that parent directory **is** the work dir — do not nest another level.) Create it with `extract/`, `structured/`, `reports/`, and `ocr/` inside. Do not fall back to another location — if writing there fails (e.g. the directory is not writable), stop and report the error rather than writing elsewhere.

`<SKILL_DIR>` below is this skill's own base directory; the bundled scripts live at `<SKILL_DIR>/scripts/`. Reference them by that skill-root-relative path — no absolute or plugin-root paths.

## Step 0 — Confirm options once, up front

One interactive gate before any work; do not re-prompt between phases. When this
skill runs as a phase of [[book-explainer]], the immutable run request
already contains these resolved choices, so do not ask again. In standalone use,
ask:

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
