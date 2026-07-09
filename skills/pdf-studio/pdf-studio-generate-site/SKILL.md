---
name: pdf-studio-generate-site
description: This skill should be used when the user wants pdf-studio reports turned into a real website — authored web pages (not converted Markdown) browsable from a smartphone, built as a static site under a work dir's site/ from its reports/, with the audio/ guides playable in-page. Triggers on "レポートをWebサイトにして", "HTMLにして", "サイトを作って", "スマホで読めるようにして", "generate a site from the reports", "make a website from the reports". Should NOT trigger for deploying/hosting the built site (use pdf-studio-deploy-site), for producing the reports (use pdf-studio-summarize / pdf-studio-deep-dive), or for the audio guide (use pdf-studio-audio-dialogue / pdf-studio-audio-narrate).
version: 0.5.0
user-invocable: true
---

# Generate Site — reports as an authored website

Turn a pdf-studio work dir into a **reading-guide website** under `<WORK_DIR>/site/`: a landing page with chapter cards, and one authored page per report with the matching audio guide playable in-page. This skill only *builds* the site; putting it on the internet is [[pdf-studio-deploy-site]]'s job — keeping the two apart lets the generated site be reviewed before it goes public.

The pages are **authored, not converted**: the `pdf-studio-site-page` procedure rewrites each report for web reading (lede, key-points box, scannable sections) against a bundled design system. Rendering the Markdown 1:1 into HTML is explicitly NOT the deliverable. The output is a **no-server static site** (openable by double-click, no build step) that bundles its design system locally (`assets/base.js` from understanding-html-docs: reading-progress bar, table of contents with scroll-spy, light/dark theme toggle, back-to-top; plus `assets/pdf-studio.js`: the index filter) as progressive enhancement, so every page stays fully readable if JS is disabled. Bundling the substrate is for **portability and durability** (the artifact doesn't rot on external dependencies), **not** a ban on external references: a page may pull in web fonts, remote images, report-embedded links, or heavy third-party libraries (a diff renderer, a diagram engine) from a CDN where it needs them — exactly as [[understanding-html-docs]] allows for the context layer.

The design system is layered: the **base substrate** (`base.css` / `base.js`) is owned by the **[[understanding-html-docs]]** skill — pdf-studio consumes it as a copy-mode base — and the **pdf-studio context layer** (`pdf-studio.css` / `pdf-studio.js`) is owned by **`pdf-studio-site-base`** (the library index uses the same two layers). This skill's own `assets/` holds only the templates `page.html` and `index.html`. If either `understanding-html-docs` or `pdf-studio-site-base` is not installed, stop and say so rather than guessing an asset path.

## When this applies

The input is a pdf-studio work dir (`<dir>/<name>/`) with at least one report under `reports/`. `audio/` is optional — pages without audio simply get no player. If no report exists yet, run [[pdf-studio-summarize]] first; for audio on the pages, run [[pdf-studio-audio-dialogue]] → [[pdf-studio-audio-narrate]] first.

## Phase 1 — Scaffold

1. Inventory `reports/*.md` and `audio/*` (`.m4a`, also `.mp3`/`.wav` for hand-added files). Fix the page order now: `overview` first, the rest naturally sorted (`chapter-2` before `chapter-10`) — prev/next links depend on this order. Assign each page a **chapter hue** by its position in that order, cycling `hue-1`..`hue-6` (position 1 → `hue-1`, … 7 → `hue-1` again). The same hue is used for the page and for its index card, so color = chapter identity across the whole site.
2. **Clear any existing `site/` first** (`rm -rf <WORK_DIR>/site`), then create `<WORK_DIR>/site/assets/` and `site/audio/`. This makes every run a clean rebuild: reports, audio, or assets no longer produced (renamed/removed chapters, stale narration, old asset files) leave no orphan behind — which matters because a later [[pdf-studio-deploy-site]] run publishes whatever is on disk. The clear is safe because everything under `site/` is reproducible from `reports/` and `audio/`; hand-added audio lives in the **source** `audio/` (not `site/`), so it is never touched. Then copy the **four asset files** into `site/assets/` — the base substrate `understanding-html-docs/assets/base.css` and `.../base.js`, and the pdf-studio context layer `pdf-studio-site-base/assets/pdf-studio.css` and `.../pdf-studio.js` — plus the audio files into `site/audio/`. Copy each verbatim; never edit them per site. `site/` is disposable — regenerating clears and rebuilds it; never hand-edit it (edit `reports/` and regenerate instead).

## Phase 2 — Author pages (parallel)

Author one page per report by applying the **`pdf-studio-site-page`** procedure (its restructuring rules and class catalog live in that skill). Run the reports **in parallel**:

- **Under Claude Code**, dispatch one `pdf-studio-site-page` subagent per report (multiple Agent calls in one message) so each page is authored in an isolated context and they run concurrently.
- **Otherwise**, apply the `pdf-studio-site-page` skill once per report.

Pass only the per-page inputs, all absolute paths:

- source report path; template path (`pdf-studio-generate-site/assets/page.html`); output path `site/<slug>.html`
- site title; kicker label (第N章 / 全体レポート)
- the page's chapter hue class (`hue-1`..`hue-6`) from Phase 1
- matching audio file name under `site/audio/` (or "none")
- prev/next hrefs + labels from the Phase 1 order (or "none" at the ends)

Each returns only the output path, the page title, and a 2–3 line card summary. Do not read the finished pages back — trust the replies. (Optionally estimate reading time from the report's length — e.g. `wc -m` (character count, not `wc -w`: Japanese isn't space-delimited so word counts are meaningless) at ~500 Japanese chars/min — to put a ⏱ chip on the card in Phase 3.)

