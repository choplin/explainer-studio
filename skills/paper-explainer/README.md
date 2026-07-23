# paper-explainer

Digest an **academic paper PDF** (a conference/journal paper or preprint, typically 8–30 pages, mainly CS) into an Ochiai-format overview plus per-perspective detail reports — capturing the paper's novelty, usefulness, and validation explicitly.

The sibling of [`pdf-explainer`](../pdf-explainer): where pdf-explainer scales a **book** through a heavy extract→structure→report pipeline, paper-explainer runs a light two-phase pipeline tuned for short papers — and shares pdf-explainer's work-dir conventions so its audio and site skills work on paper artifacts unchanged.

## How it works

```
Phase 1 (orchestrator, inline)          Phase 2 (paper-detail, parallel)     Finalize
read the paper via local MinerU OCR  →  reports/background.md   背景・問題  →  consistency & faithfulness
biblio metadata + section map [pNN]     reports/method.md       手法             sweep over the whole set
write spine.md (confirmed facts)        reports/experiments.md  実験             (paper-explainer-consistency-
write reports/overview.md               reports/discussion.md   議論             sweep) → targeted fixes
  (spine handed to every perspective)   reports/related-work.md 位置づけ+次読
                                          (dblp-verified bibliography)
```

- **Phase 1** — the orchestrator reads the paper itself (papers fit in context; no extract/stitch workers needed), captures bibliographic metadata and the section structure with `[pNN]` page anchors, materializes `spine.md` (the paper's confirmed facts — thesis + direction, running-example map, headline numbers with scope, figure-verified facts), and writes `reports/overview.md` in the Ochiai format: six questions — what is proposed / what is novel / what is the technical core / how was it validated / what is discussed / what to read next — each linking into its detail report.
- **Phase 2** — one perspective report per in-scope perspective, **in parallel**, re-reading just the relevant sections (from the OCR Markdown) and writing a standalone detail report. Each perspective is handed `spine.md` and takes the shared facts from it rather than re-deriving them, so the isolated reports do not diverge.
- **Finalize** — a single consistency & faithfulness sweep reads the **whole report set at once** (the one thing the isolated per-report passes structurally cannot do) and checks it for (1) cross-report contradictions and (2) faithfulness to the source's logical structure, verifying against `spine.md` and the paper. Its findings drive targeted, source-anchored fixes (a bounded loop, not full regeneration). Under Claude Code the sweep runs in an isolated subagent so only its findings return to the orchestrator.
- Scope is confirmed **once up front** (which detail reports to produce — default all five), then the pipeline runs without further prompts.

### MinerU OCR (mandatory, local)

The paper is read through a **local MinerU OCR** run (`mineru_ocr.sh`) — it runs entirely on the machine (nothing is uploaded, so it is safe for under-review or confidential manuscripts). This is a hard requirement with **no fallback**: if `mineru` is not installed, the skill stops at the prerequisites check and prints the install command (`uv tool install "mineru[core]"`) rather than reading the PDF another way. The first run downloads model weights (several GB).

OCR materializes `ocr/paper.md` (full text as Markdown with LaTeX math, one `[pNN]` anchor per page), extracts every figure/table to `ocr/figures/` named by its paper reference number (`fig-NN.<ext>` / `table-NN.<ext>`), and writes `ocr/figures.md` (a label / file / page / caption index). Regions MinerU locates but cannot crop are surfaced in a "⚠ Not extracted" section for the Finalize recovery step.

### dblp-verified bibliography

"Papers to read next" are chosen **only from entries that actually appear in the paper's References section**, and their bibliography (authors, venue, year, DOI/URL) is verified against the public [dblp API](https://dblp.org/) via bundled curl+jq scripts before being written. No dblp match → the entry is marked `(dblp未確認)` and carries no URL. Writing citation URLs from model memory is prohibited — hallucinated-but-plausible citations are worse than an honest "unverified".

## Skills

| Skill | Role |
|-------|------|
| `paper-explainer-summarize` | The summary pipeline: scope confirmation → Phase 1 (inline OCR read + spine + overview) → Phase 2 (parallel perspective reports) → Finalize (consistency sweep + fixes). Triggers on "この論文をまとめて", "落合フォーマットで読んで", "summarize this paper". |
| `paper-explainer-generate-site` | Build a browsable **website** from the reports — a landing page plus one authored (restructured, not converted) page per report, ordered by perspective (overview → 背景 → 手法 → 実験 → 議論 → 関連研究) with the overview audio playable in-page. The paper-tuned sibling of `pdf-explainer-generate-site`; reuses pdf-explainer's site worker/assets and differs only in report order and kicker labels. Triggers on "論文レポートをWebサイトにして", "HTMLにして". |
| `paper-explainer-full-guide` | Run the **whole chain end-to-end** on one paper: summary + perspective reports → overview audio guide → website, confirmed once up front. Triggers on "この論文を全部やって", "サマリから音声・サイトまで一気に". |
| `paper-explainer-paper-detail` | Internal Phase 2 logic: writes ONE perspective detail report (background / method / experiments / discussion / related-work), taking shared facts from `spine.md`. Applied once per perspective; not invoked directly. |
| `paper-explainer-consistency-sweep` | Internal Finalize logic: reads the whole report set + `spine.md` + the source, returns a findings list of cross-report contradictions and source-faithfulness / logical-structure drift (it never edits reports). Applied once at Finalize; not invoked directly. |

The **audio** guide reuses pdf-explainer's fully generic audio skills unchanged (there is no paper-specific audio skill): `explainer-audio-dialogue` writes a two-speaker script from `reports/overview.md`, and `explainer-audio-narrate` synthesizes it to `audio/overview.m4a` via a local VOICEVOX ENGINE. paper-explainer's audio is overview-only by design — the perspective detail reports are for reading, not listening.

The per-perspective report templates and the strict bibliographic constraints live in `paper-explainer-paper-detail`; the whole-set check criteria live in `paper-explainer-consistency-sweep`. The orchestrator passes each only its inputs. Under Claude Code each is wrapped by a thin subagent (`agents/paper-explainer-paper-detail` for the parallel perspective writers, `agents/paper-explainer-consistency-sweep` for the Finalize sweep) so it runs in an isolated context; on any other agent the same skill is applied inline. This graceful fallback is written into the orchestrator.

### Bundled scripts (in `paper-explainer-summarize/scripts/`)

| Script | Purpose |
|--------|---------|
| `mineru_ocr.sh <pdf> <ocr-dir>` | OCR the PDF **locally** with MinerU; materialize `ocr/paper.md`, `ocr/figures/`, `ocr/figures.md` (via `mineru_to_paper_md.py`). |
| `dblp_lookup.sh "<title> <surname>"` | Query the public dblp API; print candidate records as JSON lines. No API key. |
| `dblp_bibtex.sh "<dblp-key>"` | Fetch the canonical BibTeX for a dblp record key. |

## Requirements

- **MinerU** (`uv tool install "mineru[core]"`) — the mandatory OCR engine; the skill stops if it is missing (no fallback reader). First run downloads model weights.
- **poppler** — `pdfinfo` for the page-count pre-check and `pdftoppm` for Finalize figure recovery (macOS: `brew install poppler`; Debian/Ubuntu: `apt-get install poppler-utils`).
- **curl + jq** — for the dblp verification scripts.

## Work directory layout

The work dir is named with a `{year}-{venue}-{short-title}` citation slug (e.g. `2017-neurips-attention-is-all-you-need/`):

```
<slug>/                        # work dir (citation slug)
├── <slug>.pdf                 # source PDF, collected in at the end (on confirmation)
├── paper.bib                  # dblp canonical BibTeX (or printed-metadata fallback)
├── spine.md                   # Phase 1 confirmed facts — shared source for perspectives + sweep oracle
├── ocr/                       # MinerU OCR output (always produced)
│   ├── paper.md               # full text as Markdown (LaTeX math), [pNN] anchors
│   ├── figures.md             # metadata index: label / file / page / caption
│   └── figures/fig-03.jpg     # figures & tables, named by paper number
└── reports/
    ├── overview.md            # Ochiai-format overview + section map
    ├── background.md          # 背景と問題設定（動機・提案の意義）
    ├── method.md              # 技術・手法の詳細
    ├── experiments.md         # 実験設定と結果
    ├── discussion.md          # 議論・限界・今後
    └── related-work.md        # 位置づけ + 次に読むべき論文 (dblp-verified)
```

### Interop with pdf-explainer

The layout matches pdf-explainer's work-dir conventions (`reports/*.md`, `[pNN]` anchors), so with pdf-explainer installed the pipeline extends into audio and a website:

- **Audio guide** — `explainer-audio-dialogue` (pointed at `overview.md`) → `explainer-audio-narrate`. These pdf-explainer skills are fully source-generic and run unchanged; paper-explainer narrates the overview only.
- **Website** — `paper-explainer-generate-site` (in this group) builds the site with the correct perspective order and kicker labels; the shared site worker (`explainer-reading-site-page`), context assets (`explainer-reading-site-library-base`), and hosting (`explainer-reading-site-deploy`) are reused from pdf-explainer. (Running `pdf-explainer-generate-site` directly also *works*, but mislabels the pages as 第N章 — use the paper-explainer one.)
- **End-to-end** — `paper-explainer-full-guide` chains summary → overview audio → website in one request.

## Notes

- `[pNN]` anchors are always **PDF** page numbers (camera-ready papers often print journal page numbers like 1234–1245; those are ignored).
- Long documents (dissertations, books, anything over ~30 pages) are out of scope by design — use `pdf-explainer-summarize` for those.
- Report content is written in the language of the conversation (or as requested); the skills' own instructions and structural field names are in English, except the Ochiai-format headings, which are canonical in Japanese.
