---
name: paper-studio-summarize
description: This skill should be used when the user wants to digest an academic paper PDF (conference/journal paper or preprint, mainly CS; usually 8–30 pages — content type, not page count, is the deciding factor) into a structured summary — an Ochiai-format overview plus per-perspective detail reports (background / method / experiments / discussion / related-work). Triggers on "この論文をまとめて/要約して", "論文サマリを作って", "落合フォーマットで読んで", "summarize this paper", "digest this arXiv paper", "make a paper report". Should NOT trigger for non-paper documents (books, manuals, dissertations — use pdf-studio-summarize), for papers over ~30 pages of body (offer pdf-studio-summarize, but default here for anything the user calls a "paper"), for drilling into one section of an already-digested document (use pdf-studio-deep-dive), or for raw OCR/text extraction without synthesis.
version: 0.1.0
user-invocable: true
---

# Paper Summary Pipeline

Digest an academic paper into `reports/overview.md` (a TL;DR + key figure, the Ochiai format's 6 questions capturing novelty, usefulness, and validation, and short 前提知識 / 原文の読み方 sections) plus per-perspective detail reports written by parallel perspective agents. Papers are short (8–30 pages), so the heavy 3-phase pipeline of pdf-studio is unnecessary — Phase 1 runs inline in the orchestrator; only the perspective reports fan out:

```
Phase 1 (orchestrator, inline)              Phase 2 (paper-detail, parallel)
read paper (local MinerU OCR)          →    reports/background.md
biblio metadata + section map [pNN]         reports/method.md
write reports/overview.md                   reports/experiments.md
                                            reports/discussion.md
                                            reports/related-work.md   (dblp-verified)
```

The work dir's internal layout (a self-contained dir holding `<dir-name>.pdf`, `reports/*.md`, and `[pNN]` anchors) is deliberately identical to pdf-studio, so pdf-studio-audio-dialogue, pdf-studio-generate-site, and pdf-studio-deep-dive work on these artifacts unchanged. (Only the dir *name* differs — paper-studio uses a `{year}-{venue}-{short-title}` citation slug; the pdf-studio skills take the work dir as input, so the name does not matter to them.)

`<SKILL_DIR>` below is this skill's own base directory; the bundled scripts live at `<SKILL_DIR>/scripts/`. Reference them by that skill-root-relative path — no absolute or plugin-root paths.

## Gotchas (read before starting)

- **MinerU is a hard requirement — there is no fallback.** This skill reads the paper through local MinerU (`mineru_ocr.sh`), which runs entirely on the machine (nothing is uploaded; safe for confidential manuscripts). Its first run downloads model weights (several GB) and is slow — warn about that. If `mineru` is not installed, **stop the whole skill** at the Prerequisites check and give the user the install command; do NOT fall back to visual reading, to an external OCR API, or to any other reader.
- **Body text comes from the PDF text layer, not from OCR.** For a born-digital PDF (every normal CS paper), `mineru_ocr.sh` uses MinerU (`-b pipeline -m txt`) only for the *layout skeleton* — block reading order, figure/table crops, and formula LaTeX — and refills the prose from the PDF's own text layer via `pdftotext`. This is deliberately faithful: image OCR on the ACM/LinLibertine font class drops descenders ("making"→"makin"), collapses ff/fi ligatures ("different"→"diferent"), and litters the text with spurious `<sub>`/`<sup>` tags; the text-layer path has none of these. A scanned PDF with no text layer falls back to OCR mode automatically. Do not "fix" the output by re-OCRing or by switching MinerU's default backend (the default is hybrid/VLM, which image-recognizes every page and reintroduces exactly these defects).
- **Never install MinerU (or anything else) yourself.** If `mineru` is missing, print the setup command (`uv tool install "mineru[core]"`) and stop — let the user install it and re-run.
- **Never write bibliographic URLs, DOIs, venues, or years from model memory.** Plausible-looking hallucinated citations are the main failure mode of "papers to read next". Every such fact must come from the paper's own References section or from `scripts/dblp_lookup.sh` output; no dblp match → mark "(dblp未確認)" and give no URL. (The `paper-studio-paper-detail` skill restates this rule with the full lookup procedure — keep both in sync when refining it.)
- **The command sandbox may block network and cache writes.** MinerU's first-run model download and its writes to `~/.cache`, and `dblp.org` (curl), can fail under sandbox. On such an error, rerun the same script without sandboxing — do not switch to a different method or answer from memory.
- **`pdfinfo` / `pdftotext` / `pdftoppm` need system `poppler`, and `mineru_to_paper_md.py` needs `python3`.** `pdfinfo` does the page-count pre-check; `pdftotext` supplies the text layer that `mineru_ocr.sh` refills the body text from; `pdftoppm` renders pages for Finalize figure recovery. The `scripts/preflight.sh` wrapper **resolves** these and then execs the worker: uses them if on PATH, else runs inside the bundled `flake.nix` dev shell when `nix` is available, else fails with both options. To provision them yourself: **nix (one-shot, all-in-one)** `nix develop <SKILL_DIR>` — this also puts `~/.local/bin` on PATH so a uv-installed `mineru` is visible; or **manual** (macOS: `brew install poppler`; Debian/Ubuntu: `apt-get install poppler-utils python3`). `mineru` is never provided by the flake — install it with `uv tool install "mineru[core]"` regardless. Policy: [`docs/skill-runtime-and-dependencies.md`](../../../docs/skill-runtime-and-dependencies.md).
- **`[pNN]` anchors are always PDF page numbers**, not printed page numbers (camera-ready papers often print e.g. 1234–1245).
- **Every captured figure/table must be explained.** MinerU extracts *all* figures/tables into `ocr/figures/`, named by their paper reference number (`fig-NN.<ext>` / `table-NN.<ext>`) with `ocr/figures.md` recording each one's page and caption; the report set must collectively reference and explain every one — no orphan images, no image embedded without explanation. Figures are assigned to perspectives in Phase 2 (page looked up in `figures.md`), and a Finalize coverage sweep catches any that slipped through and places them (with explanation) in the nearest in-scope report or the overview. **MinerU sometimes locates a figure/table region but fails to recognize it** (no crop, no HTML) — the converter surfaces these in a "⚠ Not extracted" section of `figures.md` instead of dropping them, and Finalize step 1 recovers each by rendering the page and cropping (see Finalize).

## Prerequisites

1. Confirm the PDF path and get its page count: `pdfinfo <path> | grep Pages`. If it exceeds ~30 pages (a thesis, a book), point the user to pdf-studio-summarize and stop unless they explicitly want this pipeline anyway.
2. **Verify MinerU is installed: `command -v mineru`. If it is missing, STOP the skill — do not proceed with any fallback reader.** Tell the user to install it (`uv tool install "mineru[core]"`) and re-run; the first run then downloads model weights (several GB). MinerU is the skill's OCR engine and is mandatory by design (local processing keeps under-review manuscripts off the network). The other runtime deps (`python3` + poppler) are resolved by the `scripts/preflight.sh` wrapper that launches `mineru_ocr.sh` (PATH, else the bundled flake); see the poppler/python3 Gotcha above for the one-shot `nix develop <SKILL_DIR>` setup.
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

## Step 0 — Confirm scope once, up front

One interactive gate before any work; do not re-prompt between phases. (OCR needs no question — MinerU runs locally and was already verified in Prerequisites; mention it will run and that a first run downloads models and takes a while.) Ask:

1. **Detail reports** — *default: all five* (background / method / experiments / discussion / related-work). Accept a subset or "overview only".
2. **Collect the source PDF into the work dir at Finalize?** — note the answer now so it is not asked again.

## Phase 1 — Read the paper and write the overview (inline)

No subagent: a paper fits the orchestrator's context, and Phase 2 needs the section map anyway.

**Obtain the text** by running `bash <SKILL_DIR>/scripts/preflight.sh bash <SKILL_DIR>/scripts/mineru_ocr.sh <pdf-abs-path> <WORK_DIR>/ocr` (the `preflight.sh` wrapper resolves the python3+poppler env — PATH or the bundled flake — then execs `mineru_ocr.sh` inside it). It writes `ocr/paper.md` with one `[pNN]` anchor per page — the body text refilled from the PDF's text layer over MinerU's block skeleton (see the Gotcha above), with inline math as `$…$` LaTeX and section headings from MinerU's title blocks. It extracts figures/tables to `ocr/figures/` named by their paper reference number (`fig-NN.<ext>` / `table-NN.<ext>`, e.g. `fig-03.jpg` = Fig. 3), already referenced from `paper.md` by relative path, and writes `ocr/figures.md` — a metadata index mapping each image file to its label, page (`[pNN]`), and caption. (The number comes from the block caption; a caption MinerU dropped is reconstructed from figure order. Because the filename no longer encodes the page, `figures.md` is the authoritative file→page map for Phase 2 assignment.) Tables are kept as both the cropped image and their cell text (`<table>` HTML), so numeric results survive in the text stream. Footnotes are preserved as GitHub-flavored footnotes — a body reference as `[^N]` and its definition as `[^N]: …` — so the body↔footnote link is kept. This covers both numeric footnotes and symbol footnotes (`∗`/`†`/`‡` author/affiliation notes, label e.g. `[^star-p01]`, page-scoped since symbols are reused across pages). If MinerU located a figure/table but could not extract it, `figures.md` ends with a "⚠ Not extracted" section listing it for Finalize recovery (the script also prints a `⚠ N figure/table(s)…` line). MinerU can take minutes — run it with a generous timeout. Then Read `ocr/paper.md`. On failure, report the error and stop — do not fall back to another reader (a missing `mineru` should already have stopped the run at Prerequisites).

**Extract while reading:**
- Bibliographic metadata: title, authors, venue/journal, year, DOI or arXiv URL — **only what is printed in the paper**; if the venue is not printed (arXiv preprint), write "不明 (preprint)" rather than guessing.
- A section map: every section with its `[pNN]` span, including the References span (Phase 2 needs it).

**Rename the work dir to the citation slug.** Build `{year}-{venue}-{short-title}` from the metadata (see **Naming convention**) and rename the provisional work dir to `<dir>/<slug>/`; use the renamed path as `<WORK_DIR>` for the overview, Phase 2, and Finalize. Skip the rename if the dir is already so named (re-run). If a *different* directory of that name already exists, do not clobber it — keep the provisional name, note the collision, and continue.

**Build `<WORK_DIR>/paper.bib`** — the paper's own citation, dblp-verified like every other bibliographic fact (never hand-typed from memory):
1. Run `bash <SKILL_DIR>/scripts/dblp_lookup.sh "<title> <first-author surname>"`. Pick the hit whose title/authors/year match the paper; when both a peer-reviewed venue and a CoRR/arXiv preprint (`type` = "Informal and Other Publications") match, prefer the peer-reviewed one.
2. On a confident match: `bash <SKILL_DIR>/scripts/dblp_bibtex.sh "<key>" > <WORK_DIR>/paper.bib` (the `key` field from step 1).
3. On no confident match, or if `dblp_bibtex.sh` fails: hand-build a minimal entry from the paper's **printed** metadata only — cite key = the work-dir slug; `@inproceedings` / `@article` / `@misc` by venue kind; fields limited to `author`, `title`, `year`, plus `booktitle`-or-`journal` / `doi` / `url` that actually appear in the paper — and prepend a comment line `% not dblp-verified — from the paper's printed metadata`. Never invent a venue, DOI, or URL.

**Write `reports/overview.md`** following the template below, in the conversation language (or the user's requested language). Rules:
- **Follow each item's writing discipline** (the bracketed guidance in the template). The Ochiai format's value is the sharpness of its six questions — a vague, adjective-laden answer wastes it. Concretely: item 1 must contain a one-sentence "X は Y する Z である" definition; item 2 must name the specific prior methods the paper compares against (never anonymous "既存手法"); item 4 must give numbers (`<baseline> 比 +N% on <benchmark>`), not "大幅に改善".
- **Surface the paper's own thesis, not only per-item facts.** The six questions decompose the paper side by side, so its own overall verdict — the judgment that ties several results together (a superiority / asymmetry / trade-off conclusion, usually the Abstract's "we show / reveal / find that …" sentence) — has no dedicated item and is easily lost as a list of separate numbers. Extract that thesis in one sentence from the Abstract's own claim sentence and put it in the TL;DR (or a closing 総括 line); when several results are reported, keep the *relation* the paper draws between them (which is stronger, under what condition, at what cost), not just the individual values — that relation is the finding. **Then verify its direction against the Abstract's own sentence** (which side is stronger / which of two things holds more, in the paper's own ordering) — deciding to state the relation is not enough if you state it backwards, and a reversed thesis is worse than none. *Why:* each item-answer can be correct yet the summary still omits the conclusion the paper leads with — or states that conclusion in the wrong direction.
- **Give every headline number its scope.** Write each key result with the conditions under which it holds: the method / definition / setting it is measured under, its population (all cases, or a named subset), and whether it is a bound / mean / median / quantile. *Why:* a scopeless number reads as a universal fact and drops the condition that is often the paper's actual point (e.g. that the result depends on which definition is used), or lets a subset average be misread as an all-cases average.
- **Preserve the authors' hedges; don't harden them into fact.** Keep author modality — "can / may / suggests / we believe" — and present a design argument or hypothesis as such, not as a measured result (items 3–5 especially). *Why:* the overview is the most-read layer, so a hedged or design-level claim asserted here as established fact misleads exactly the readers who never open the detail reports.
- **Key figure:** place the paper's single most explanatory figure — usually its Fig. 1 architecture/overview diagram, from `ocr/figures/` — right after the metadata block, with a one-line caption and its `[pNN]`.
- Items 1–2 (何を提案 / 新規性) point to `background.md`; items 3–6 each point to their own detail report — only for reports in Step 0 scope.
- Item 6 needs dblp-verified entries, which Phase 2 produces — leave it as `(Phase 2 完了後に確定)` for now and complete it at Finalize. If related-work is out of scope, instead pick 1–3 entries from the References section and verify them yourself with `bash <SKILL_DIR>/scripts/dblp_lookup.sh "<title> <first-author surname>"` before writing them (include the surname — title-only queries for generic titles miss the right paper).
- Close with **前提知識** and **原文の読み方** (both short), then the section map (it doubles as the outline pdf-studio-deep-dive resolves spans from).

## Phase 2 — Perspective detail reports (parallel)

Write one perspective detail report per in-scope perspective (background / method / experiments / discussion / related-work) by applying the **`paper-studio-paper-detail`** skill — it holds the per-perspective report templates and the strict bibliographic constraints. Run the perspectives **in parallel**:

- **Under Claude Code**, dispatch one `paper-studio-paper-detail` subagent per in-scope perspective (multiple Agent calls in one message) so each report is written in an isolated context and they run concurrently.
- **Otherwise**, apply the `paper-studio-paper-detail` skill inline, once per perspective, keeping each report's work self-contained.

Either way, provide each perspective run only the inputs below; the report structure and constraints come from the skill itself, not from the orchestrator:

- The perspective (`background` / `method` / `experiments` / `discussion` / `related-work`)
- The source — OCR ran: absolute path to `<WORK_DIR>/ocr/paper.md`; otherwise: the PDF absolute path plus the perspective's page span (from the section map, ±1 page margin; when in doubt, the span may generously cover the whole body — papers are short)
- The section map (compact, from Phase 1)
- **The assigned figure/table files** — from `<WORK_DIR>/ocr/figures/`, the files whose page falls in this perspective's span. Read each file's page from `<WORK_DIR>/ocr/figures.md` (the filename encodes the paper number, not the page). Every one must be explained. **Assign each figure to exactly one in-scope perspective** so none is duplicated or dropped: by its page → the perspective whose span contains it; when a page is shared, route by kind (teaser/motivating-example figures → background; architecture/overview/method figures → method; result plots/tables → experiments). Hold any figure whose page is covered *only* by an out-of-scope perspective for the overview (handled at Finalize).
- The output absolute path `<WORK_DIR>/reports/<perspective>.md`
- The report language
- For `background` additionally: the paper's thesis sentence from the overview's TL;DR (already written in Phase 1) — so background's stated conclusion stays consistent with the overview (same claim and direction) instead of being independently re-derived and diverging. The overview and each detail report are written independently and never reconciled afterward, so the thesis must be *handed down*, not rediscovered per report.
- For `related-work` additionally: the absolute path to `<SKILL_DIR>/scripts/dblp_lookup.sh` and the References `[pNN]` span

Perspective → relevant sections, when resolving spans: background → abstract + introduction + motivation/background sections; method → approach/method + preliminaries; experiments → experiments/evaluation + result appendices; discussion → discussion/limitations/conclusion; related-work → related work + introduction + references. (background and related-work both draw on the introduction — background from its motivation/problem framing, related-work from its cited prior work.)

**Context hygiene:** each perspective writes its report to a file and returns only a path + one-line status. Do not read the finished detail reports back into the orchestrator — the single exception is the "次に読むべき論文" section of `related-work.md`, needed at Finalize. (When dispatching to subagents this is automatic; when applying the skill inline, keep the same discipline — do not fold a full detail report back into the overview context.)

## Finalize

1. **Recover MinerU extraction failures — if `ocr/figures.md` has a "⚠ Not extracted" section.** Each row there is a figure/table MinerU located but could not crop (recognizer failed), so it is missing from `ocr/figures/`. Recover each one:
   - Render its page from the source PDF: `pdftoppm -f <N> -l <N> -singlefile -r 200 -png <pdf-path> <tmp>/pg` (N = the row's `[pNN]`; the PDF is the source, not yet collected — use its current path). View the PNG.
   - If a real figure/table is there, crop it (caption included) and save it to the row's **Intended file** path under `ocr/figures/`. Crop with `pdftoppm ... -x -y -W -H` in pixels: page size in pts comes from `pdfinfo`; pixel = pt × DPI ÷ 72. The `bbox (approx)` is a hint in MinerU's own space — if it doesn't line up, crop by eye from the full-page render (papers pages are mostly whitespace around a table). Re-render and re-view until the crop is clean and complete.
   - Then edit `ocr/figures.md`: delete the row from the "⚠ Not extracted" section and add a normal row (Label / File / Page / Caption) to the main table. The recovered file is now an assigned figure like any other (step 2 will require it be explained).
   - If the region is a MinerU phantom (no real figure/table), just delete the row and note it in the manifest.
2. **Figure/table coverage — guarantee no orphan.** List `<WORK_DIR>/ocr/figures/` (now including any recovered files). For each file, confirm at least one report under `reports/` references it by its relative path (grep the reports for the filename). Any figure not yet referenced by an in-scope report — because its page (look it up in `ocr/figures.md`) fell outside every in-scope span, or a perspective missed it — must be added, with a one-line explanation and its `[pNN]`, to a "図表" section: in the perspective report whose span contains its page if that report is in scope, otherwise in `overview.md`. After this step **every file in `ocr/figures/` is referenced-and-explained by exactly one report** (when scope is "overview only", they all land in overview's 図表 section).
3. **Complete overview item 6**: read only the "次に読むべき論文" section of `reports/related-work.md` and copy the top 1–3 entries (verified ones first) into `overview.md`, replacing the placeholder. Keep any "(dblp未確認)" markers.
4. **Collect the PDF**: if the user said yes in Step 0, move the source PDF into the work dir as `<WORK_DIR>/<slug>.pdf`, renaming it to match the dir. Otherwise leave the source at its original path and name (do not rename a file that stays outside the work dir). (Do this *after* step 1, which still needs the PDF at its pre-collection path — or just use whichever path the PDF is at.)
5. **Print a manifest**: the work dir path (the renamed slug dir), each report, and `ocr/` contents (OCR always runs via MinerU). Note any figures recovered or dropped in step 1.

## overview.md template

Fill every placeholder; body language follows the conversation. Drop pointer lines for out-of-scope reports.

```markdown
# <論文タイトル>

> **TL;DR**: <3 行以内。何を・どうやって・どれくらい効いたか。形容詞ではなく事実で。
>  複数の結果があるなら、論文自身がそれらの間に下す総合判断（優劣・非対称・トレードオフ）を1文で必ず含める — 個別数値の羅列で終わらせない。>

`タグ: <新手法 | 分析 | ベンチマーク/データセット | システム | サーベイ から該当するもの>`

| 項目 | 内容 |
| --- | --- |
| タイトル | <original title> |
| 著者 | <authors> |
| 会議/ジャーナル | <venue, or 不明 (preprint)> |
| 年 | <year> |
| DOI / URL | <as printed in the paper only> |

BibTeX: [`../paper.bib`](../paper.bib)

<!-- The paper's single most explanatory figure, from ocr/figures/ (named by paper number). -->
![key figure](../ocr/figures/fig-01.ext)
*Figure N ([pNN]): <one-line caption>*

## 1. 何を提案している?
<Include a one-sentence "X は Y する Z である" definition of the core, then briefly expand.>

## 2. 先行研究と比べて新規な部分は?
<"<a specific prior method named in the paper> では〜だったが、本研究は〜" contrast.
 Do not use an anonymous comparison target like "既存手法" / "従来研究".>

→ 詳細（背景・問題設定・提案の意義）: [background.md](background.md)

## 3. 技術・手法のキモは?
<Two paragraphs: (1) the intuition for *why it works*, no equations; (2) one technical paragraph.>

→ 詳細: [method.md](method.md)

## 4. 有効性の検証はどのように行った?
<Numbers required: up to three key results as "<baseline> 比 +N% on <benchmark>".
 Adjective-only claims ("大幅に改善") are not acceptable.
 Each number states its scope — the method/definition/setting it holds under, its population
 (all cases or a named subset), and whether it is a bound/mean/median/quantile — so a conditional
 or subset result is not read as a universal one.>

→ 詳細: [experiments.md](experiments.md)

## 5. 議論はある?
<Author-stated limitations and reader-inferred critique, kept clearly separate.
 著者のヘッジ（can/may/suggests・設計論証か実測か）を保存し、留保付き主張を確定事実として書かない。>

→ 詳細: [discussion.md](discussion.md)

## 6. 次に読むべき論文は?
- <title> — <筆頭著者> et al., <venue>, <year>. <URL または (dblp未確認)> — <relation to this paper>

→ 詳細: [related-work.md](related-work.md)

## 前提知識
<Up to five concepts needed to read this paper, one line each; "特になし" if none.>

## 原文の読み方
<Recommended reading path for a time-pressed reader, ≤3 lines.
 e.g. "Fig. 2 → §3.2 → Table 1 で骨子が掴める".>

## Section map
- [p01–p02] 1 Introduction
- ...
- [p09–p10] References
```

## Success criteria (verify the deliverable, not the steps)

- [ ] The work dir is named with the `{year}-{venue}-{short-title}` citation slug (lowercase `[a-z0-9-]`), and — if the user opted to collect the PDF — the PDF inside is `<slug>.pdf` matching the dir. (Exception: a name-collision the run reported, where the provisional name was kept.)
- [ ] `ocr/paper.md` exists with per-page `[pNN]` anchors (MinerU ran); every figure reference in the reports resolves as a relative path (`../ocr/figures/...` from `reports/`).
- [ ] `ocr/figures.md` exists and lists every file in `ocr/figures/` with its label, page (`[pNN]`), and caption; the figure files are named by paper number (`fig-NN` / `table-NN`). Its "⚠ Not extracted" section (if the converter wrote one) has been worked off at Finalize — every row either recovered into the main table (with the file now present in `ocr/figures/`) or dropped as a phantom and noted in the manifest.
- [ ] **Every file in `ocr/figures/` is referenced by at least one report and accompanied there by an explanation** (not embedded bare); no captured figure/table is left unexplained.
- [ ] `reports/overview.md` has the TL;DR + tag, the metadata block (no guessed venue/DOI), all six items filled, one key figure with a `[pNN]` caption, the 前提知識 and 原文の読み方 sections, pointer lines for every in-scope detail report, and a Section map whose `[pNN]` spans cover the whole body.
- [ ] The writing disciplines hold: item 1 has a one-sentence core definition; item 2 names concrete prior methods (no anonymous "既存手法"); item 4 gives numeric results, not adjectives only.
- [ ] The TL;DR (or a 総括 line) states the paper's own thesis — the overall verdict it leads with in the Abstract — and, when several results are reported, the relation the paper draws between them (superiority / asymmetry / trade-off), not just parallel numbers; that relation points the same direction as the source (not reversed).
- [ ] The overview's thesis and `background.md`'s stated conclusion agree — same claim and same direction — because background was handed the overview thesis as an input; the two do not contradict each other.
- [ ] Every headline number in the overview carries its scope: the method/definition/setting it holds under, its population (all cases or a named subset), and whether it is a bound/mean/median/quantile.
- [ ] Overview claims preserve author modality: hedged or design-level claims (can / may / suggests / we believe) are not asserted as measured fact.
- [ ] Every in-scope `reports/<perspective>.md` exists and carries `[pNN]` anchors.
- [ ] Every URL/DOI in `related-work.md` and overview item 6 traces to dblp output or the paper itself; unmatched entries carry "(dblp未確認)" and no URL.
- [ ] `<WORK_DIR>/paper.bib` exists with one BibTeX entry for the paper, either dblp-fetched or hand-built from printed metadata and marked `% not dblp-verified`; no venue/DOI/URL was invented, and overview links to it.
- [ ] A final manifest of all artifacts was shown to the user.

## Bundled scripts

- **`scripts/preflight.sh <command> [args…]`** — resolves the skill's runtime env once (python3 + poppler + uv), then execs the command inside it: PATH if present, else `nix develop` when a `flake.lock` is bundled and `nix` is available, else an aggregated fail listing both setup options (nix / manual). Launch `mineru_ocr.sh` through it (`preflight.sh bash …/mineru_ocr.sh <pdf> <ocr-dir>`). Does not touch `mineru` — that is checked in-env by the worker (in nix mode it only appears once the dev shell loads `~/.local/bin`). See [`docs/skill-runtime-and-dependencies.md`](../../../docs/skill-runtime-and-dependencies.md).
- **`scripts/mineru_ocr.sh <pdf> <ocr-dir>`** — reads the PDF **locally** with MinerU (`-b pipeline`, text mode for born-digital PDFs / OCR mode for scanned ones, chosen by probing the text layer) and materializes `ocr/paper.md`, `ocr/figures/` (figures/tables named by paper number `fig-NN` / `table-NN`), and `ocr/figures.md` (metadata index: label / file / page / caption, plus a "⚠ Not extracted" section for regions MinerU located but failed to crop) via `mineru_to_paper_md.py`. Launch it through `scripts/preflight.sh` (which supplies its python3 + poppler deps). Requires the `mineru` CLI (install with `uv tool install "mineru[core]"`; if missing it prints the setup command and exits non-zero — relay it and stop, do not install). First run downloads models. How the two scripts turn MinerU's layout skeleton + the PDF text layer into `paper.md` (and the fidelity trade-offs) is documented in [`docs/ocr-pipeline.md`](docs/ocr-pipeline.md).
- **`scripts/dblp_lookup.sh "<title> <first-author surname>"`** — queries the public dblp API and prints candidate records as JSON lines (`{key, type, title, authors, venue, year, doi, url}`). No key needed; empty output = no hit. Used by the orchestrator to build `paper.bib` (and to verify related-work when that report is out of scope), and by the `related-work` perspective (pass it the absolute path).
- **`scripts/dblp_bibtex.sh "<dblp-key>"`** — fetches the canonical BibTeX for a dblp record key (the `key` from `dblp_lookup.sh`), retrying dblp's transient 503s. Exits non-zero and prints nothing on failure so the caller falls back to a hand-built entry. No key needed.