## Phase 3 — Landing page (orchestrator, inline)

Write `site/index.html` from `pdf-studio-generate-site/assets/index.html`: hero (site title = the book title, a 2–3 sentence lede composed from the overview card summary, chapter/audio count chips, CTA to `overview.html`), then one card per page in order — kicker, returned title, returned summary. Give each card the **same `hue-N` class** its page uses so card color matches the chapter, and a ⏱ reading-time chip and a 🔊 chip when they apply. Audio files with no matching report get inline players under 音声ガイド. Then verify (see Success criteria).

## Hand off to deployment

After building `site/`, tell the user the site is ready under `<WORK_DIR>/site/` and that [[pdf-studio-deploy-site]] can put it on the internet (as a subpath of the shared Cloudflare Pages library, Access-protected) — or offer to run it. If nothing has been deployed before, the one-time [[pdf-studio-initialize-site]] setup must run first. Do not deploy here: the split lets the user review the generated site before it goes public.

## Gotchas

- **Restructuring is the deliverable.** A page whose heading sequence mirrors the source Markdown is a conversion, not an authored page — re-author it with the instruction to restructure (the `pdf-studio-site-page` procedure states the same rule).
- **`site/` is disposable and rebuilt from scratch.** Each run clears `site/` and regenerates, so files no longer produced (renamed/removed chapters, stale audio, superseded assets) don't linger as orphans; never hand-edit `site/` — edit the source `reports/` and regenerate. A later [[pdf-studio-deploy-site]] run publishes whatever is on disk, so a stale overwrite-only build would leak orphans — regenerate (clean) before redeploying.

## Success criteria

- [ ] Every `reports/*.md` has a `site/<slug>.html`, and `index.html` has a card for each with a composed (not copied) summary; `overview` is the hero CTA.
- [ ] Each page carries a `lede` and a `keypoints` box, and no unrendered Markdown artifacts (verify: `grep -n '\*\*\|^#\{1,3\} ' site/*.html` → only hits inside `<pre>` blocks, if any).
- [ ] Every page `<body>` has a `hue-N` class and its index card carries the same `hue-N` (color = chapter identity); callout variants, if used, match their meaning.
- [ ] Reports with a matching audio slug have an in-page `<audio>` player; unmatched audio is listed on the index; every referenced audio file exists in `site/audio/`.
- [ ] The design system is bundled locally: all four of `site/assets/base.css`, `site/assets/base.js`, `site/assets/pdf-studio.css`, `site/assets/pdf-studio.js` exist, and every page's `<head>` keeps the theme-boot inline script (key `html-docs-theme`) and the `assets/base.js` + `assets/pdf-studio.js` references. (External references — web fonts, CDN libraries, remote images, report-embedded links — are allowed where a page needs them; they are not checked.)
- [ ] The user was told the site is built under `<WORK_DIR>/site/` and pointed to [[pdf-studio-deploy-site]] for putting it online.
