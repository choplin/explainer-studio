---
name: paper-explainer-summarize
description: "Digest an academic paper into a structured overview and perspective reports covering background, method, experiments, discussion, and related work. Use for conference or journal papers and preprints. Use pdf-explainer-summarize for books, manuals, dissertations, or other long non-paper PDFs."
user-invocable: true
---

# Paper Summary Pipeline

Digest an academic paper into `reports/overview.md` (a TL;DR + key figure, the Ochiai format's 6 questions capturing novelty, usefulness, and validation, and short 前提知識 / 原文の読み方 sections) plus per-perspective detail reports written by parallel perspective agents. Papers are short (8–30 pages), so the heavy 3-phase pipeline of pdf-explainer is unnecessary — Phase 1 runs inline in the orchestrator; only the perspective reports fan out:

```
Phase 1 (orchestrator, inline)              Phase 2 (paper-detail, parallel)     Finalize
read paper (local MinerU OCR)          →    reports/background.md            →   consistency & faithfulness
biblio metadata + section map [pNN]         reports/method.md                    sweep over the whole set
write spine.md (confirmed facts)            reports/experiments.md               (paper-explainer-consistency-
write reports/overview.md                   reports/discussion.md                sweep) → targeted fixes
   (spine handed to every perspective)      reports/related-work.md (dblp)
```

The work dir's internal layout (a self-contained dir holding `<dir-name>.pdf`, `reports/*.md`, and `[pNN]` anchors) is deliberately identical to pdf-explainer, so explainer-audio-dialogue and pdf-explainer-generate-site work on these artifacts unchanged. (Only the dir *name* differs — paper-explainer uses a `{year}-{venue}-{short-title}` citation slug; the pdf-explainer skills take the work dir as input, so the name does not matter to them.)

`<SKILL_DIR>` below is this skill's own base directory; the bundled scripts live at `<SKILL_DIR>/scripts/`. Reference them by that skill-root-relative path — no absolute or plugin-root paths.

## Before starting — read the runtime contract

Read [`references/runtime-and-ocr.md`](references/runtime-and-ocr.md) completely before running any command or creating the work directory. It contains the original Gotchas, Prerequisites, naming convention, and work-directory layout without abridgment.

## Step 0 — Confirm scope once, up front

One interactive gate before any work; do not re-prompt between phases. (OCR needs no question — MinerU runs locally and was already verified in Prerequisites; mention it will run and that a first run downloads models and takes a while.) Ask:

1. **Detail reports** — *default: all five* (background / method / experiments / discussion / related-work). Accept a subset or "overview only".
2. **Collect the source PDF into the work dir at Finalize?** — note the answer now so it is not asked again.

## Phase 1 — Read the paper and write the overview (inline)

Read [`references/phase-1.md`](references/phase-1.md) completely and follow it end-to-end. When it reaches the overview template, read [`references/overview-template.md`](references/overview-template.md) completely before writing `reports/overview.md`.

## Phase 2 — Perspective detail reports (parallel)

Write one perspective detail report per in-scope perspective (background / method / experiments / discussion / related-work) by applying the **`paper-explainer-paper-detail`** skill — it holds the per-perspective report templates and the strict bibliographic constraints. Run the perspectives **in parallel**:

- **Under Claude Code**, dispatch one `paper-explainer-paper-detail` subagent per in-scope perspective (multiple Agent calls in one message) so each report is written in an isolated context and they run concurrently.
- **Otherwise**, apply the `paper-explainer-paper-detail` skill inline, once per perspective, keeping each report's work self-contained.

Either way, provide each perspective run only the inputs below; the report structure and constraints come from the skill itself, not from the orchestrator:

- The perspective (`background` / `method` / `experiments` / `discussion` / `related-work`)
- The source — OCR ran: absolute path to `<WORK_DIR>/ocr/paper.md`; otherwise: the PDF absolute path plus the perspective's page span (from the section map, ±1 page margin; when in doubt, the span may generously cover the whole body — papers are short)
- The section map (compact, from Phase 1)
- **The assigned figure/table files** — from `<WORK_DIR>/ocr/figures/`, the files whose page falls in this perspective's span. Read each file's page from `<WORK_DIR>/ocr/figures.md` (the filename encodes the paper number, not the page). Every one must be explained. **Assign each figure to exactly one in-scope perspective** so none is duplicated or dropped: by its page → the perspective whose span contains it; when a page is shared, route by kind (teaser/motivating-example figures → background; architecture/overview/method figures → method; result plots/tables → experiments). Hold any figure whose page is covered *only* by an out-of-scope perspective for the overview (handled at Finalize).
- The output absolute path `<WORK_DIR>/reports/<perspective>.md`
- The report language
- **The spine** — the absolute path to `<WORK_DIR>/spine.md`. Every perspective gets it and treats it as authoritative for the facts it covers (thesis + direction, future-direction conclusion, running-example map, headline numbers + scope, figure-verified facts), rather than independently re-deriving them from OCR prose and diverging. The overview and each detail report are written independently and never reconciled afterward, so these facts must be taken from the one shared source, not rediscovered per report. (The `paper-explainer-paper-detail` skill states how a perspective consumes the spine, including the "figure wins over a wrong spine row" safety net.)
- For `related-work` additionally: the absolute path to `<SKILL_DIR>/scripts/dblp_lookup.sh` and the References `[pNN]` span

Perspective → relevant sections, when resolving spans: background → abstract + introduction + motivation/background sections; method → approach/method + preliminaries; experiments → experiments/evaluation + result appendices; discussion → discussion/limitations/conclusion; related-work → related work + introduction + references. (background and related-work both draw on the introduction — background from its motivation/problem framing, related-work from its cited prior work.)

**Context hygiene:** each perspective writes its report to a file and returns only a path + one-line status. Do not fold a full detail report back into the orchestrator context. The whole-set read that Finalize needs (all reports at once, to catch cross-report contradictions) is done by the **consistency sweep in its own isolated context** — only its findings list returns to the orchestrator, so hygiene is preserved even though the whole set is read. The orchestrator's own Finalize reads stay *narrow*: the "次に読むべき論文" section of `related-work.md` (for overview item 6), and the specific loci the sweep flags (to apply targeted fixes). (When dispatching to subagents this is automatic; when applying the skill inline, keep the same discipline — do the sweep as a self-contained pass and carry back only its findings.)

## Finalize

Read [`references/finalize.md`](references/finalize.md) completely and follow it end-to-end. That reference contains the original Finalize procedure and Success criteria without abridgment.

## Bundled scripts

- **`scripts/preflight.sh <command> [args…]`** — resolves the skill's runtime env once (poppler + a MinerU source), then execs the command inside it: PATH mode when poppler + (`uv`, or `mineru` + `python3`) are present, else `nix develop` when a `flake.lock` is bundled and `nix` is available, else an aggregated fail listing both setup options (nix / manual). Launch `mineru_ocr.sh` through it (`preflight.sh bash …/mineru_ocr.sh <pdf> <ocr-dir>`). Does not choose the MinerU source itself — the worker does that PATH-first (installed `mineru`, else `uvx --from 'mineru[core]' mineru`).
- **`scripts/mineru_ocr.sh <pdf> <ocr-dir>`** — reads the PDF **locally** with MinerU (`-b pipeline`, text mode for born-digital PDFs / OCR mode for scanned ones, chosen by probing the text layer) and materializes `ocr/paper.md`, `ocr/figures/` (figures/tables named by paper number `fig-NN` / `table-NN`), and `ocr/figures.md` (metadata index: label / file / page / caption, plus a "⚠ Not extracted" section for regions MinerU located but failed to crop) via `mineru_to_paper_md.py`. Launch it through `scripts/preflight.sh` (which supplies poppler + a MinerU source). MinerU is resolved PATH-first: an installed `mineru` is used as-is, else `uvx --from 'mineru[core]' mineru` resolves it into uv's shared tool cache (no manual install; first run syncs the tool env and downloads models — slow). How the two scripts turn MinerU's layout skeleton + the PDF text layer into `paper.md` (and the fidelity trade-offs) is documented in [`docs/ocr-pipeline.md`](docs/ocr-pipeline.md).
- **`scripts/dblp_lookup.sh "<title> <first-author surname>"`** — queries the public dblp API and prints candidate records as JSON lines (`{key, type, title, authors, venue, year, doi, url}`). No key needed; empty output = no hit. Used by the orchestrator to build `paper.bib` (and to verify related-work when that report is out of scope), and by the `related-work` perspective (pass it the absolute path).
- **`scripts/dblp_bibtex.sh "<dblp-key>"`** — fetches the canonical BibTeX for a dblp record key (the `key` from `dblp_lookup.sh`), retrying dblp's transient 503s. Exits non-zero and prints nothing on failure so the caller falls back to a hand-built entry. No key needed.
