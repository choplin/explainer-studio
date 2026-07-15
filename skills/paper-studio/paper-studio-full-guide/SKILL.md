---
name: paper-studio-full-guide
description: This skill should be used when the user wants to run the WHOLE paper-studio pipeline end-to-end on one academic paper PDF in a single request — from the Ochiai-format summary and per-perspective reports, to a two-speaker audio guide of the overview, to a browsable website of the reports. Triggers on "この論文を全部やって", "サマリから音声・サイトまで一気に", "論文を音声ガイドとサイトまで", "全ステップ実行して", "run the whole paper pipeline / do everything for this paper / from summary to audio and site". It chains paper-studio-summarize → pdf-studio-audio-dialogue → pdf-studio-audio-narrate (overview only) → paper-studio-generate-site (and hands off to pdf-studio-deploy-site for publishing). Should NOT trigger for a single phase (use those sub-skills directly), for a non-paper document (use pdf-studio-full-guide), or for a paper already partway through the pipeline where only remaining steps are wanted (invoke the remaining sub-skills).
user-invocable: true
---

# Full Guide — one paper, all the way to audio and site

Run the entire paper-studio pipeline on a single academic paper as one job:

```
summarize                → audio-dialogue → audio-narrate → generate-site
overview.md + reports/*    dialogue/overview.txt  audio/overview.m4a   site/
```

This skill is **only orchestration**: it decides scope and order, and runs each phase against the right inputs. Every phase's *how* lives in the sub-skill it delegates to — do not re-derive or duplicate their procedures here. Follow each referenced skill's own SKILL.md when you reach that phase; if a sub-skill's step fails, stop and report rather than working around it.

**The audio is overview-only by design.** A paper's overview is the single broad guide worth narrating; the perspective detail reports are for reading, not listening. So this pipeline synthesizes exactly one audio guide — from `reports/overview.md` — and does not fan out per-perspective audio. (A user who wants audio of a specific detail report can run [[pdf-studio-audio-dialogue]] on it directly.)

## Prerequisites

- **MinerU + poppler** — required by [[paper-studio-summarize]] to read the paper (MinerU is resolved automatically PATH-first, else via `uvx`; poppler supplies `pdfinfo`/`pdftotext`/`pdftoppm`). See that skill's Gotchas; the runtime is resolved by its `preflight.sh`. If unresolvable, [[paper-studio-summarize]] stops — do not work around it.
- **VOICEVOX ENGINE + `ffmpeg`** — for the audio synthesis step ([[pdf-studio-audio-narrate]] synthesizes via a local VOICEVOX ENGINE and encodes m4a with `ffmpeg`). If either is unavailable, the pipeline still runs through the dialogue script; skip the synthesis and say so.
- **`understanding-html-docs` and `pdf-studio-site-base` skills** — the site build step's design-system substrate ([[paper-studio-generate-site]] copies its assets from them). If either is not installed, [[paper-studio-generate-site]] stops rather than guessing an asset path; skip the site build and say so.
- The source PDF path, and its page count (`pdfinfo <path> | grep Pages`). If it exceeds ~30 pages of body, this is a book/thesis — point the user to [[pdf-studio-full-guide]] and stop unless they explicitly want the paper pipeline anyway.

`<WORK_DIR>` is the single work dir [[paper-studio-summarize]] defines — created provisionally from the PDF basename and renamed to the `{year}-{venue}-{short-title}` citation slug in its Phase 1. Everything below lands there.

## Step 0 — Confirm scope once, up front (do this before any work)

This is the one interactive gate. Because the full run can fan out to parallel workers and audio synthesis, confirm the scope **once** here, then run the rest without stopping between phases (unless something fails). Ask the user, offering these defaults — and note the answers to [[paper-studio-summarize]]'s own Step 0 questions here so that skill is **not re-prompted** mid-run:

