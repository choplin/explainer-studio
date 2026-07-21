# pdf-studio

Turn a large PDF (a book, manual, or long document) into a Markdown report — and, optionally, a NotebookLM-style audio guide and a phone-ready website — through a phased, worker-orchestrated pipeline, drilling back into any section on demand.

The core idea: separate **faithful extraction** from **interpretive synthesis**, and run the heavy phases in isolated contexts so the source pages and intermediate material never fill the orchestrator's context. That is what lets it scale to hundreds of pages while avoiding the page-boundary inconsistencies you get when a report is written directly from fixed page ranges.

## How it works

The pipeline compresses information in three phases, then recovers detail on demand:

```
extract  →  structure  →  report            (pdf-studio-summarize)
  │            │             │
  ▼            ▼             ▼
chunk-*.md   outline.md   reports/overview.md
                              │
                              ├─ ⟳  zoom back in  →  reports/<section>.md   (pdf-studio-deep-dive)
                              ├─ 🔊  report → dialogue/<slug>.txt → audio/<slug>.m4a
                              │      (pdf-studio-audio-dialogue → pdf-studio-audio-narrate)
                              └─ 🌐  reports/*.md + audio/*.m4a → site/ → Cloudflare Pages
                                     (pdf-studio-generate-site → pdf-studio-deploy-site)
```

- **Phase 1 — extract**: split the body into chunks, read each visually in parallel, write structured *material* (not a finished report) with `[pNN]` page anchors.
- **Phase 2 — structure**: a single pass stitches sections split across chunk boundaries, dedupes, and rebuilds the chapter → section hierarchy into `outline.md`.
- **Phase 3 — report**: the orchestrator turns the outline into a readable overview report inline (the outline is already compact enough to read directly).
- **Detail on demand**: because every artifact keeps `[pNN]` anchors, a later request resolves a section back to its source pages and re-reads them for a deeper, standalone report.

## Skills

### Orchestrators / user-facing

| Skill | Role |
|-------|------|
| `pdf-studio-full-guide` | End-to-end: runs the whole pipeline on one PDF in a single request — chains summarize → deep-dive (per chapter) → audio-dialogue → audio-narrate. Confirms scope once up front, then runs the phases. |
| `pdf-studio-summarize` | First full-document pass. Drives the `extract → structure → report` phases. |
| `pdf-studio-deep-dive` | Zoom-in counterpart. Resolves a requested section/page range via the outline's `[pNN]` anchors and writes a detailed standalone report for just that part. |
| `pdf-studio-audio-dialogue` | Audio guide, step 1. Rewrites any report Markdown into a NotebookLM-style two-host dialogue script (台本) under `dialogue/`. |
| `pdf-studio-audio-narrate` | Audio guide, step 2. Synthesizes a dialogue script into a compact AAC/m4a with a local VOICEVOX ENGINE (offline, no API key) + `ffmpeg`, two distinct Japanese voices. |
| `pdf-studio-generate-site` | Builds a reading-guide website under `site/` — pages are *authored* for the web (lede, key points, scannable sections), not converted 1:1 from Markdown — with in-page audio players. Build only. |
| `pdf-studio-initialize-site` | One-time hosting setup: a single Cloudflare Pages project + a local library, protected by a Cloudflare Access policy. Run once before the first deploy. |
| `pdf-studio-deploy-site` | Publishes a built `site/` by adding it as a subpath to the shared library, then deploying the whole library. |

### Internal (worker logic + shared resources)

| Skill | Role |
|-------|------|
| `pdf-studio-pdf-extract` | Phase 1 worker — one per chunk, in parallel. Read+Write only. |
| `pdf-studio-pdf-stitch` | Phase 2 worker — single instance. Read+Write+Glob. |
| `pdf-studio-pdf-detail` | Section drill-down worker (deep-dive / full-guide). |
| `pdf-studio-site-page` | Site page author — one per report, in parallel. |
| `pdf-studio-site-base` | Shared resources, delegated to by name (not invoked directly): the Cloudflare Pages library manager (`library.py`) and the pdf-studio content context layer (`pdf-studio.css`), layered on the `understanding-html-docs` base design system. The reading-site nav widgets are `understanding-html-docs`' `reading-nav` opt-in component (pulled in via `--component reading-nav`). |

The four worker skills carry their own constraints and output format, so the orchestrators only choose *when* and *with what inputs* to run them. Under Claude Code each is wrapped by a thin subagent (see `opts/claude/agents/pdf-studio-*`) so it runs in an isolated context and cannot install software or shell out to PDF converters; on any other agent the same skill is applied inline. This graceful fallback is written into each orchestrator.

## When skills activate

- **summarize**: "PDFをレポートにして", "この本を要約して", "turn this PDF into a markdown report"
- **deep-dive**: "第2章をもっと詳しく", "drill into chapter 2", "expand the section on X"
- **full-guide**: "この本を全部やって", "summaryから音声まで一気に", "do everything for this PDF"
- **audio-dialogue / audio-narrate**: "音声ガイドを作って", "台本を音声にして"
- **generate-site / deploy-site / initialize-site**: "サイトを作って", "この本を公開して", "配信の初期設定"

## Requirements

- **poppler** — the Read tool rasterizes PDF pages with `pdftoppm`. If reading fails with `pdftoppm failed:`, install it (macOS: `brew install poppler`; Debian/Ubuntu: `apt-get install poppler-utils`).
- **VOICEVOX ENGINE + `ffmpeg`** — an essential prerequisite for the audio guide only (`pdf-studio-audio-narrate`); local neural Japanese TTS (offline, no API key) + AAC encoding. Not needed for text reports.
- **`wrangler` + a Cloudflare account** — an essential prerequisite for publishing the website only (`initialize-site` / `deploy-site`). Free tier suffices.

## Work directory layout

Everything lands in one work dir named after the PDF's basename; the source PDF is collected inside it as the final step (on confirmation):

```
/path/to/book/               # work dir (named after the PDF basename)
├── book.pdf                 # source PDF, collected in after Phase 3 (on confirmation)
├── extract/                 # summarize · Phase 1: structured extraction material ([pNN] anchors)
│   └── chunk-030-049.md
├── structured/
│   └── outline.md           # summarize · Phase 2: stitched, deduped outline (## Page offset field)
├── reports/
│   ├── overview.md          # summarize · Phase 3: overview report
│   └── chapter-2.md         # deep-dive: on-demand section deep dive
├── dialogue/                # audio-dialogue: two-host dialogue script (台本, editable)
├── audio/                   # audio-narrate: synthesized audio (disposable, re-generatable)
└── site/                    # generate-site: authored website (disposable, rebuilt on re-run)
```

## Notes

- `[pNN]` anchors are always **PDF** page numbers. The printed-page ↔ PDF-page offset is recorded once in the outline's `## Page offset` field so section drill-down can convert printed page numbers.
- Report content is written in the language of the source PDF (or the conversation); the skills' own instructions and structural field names are in English.
- For academic papers (conference/journal/preprint), use `paper-studio-summarize` instead — it produces an Ochiai-format overview and dblp-verified bibliography. paper-studio shares this work-dir layout, so these audio/site/deep-dive skills work on paper artifacts unchanged.
