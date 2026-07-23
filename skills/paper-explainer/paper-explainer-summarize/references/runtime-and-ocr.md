## Gotchas (read before starting)

- **MinerU is a hard requirement — there is no fallback.** This skill reads the paper through local MinerU (`mineru_ocr.sh`), which runs entirely on the machine (nothing is uploaded; safe for confidential manuscripts). MinerU is resolved automatically — an already-installed `mineru` on PATH is used as-is; otherwise it is run ephemerally via `uvx --from 'mineru[core]' mineru` (resolved from PyPI into uv's shared tool cache, so no manual install and no per-skill lockfile) — but its first run downloads model weights (several GB), plus a tool-env sync when resolved via uvx, so it is slow: warn about that. If OCR errors out, report it and stop; do NOT fall back to visual reading, to an external OCR API, or to any other reader.
- **Body text comes from the PDF text layer, not from OCR.** For a born-digital PDF (every normal CS paper), `mineru_ocr.sh` uses MinerU (`-b pipeline -m txt`) only for the *layout skeleton* — block reading order, figure/table crops, and formula LaTeX — and refills the prose from the PDF's own text layer via `pdftotext`. This is deliberately faithful: image OCR on the ACM/LinLibertine font class drops descenders ("making"→"makin"), collapses ff/fi ligatures ("different"→"diferent"), and litters the text with spurious `<sub>`/`<sup>` tags; the text-layer path has none of these. A scanned PDF with no text layer falls back to OCR mode automatically. Do not "fix" the output by re-OCRing or by switching MinerU's default backend (the default is hybrid/VLM, which image-recognizes every page and reintroduces exactly these defects).
- **Do not install anything by hand.** MinerU is used from PATH if already installed, else resolved automatically by `uvx --from 'mineru[core]' mineru` (uv's shared tool cache, resolved on first use) — never run an ad-hoc `pip`, `uv tool install`, or `uv add`. If resolution fails (e.g. no network — see the sandbox Gotcha below), report the error and stop; do not work around it.
- **Never write bibliographic URLs, DOIs, venues, or years from model memory.** Plausible-looking hallucinated citations are the main failure mode of "papers to read next". Every such fact must come from the paper's own References section or from `scripts/dblp_lookup.sh` output; no dblp match → mark "(dblp未確認)" and give no URL. (The `paper-explainer-paper-detail` skill restates this rule with the full lookup procedure — keep both in sync when refining it.)
- **The command sandbox may block network and cache writes.** MinerU's first-run model download and its writes to `~/.cache`, and `dblp.org` (curl), can fail under sandbox. On such an error, rerun the same script without sandboxing — do not switch to a different method or answer from memory.
- **Runtime env = system `poppler` (`pdftotext`/`pdfinfo`/`pdftoppm`) + a MinerU source; MinerU is resolved PATH-first.** `pdfinfo` does the page-count pre-check; `pdftotext` supplies the text layer that `mineru_ocr.sh` refills the body text from; `pdftoppm` renders pages for Finalize figure recovery. The `scripts/preflight.sh` wrapper **resolves** this and execs the worker: PATH mode when poppler is present **and** either `uv` (which supplies MinerU via `uvx` + a python via `uv run`) **or** an installed `mineru` + `python3`; else it runs inside the bundled `flake.nix` dev shell when `nix` is available; else it fails with both options. MinerU itself: an installed `mineru` is used as-is, otherwise it is **not** in the flake — it is resolved on first use by `uvx --from 'mineru[core]' mineru` into uv's shared tool cache (unpinned by design; shared across skills that request the same spec), so nothing needs a manual/global install. To provision the env yourself: **nix (one-shot, no other setup)** run the skill under `nix develop <SKILL_DIR>`; or **manual** install `uv` (<https://docs.astral.sh/uv/>) and poppler (macOS: `brew install poppler`; Debian/Ubuntu: `apt-get install poppler-utils`).
- **`[pNN]` anchors are always PDF page numbers**, not printed page numbers (camera-ready papers often print e.g. 1234–1245).
- **Every captured figure/table must be explained.** MinerU extracts *all* figures/tables into `ocr/figures/`, named by their paper reference number (`fig-NN.<ext>` / `table-NN.<ext>`) with `ocr/figures.md` recording each one's page and caption; the report set must collectively reference and explain every one — no orphan images, no image embedded without explanation. Figures are assigned to perspectives in Phase 2 (page looked up in `figures.md`), and a Finalize coverage sweep catches any that slipped through and places them (with explanation) in the nearest in-scope report or the overview. **MinerU sometimes locates a figure/table region but fails to recognize it** (no crop, no HTML) — the converter surfaces these in a "⚠ Not extracted" section of `figures.md` instead of dropping them, and Finalize step 1 recovers each by rendering the page and cropping (see Finalize).

## Prerequisites

1. Confirm the PDF path and get its page count: `pdfinfo <path> | grep Pages`. If it exceeds ~30 pages (a thesis, a book), point the user to pdf-explainer-summarize and stop unless they explicitly want this pipeline anyway.
2. **No install step for MinerU — it is resolved automatically.** The runtime env (poppler + a MinerU source) is resolved by the `scripts/preflight.sh` wrapper that launches `mineru_ocr.sh` (PATH, else the bundled flake); MinerU is used from PATH if installed, else resolved by `uvx --from 'mineru[core]' mineru` on first use. MinerU is the skill's OCR engine and is mandatory by design (local processing keeps under-review manuscripts off the network) — there is no fallback reader. Just be ready for a **slow first run** (several-GB model download, plus a tool-env sync when resolved via uvx); see the runtime-env Gotcha above for the one-shot `nix develop <SKILL_DIR>` setup.
3. Set a **provisional** work dir next to the source PDF, named after the PDF's current basename: for `<dir>/<name>.pdf`, `<dir>/<name>/`. Create `reports/` and `ocr/` inside. Phase 1 renames this dir to the citation slug (see **Naming convention**) once the metadata is known. (On a re-run the given path is already `<dir>/<slug>/<slug>.pdf` and the parent dir is already the slug — that parent **is** the work dir; do not nest another level, and the Phase 1 rename becomes a no-op.) Do not fall back to another location — if writing fails, stop and report.

## Naming convention

The work dir and the collected PDF are named `{year}-{venue}-{short-title}` — a citation-style slug derived from the paper's own bibliographic metadata, e.g. dir `2017-neurips-attention-is-all-you-need/` and PDF `2017-neurips-attention-is-all-you-need.pdf`. Because the metadata is only known after Phase 1 reads the paper, the dir is created under a provisional (PDF-basename) name and renamed to this slug in Phase 1.

Build the slug as lowercase ASCII kebab-case, filesystem-safe:
- `{year}` — 4-digit publication year as printed; for a preprint, the arXiv year; if truly absent, `nd`.
- `{venue}` — the venue acronym as printed, lowercased (`neurips`, `icml`, `iclr`, `cvpr`, `acl`, …); for a journal with no acronym, a short lowercase form; for a preprint with no venue, `arxiv`.
- `{short-title}` — the title reduced to its key content words, lowercased, spaces → `-`, punctuation stripped; drop a leading article and any subtitle after a colon. Aim for ≤6 words.
- Sanitize the whole slug: keep only `[a-z0-9-]`, collapse repeated `-`, and trim leading/trailing `-`.

## Work directory layout

```
<dir>/<slug>/                  # work dir (named {year}-{venue}-{short-title})
├── <slug>.pdf                 # source PDF, collected in + renamed at Finalize (on confirmation)
├── paper.bib                  # Phase 1: citation (dblp canonical BibTeX, or printed-metadata fallback)
├── spine.md                   # Phase 1: confirmed facts (thesis + direction, running-example map, headline numbers + scope, figure-verified facts) — handed to every perspective and used as the Finalize sweep's oracle
├── ocr/                       # MinerU OCR output (always produced)
│   ├── paper.md               # full text as Markdown (LaTeX math), [pNN] anchors
│   ├── figures.md             # metadata index: label / file / page / caption per image
│   └── figures/fig-03.jpg     # figures & tables, named by paper number (fig-NN / table-NN)
└── reports/
    ├── overview.md            # Phase 1: Ochiai-format overview + section map
    ├── background.md          # Phase 2: 背景と問題設定（動機・提案の意義）
    ├── method.md              # Phase 2: 技術・手法の詳細
    ├── experiments.md         # Phase 2: 実験設定と結果
    ├── discussion.md          # Phase 2: 議論・限界・今後
    └── related-work.md        # Phase 2: 位置づけ + 次に読むべき論文 (dblp-verified)
```
