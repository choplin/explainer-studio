---
name: pdf-studio-full-guide
description: This skill should be used when the user wants to run the WHOLE pdf-studio pipeline end-to-end on one PDF in a single request — from summary, through a detailed report per chapter, to a two-host dialogue script, to synthesized audio. Triggers on "この本を全部やって", "一冊まるごと音声ガイドまで", "summaryから音声まで一気に", "全ステップ実行して", "run the whole pipeline / do everything for this PDF / from summary to audio". It chains pdf-studio-summarize → pdf-studio-deep-dive (per chapter) → pdf-studio-audio-dialogue → pdf-studio-audio-narrate. Should NOT trigger for a single phase (use those sub-skills directly), or for a PDF already partway through the pipeline where only remaining steps are wanted (invoke the remaining sub-skills).
user-invocable: true
---

# Full Guide — one PDF, all the way to audio

Run the entire pdf-studio pipeline on a single PDF as one job:

```
summarize → deep-dive (per chapter) → audio-dialogue → audio-narrate
overview.md   reports/<ch>.md          dialogue/*.txt    audio/*.m4a
```

This skill is **only orchestration**: it decides scope, order, and what to run against what. Every phase's *how* lives in the sub-skill it delegates to — do not re-derive or duplicate their procedures here. Follow each referenced skill's own SKILL.md when you reach that phase; if a sub-skill's step fails, stop and report rather than working around it.

## Prerequisites

- **poppler** (`command -v pdftoppm`) — required by the reading phases. If missing, install per [[pdf-studio-summarize]]'s gotcha (`brew install poppler` / `apt-get install poppler-utils`). Do not remove it.
- **VOICEVOX ENGINE + `ffmpeg`** — for the audio synthesis step ([[pdf-studio-audio-narrate]] synthesizes via a local VOICEVOX ENGINE and encodes m4a with `ffmpeg`; both are cross-platform). If either is unavailable, the pipeline still runs through the dialogue script; skip audio and say so.
- The source PDF path, and its page count (`pdfinfo <path> | grep Pages`).

`<WORK_DIR>` is the single work dir named after the PDF's basename (`<dir>/<name>/`), exactly as [[pdf-studio-summarize]] defines it. Everything below lands there.

## Step 0 — Confirm scope once, up front (do this before any work)

This is the one interactive gate. Because the full run can fan out to many workers and long audio synthesis, confirm the scope **once** here, then run the rest without stopping between phases (unless something fails). Ask the user, offering these defaults:

0. **Existing work dir** — if `<WORK_DIR>/` already holds a prior run's outputs (`reports/`, `dialogue/`, `audio/`, …), say so and confirm before overwriting them: regenerate in place, or use a different work-dir name to keep the old one. No prompt when the work dir is new. (This one confirmation covers the whole run — the sub-skills below don't re-ask per file.)
1. **Chapters to detail** — *default: all top-level chapters.* Accept a subset ("2章と4章だけ") or "none" (overview only). The chapter list is not known yet; if the user wants a subset by name, resolve it after [[pdf-studio-summarize]] produces the spine `toc.md` and re-confirm the matched chapters.
2. **Audio scope** — which reports become an audio guide:
   - **A** — overview only (one broad guide).
   - **B** — each in-scope chapter detail only (one focused guide per chapter).
   - **C** *(default)* — overview **and** every in-scope chapter detail.
   - **none** — stop after the reports; produce no dialogue/audio.
3. **Audio length** — *default: no target.* [[pdf-studio-audio-dialogue]] lets each report's own content decide the runtime, on purpose — writing to a fixed length pads the script with hollow exchanges. Only pass a length if the user asks for one, and pass it through as a coverage budget, not a quota.
4. **Collect the source PDF into the work dir at the end?** — deferred to Finalize; [[pdf-studio-summarize]] normally asks this. Note it here so it is not asked again mid-run.
5. **Text source** — *default: visual reading* (any PDF). Only if the born-digital probe passes ([[pdf-studio-summarize]]'s `text_layer.sh --probe`), offer the **text-layer** option (more faithful for code / commands / numbers / console output, born-digital ebooks only). This is [[pdf-studio-summarize]]'s Step 0 question, asked here so it is not asked again.
6. **Figure harvest** — runs during Step 1 with its runtime resolved automatically by [[pdf-studio-summarize]]'s `preflight.sh` (poppler + MinerU from PATH/uv, else the bundled flake; crops diagrams/plots into `ocr/figures/`; a first run downloads models and runs unsandboxed). Default on; note it here and let the user skip it, and know it self-skips if the runtime is unresolvable.

State the rough cost implication (e.g. "all 8 chapters + option C ≈ 8 deep-dive workers and 9 audio guides"). If the user names a target length or subset, honor it over the defaults.

## Step 1 — Summary

Follow **[[pdf-studio-summarize]]** in full (Phase 1 extract → Phase 2 stitch → Phase 3 overview), including body-start detection, `[pNN]` anchors, and the `## Page offset` field. Produces `<WORK_DIR>/structured/toc.md` (the canonical spine), `<WORK_DIR>/structured/outline.md`, and `<WORK_DIR>/reports/overview.md`.

- **Defer the "collect the source PDF" finalize step** to this skill's Finalize (below). Keeping the PDF at its original path until the end means [[pdf-studio-deep-dive]] resolves a stable source in Step 2.

## Step 2 — Detail every in-scope chapter

Read `<WORK_DIR>/structured/toc.md` (the canonical spine; fall back to `outline.md` only for a pre-spine digest), enumerate the **top-level chapters** (level-1 headings) and their `[pNN]` anchors, and intersect with the Step 0 chapter scope. For each in-scope chapter, run **[[pdf-studio-deep-dive]]** to produce `<WORK_DIR>/reports/<chapter-slug>.md`:

- Resolve each chapter's page span from its anchors (with [[pdf-studio-deep-dive]]'s ~2-page margins) and apply the `pdf-studio-pdf-detail` procedure per chapter. Chapters are independent — **run them in parallel** (under Claude Code, multiple `pdf-studio-pdf-detail` Agent calls in one message; otherwise apply the skill per chapter), as many at a time as is reasonable.
- **If text-layer was chosen in Step 0**, run each chapter's detail worker in text-layer mode exactly as [[pdf-studio-deep-dive]]'s Procedure does: materialize the chapter span's faithful text with [[pdf-studio-summarize]]'s `text_layer.sh` (through `preflight.sh`) into `<WORK_DIR>/extract/text-<START>-<END>.md` and pass that file to the worker instead of a page range. The probe already passed in Step 0, so do not re-probe or re-ask.
- **Pass each worker its span's figure crops.** From `<WORK_DIR>/ocr/figures.md`, hand each chapter worker the rows whose page falls in its span, with the crop file paths, so it can read and describe in-figure content. This matters most in text-layer mode, where the crops are the worker's only view of values baked into diagrams (the text layer drops them) — without them, readable figure content is silently lost. If figure harvest was skipped, tell the worker none are available.
- **Fix the register up front so the reports read as one set.** Instruct every parallel worker to write in one uniform register — for Japanese, である調（常体） — so chapters do not drift between plain and polite forms. (The `pdf-studio-pdf-detail` procedure fixes this too; state it here because the workers run in parallel and independently, and register drift between them is otherwise invisible until Finalize.)
- **Context hygiene (same rule as [[pdf-studio-summarize]]):** each deep-dive writes its report to a file and returns only a short status. Never read PDF pages or the full chapter reports into this orchestrator's context.
- If the chapter scope was "none", skip this step.