0. **Existing work dir** — if a prior run's work dir already holds outputs (`reports/`, `dialogue/`, `audio/`, `site/`), say so and confirm before overwriting: regenerate in place, or use a different work-dir name to keep the old one. No prompt when it is new.
1. **Detail reports** — *default: all five* (background / method / experiments / discussion / related-work). Accept a subset or "overview only". (This is [[paper-studio-summarize]]'s Step 0 question 1.)
2. **Audio guide** — *default: yes.* Whether to produce the overview audio guide (a two-speaker guide of `reports/overview.md`). Accept "none" to stop after the reports/site. (Audio is overview-only — there is no per-perspective audio option.)
3. **Site** — *default: build the site.* Whether to author a browsable website from the reports ([[paper-studio-generate-site]]). Accept "none" to stop after the reports/audio. **Publishing is not part of this run**: the site is only *built* locally so it can be reviewed; [[pdf-studio-deploy-site]] is offered at the end and confirmed then, never auto-run.
4. **Collect the source PDF into the work dir at the end?** — [[paper-studio-summarize]]'s Step 0 question 2; note the answer now so it is not asked again.

State the rough cost implication (e.g. "all five reports + audio + site ≈ 5 perspective workers, 1 audio guide, and 6 authored site pages"). Honor any subset the user names over the defaults.

## Step 1 — Summary + perspective reports

Follow **[[paper-studio-summarize]]** in full: Phase 1 (inline MinerU OCR read, bibliographic metadata + section map, `spine.md`, `reports/overview.md`), Phase 2 (parallel perspective detail reports for the in-scope perspectives), and its Finalize (figure coverage + the consistency & faithfulness sweep + fixes). Use the Step 0 answers you already collected — do **not** let it re-ask the detail-report scope or the PDF-collect question. Concretely: supply the detail-report scope and the PDF-collect answer from Step 0 directly when applying [[paper-studio-summarize]], and skip its Step 0 gate rather than re-presenting it.

- This produces `<WORK_DIR>/reports/overview.md` and the in-scope `reports/<perspective>.md`, `<WORK_DIR>/spine.md`, `paper.bib`, and the `ocr/` artifacts.
- [[paper-studio-summarize]] runs its **own** consistency sweep at Finalize (the whole-report-set check). Do not add a second sweep here — unlike the book pipeline, the paper pipeline's accuracy guard already lives inside Step 1.

## Step 2 — Overview audio guide (unless "none" in Step 0)

Produce exactly one audio guide, from the overview:

1. **Dialogue script** — follow **[[pdf-studio-audio-dialogue]]** pointed at `<WORK_DIR>/reports/overview.md`, writing `<WORK_DIR>/dialogue/overview.txt` — a **broad** two-speaker guide touring the paper's key points. Let the source set the length; do not write to a runtime.
2. **Synthesis** — run **[[pdf-studio-audio-narrate]]** on `dialogue/overview.txt` to synthesize `<WORK_DIR>/audio/overview.m4a`. Report the output path and duration.
   - Needs a VOICEVOX ENGINE and `ffmpeg`. If either is unavailable, skip synthesis and tell the user the dialogue script is ready to narrate elsewhere.
   - [[pdf-studio-audio-narrate]] talks to the VOICEVOX ENGINE over `localhost`, which the command sandbox blocks — run its script without sandboxing (see that skill's note).

Run this **before** Step 3: the overview site page embeds `audio/overview.m4a` as an in-page player, so the audio must exist first.

## Step 3 — Site (unless "none" in Step 0)

Follow **[[paper-studio-generate-site]]** in full to build a browsable website under `<WORK_DIR>/site/` from `reports/` (and the overview `audio/` guide, played in-page): scaffold assets and figures, author one page per report in parallel (in the canonical perspective order, with perspective kicker labels), write the landing page, then run its own [[understanding-html-docs-review]] pass over every page and fix what it finds.

- **Build only — do not deploy here.** [[paper-studio-generate-site]] deliberately keeps `site/` local so it can be reviewed before going public; publishing is [[pdf-studio-deploy-site]]'s job and is handled at Finalize as an offer, confirmed then.
- Delegate the mechanics (scaffold, per-page authoring, index, review) to [[paper-studio-generate-site]] — do not duplicate them here. If `understanding-html-docs` or `pdf-studio-site-base` is not installed, it stops; skip the site build and say so rather than working around it.

## Finalize

- **PDF collection** is handled inside [[paper-studio-summarize]]'s Finalize (Step 1), per the Step 0 answer — nothing to redo here.
- **Offer deployment (do not auto-run).** If the site was built (Step 3), tell the user it is ready under `<WORK_DIR>/site/` and offer to publish it with [[pdf-studio-deploy-site]] (a subpath of the shared Cloudflare Pages library, Access-protected) — deployment is outward-facing, so confirm before running it, and note that a first-ever deploy needs the one-time [[pdf-studio-initialize-site]] setup. Do not deploy without explicit confirmation.
- Print a short manifest of everything produced: `reports/overview.md`, each in-scope `reports/<perspective>.md`, `spine.md`, `paper.bib`, `dialogue/overview.txt`, `audio/overview.m4a`, and the built `site/` (with its page count) — grouped by phase, with the work dir path.

## Orchestration rules

- **Confirm once (Step 0), then run through.** Do not re-prompt between phases; only stop on a real failure (unresolvable MinerU runtime, unwritable work dir, a sub-skill error).
- **Delegate, don't duplicate.** Each phase's mechanics (OCR, spine, perspective templates, dialogue patterns, voices, site classes) live in the sub-skill — follow it there so this orchestrator stays correct if a sub-skill changes.
- **Parallelize the independent fan-outs** — the perspective reports (Step 1, via [[paper-studio-summarize]]) and per-report site-page authoring + review (Step 3, via [[paper-studio-generate-site]]) — and keep dependent phases sequential (each step needs the prior step's files; audio before site).
- **File-based hand-off only.** Sub-skills and workers write to files under `<WORK_DIR>` and return short status; never echo report or page text back into the orchestrator's context.

## Success criteria (verify the deliverables)

- [ ] Scope (detail reports subset or overview-only, audio yes/none, site build or none, PDF-collect) was confirmed with the user **before** any work started, and the run proceeded from Step 0 to the manifest **without a second interactive scope prompt** (the Step 0 answers alone carried it through).
- [ ] `reports/overview.md` exists in the Ochiai format, and every in-scope `reports/<perspective>.md` exists; `spine.md` and `paper.bib` were produced, and [[paper-studio-summarize]]'s own Finalize consistency sweep ran.
- [ ] Unless audio was "none": `dialogue/overview.txt` exists in the `A:`/`B:` format faithful to the overview, and (when VOICEVOX + ffmpeg are available) a non-empty `audio/overview.m4a` was produced and its path + duration reported; otherwise audio was skipped with a clear note.
- [ ] The overview audio was produced **before** the site build, so the overview site page can embed it.
- [ ] Unless the site was "none": `<WORK_DIR>/site/` was built via [[paper-studio-generate-site]] (a page per report in the canonical perspective order with perspective kickers, its own review pass applied) and **not** deployed without explicit confirmation; the user was told it is ready and offered [[pdf-studio-deploy-site]]. (If `understanding-html-docs` / `pdf-studio-site-base` were missing, the site was skipped with a clear note.)
- [ ] A final manifest of all artifacts (with the work dir path) was shown to the user.