## Step 3 — Dialogue scripts

For each audio target selected in Step 0 (per scope A / B / C), follow **[[pdf-studio-audio-dialogue]]** to write a `<WORK_DIR>/dialogue/<slug>.txt` script:

- overview → `dialogue/overview.txt` — a **broad** guide (touches every top-level section lightly).
- each in-scope chapter report → `dialogue/<chapter-slug>.txt` — a **focused, deeper** guide.
- Use the Step 0 length for each. Let the source set depth (overview → broad, detail → deep).
- These are independent per target; they may be written in parallel, but keep each faithful to its own source report.

## Step 4 — Audio

For each dialogue script from Step 3, run **[[pdf-studio-audio-narrate]]** to synthesize `<WORK_DIR>/audio/<slug>.m4a`. Report each output path and duration.

- Needs a VOICEVOX ENGINE and `ffmpeg`. If either is unavailable, skip and tell the user the dialogue scripts are ready to narrate elsewhere.
- [[pdf-studio-audio-narrate]] talks to the VOICEVOX ENGINE over `localhost`, which the command sandbox blocks — run its script without sandboxing (see [[pdf-studio-audio-narrate]]'s note).

## Finalize

- **Cross-chapter consistency sweep (accuracy guard).** After all chapter reports are written, read the finished `reports/*.md` and check for: (a) a proper noun's classifying attribute stated inconsistently across chapters — e.g. a system called column-oriented in one chapter and row-oriented in another; at most one is right, so re-read the offending source span to settle it; and (b) register drift — a chapter in ですます調 when the set is である調. Fix what you find. This is a light editorial pass over the reports only — do not re-run the reading phases. It is the book-pipeline analogue of paper-studio's consistency sweep, and the net that catches per-chapter faithfulness/style errors the individual workers can't see across each other.
- If the user said yes in Step 0, collect the source PDF into the work dir as `<WORK_DIR>/<name>.pdf` (per [[pdf-studio-summarize]]'s finalize). Otherwise leave it in place.
- Print a short manifest of everything produced: `overview.md`, each `reports/<chapter>.md`, each `dialogue/<slug>.txt`, each `audio/<slug>.m4a` — grouped by phase, with the work dir path.

## Orchestration rules

- **Confirm once (Step 0), then run through.** Do not re-prompt between phases; only stop on a real failure (missing poppler, unwritable work dir, a sub-skill error).
- **Delegate, don't duplicate.** Each phase's mechanics (chunk sizes, worker types, dialogue patterns, voices) live in the sub-skill — follow it there so this orchestrator stays correct if a sub-skill changes.
- **Parallelize the independent fan-outs** — extraction chunks (Step 1, via [[pdf-studio-summarize]]) and per-chapter deep-dives (Step 2) — and keep dependent phases sequential (each step needs the prior step's files).
- **File-based hand-off only.** Sub-skills and workers write to files under `<WORK_DIR>` and return short status; never echo report or page text back into the orchestrator's context.

## Success criteria (verify the deliverables)

- [ ] Scope (chapters, audio A/B/C or none, length, PDF-move) was confirmed with the user **before** any work started.
- [ ] `structured/toc.md` (the canonical spine) exists, and `reports/overview.md` covers every top-level section in it.
- [ ] `reports/<chapter>.md` exists for every in-scope chapter (none silently dropped).
- [ ] Each chapter worker was handed its span's figure crops (when `ocr/figures.md` exists) and a fixed register directive; the cross-chapter consistency sweep ran and no proper noun's classifying attribute or report register is inconsistent across chapters.
- [ ] For the selected audio scope, a `dialogue/<slug>.txt` exists for each target, in the `A:`/`B:` format, faithful to its source report.
- [ ] For each dialogue script (when VOICEVOX + ffmpeg are available), a non-empty `audio/<slug>.m4a` was produced and its path + duration reported; otherwise audio was skipped with a clear note.
- [ ] A final manifest of all artifacts (with the work dir path) was shown to the user.
