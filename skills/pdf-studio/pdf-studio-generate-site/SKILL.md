---
name: pdf-studio-generate-site
description: This skill should be used when the user wants pdf-studio reports turned into a real website — authored web pages (not converted Markdown) browsable from a smartphone, built as a static site under a work dir's site/ from its reports/, with the audio/ guides playable in-page. Triggers on "レポートをWebサイトにして", "HTMLにして", "サイトを作って", "スマホで読めるようにして", "generate a site from the reports", "make a website from the reports". Should NOT trigger for deploying/hosting the built site (use pdf-studio-deploy-site), for producing the reports (use pdf-studio-summarize / pdf-studio-deep-dive), or for the audio guide (use pdf-studio-audio-dialogue / pdf-studio-audio-narrate).
user-invocable: true
---

# Generate Site — reports as an authored website

Turn a pdf-studio work dir into a **reading-guide website** under `<WORK_DIR>/site/`: a landing page with chapter cards, and one authored page per report with the matching audio guide playable in-page. This skill only *builds* the site; putting it on the internet is [[pdf-studio-deploy-site]]'s job — keeping the two apart lets the generated site be reviewed before it goes public.

The pages are **authored, not converted**: the `pdf-studio-site-page` procedure rewrites each report for web reading (lede, key-points box, scannable sections) against a bundled design system. Rendering the Markdown 1:1 into HTML is explicitly NOT the deliverable. The output is a **no-server static site** (openable by double-click, no build step) that bundles its design system locally (`assets/base.js` from understanding-html-docs: reading-progress bar, table of contents with scroll-spy, light/dark theme toggle, back-to-top; plus `assets/pdf-studio.js`: the index filter) as progressive enhancement, so every page stays fully readable if JS is disabled. Bundling the substrate is for **portability and durability** (the artifact doesn't rot on external dependencies), **not** a ban on external references: a page may pull in web fonts, remote images, report-embedded links, or heavy third-party libraries (a diff renderer, a diagram engine) from a CDN where it needs them — exactly as [[understanding-html-docs]] allows for the context layer.

The design system is layered: the **base substrate** (`base.css` / `base.js`) is owned by the **[[understanding-html-docs]]** skill — pdf-studio consumes it as a copy-mode base — and the **pdf-studio context layer** (`pdf-studio.css` / `pdf-studio.js`) is owned by **`pdf-studio-site-base`** (the library index uses the same two layers). This skill's own `assets/` holds only the templates `page.html` and `index.html`. If either `understanding-html-docs` or `pdf-studio-site-base` is not installed, stop and say so rather than guessing an asset path.

## When this applies

The input is a pdf-studio work dir (`<dir>/<name>/`) with at least one report under `reports/`. `audio/` is optional — pages without audio simply get no player. If no report exists yet, run [[pdf-studio-summarize]] first; for audio on the pages, run [[pdf-studio-audio-dialogue]] → [[pdf-studio-audio-narrate]] first.

## Phase 1 — Scaffold

1. Inventory `reports/*.md`, `audio/*` (`.m4a`, also `.mp3`/`.wav` for hand-added files), and `ocr/figures/*` if the figure harvest ran. Fix the page order now: `overview` first, the rest naturally sorted (`chapter-2` before `chapter-10`) — this order is the **single source of truth for the page navigation** (the `nav-manifest.js` written in Phase 3, from which prev/next and the page list are rendered at runtime). Chapters are **not** color-coded: color carries meaning in this design system, so a per-chapter hue would collide with it (a reader cannot tell "chapter 5 red" from "hazard red"). Which chapter you are in is answered by the nav, the title, and the index — not by a color.
2. **If `<WORK_DIR>/site/` already exists, ask the user before clearing it** (no prompt is needed when it doesn't exist yet). A clean rebuild (recommended) does `rm -rf <WORK_DIR>/site` first so that anything no longer produced (renamed/removed chapters, stale narration, superseded assets) leaves no orphan behind — which matters because a later [[pdf-studio-deploy-site]] run publishes whatever is on disk. If the user declines, build over the existing tree instead and warn that orphaned files may remain and would be published on the next deploy. Clearing is safe: everything under `site/` is reproducible from `reports/`, `audio/`, and `ocr/figures/`, and hand-added audio lives in the **source** `audio/` (not `site/`), so it is never touched. Then create `<WORK_DIR>/site/assets/` and `site/audio/` and copy the **four asset files** into `site/assets/` — the base substrate `understanding-html-docs/assets/base.css` and `.../base.js`, and the pdf-studio context layer `pdf-studio-site-base/assets/pdf-studio.css` and `.../pdf-studio.js` — plus the audio files into `site/audio/`. Copy each verbatim; never edit them per site. `site/` is disposable — never hand-edit it (edit `reports/` and regenerate instead).
3. **Copy the figures into the site** — if `<WORK_DIR>/ocr/figures/` exists, copy it **whole** to `site/figures/` (`cp -R <WORK_DIR>/ocr/figures site/figures`). Copy every crop, not only the ones the reports embed: the pages are authored in parallel by workers that each see one report, so at this point nobody knows the union of referenced figures; a handful of unreferenced crops is harmless (Pages allows 25 MiB per file and 20,000 files). **This is what makes the site self-contained.** The reports embed figures as `../ocr/figures/…` (a path relative to `reports/`, correct for reading the Markdown); a page that keeps that path resolves *outside* `site/`, which still renders locally but 404s the moment [[pdf-studio-deploy-site]] publishes `site/` alone. `pdf-studio-site-page` rewrites the path to `figures/…` — this step is what puts a file there for it to point at.

## Phase 2 — Author pages (parallel)

Author one page per report by applying the **`pdf-studio-site-page`** procedure (its restructuring rules and class catalog live in that skill). Run the reports **in parallel**:

- **Under Claude Code**, dispatch one `pdf-studio-site-page` subagent per report (multiple Agent calls in one message) so each page is authored in an isolated context and they run concurrently.
- **Otherwise**, apply the `pdf-studio-site-page` skill once per report.

Pass only the per-page inputs, all absolute paths:

- source report path; template path (`pdf-studio-generate-site/assets/page.html`); output path `site/<slug>.html`
- site title; kicker label (第N章 / 全体レポート)
- whether `site/figures/` exists (from Phase 1 step 3), so the worker knows the report's `../ocr/figures/X` references are rewritten to `figures/X` — the site must not reference anything outside `site/`
- matching audio file name under `site/audio/` (or "none")

The worker does **not** author prev/next links: page-to-page navigation is rendered at runtime by `pdf-studio.js` from the `nav-manifest.js` you write in Phase 3, so there is one source for the page order instead of neighbor links copied into every page. Each returns only the output path, the page title, and a 2–3 line card summary. Do not read the finished pages back — trust the replies. (Optionally estimate reading time from the report's length — e.g. `wc -m` (character count, not `wc -w`: Japanese isn't space-delimited so word counts are meaningless) at ~500 Japanese chars/min — to put a ⏱ chip on the card in Phase 3.)

## Phase 3 — Landing page (orchestrator, inline)

Write `site/index.html` from `pdf-studio-generate-site/assets/index.html`: hero (site title = the book title, a 2–3 sentence lede composed from the overview card summary, chapter/audio count chips, CTA to `overview.html`), then one card per page in order — kicker, returned title, returned summary. Give each card a ⏱ reading-time chip and a 🔊 chip when they apply. Audio files with no matching report get inline players under 音声ガイド.

**Then write `site/nav-manifest.js`** — the single source of truth for page-to-page navigation, from the fixed Phase 1 order. Every page loads it (a `<script src="nav-manifest.js">` line already in both templates), and `pdf-studio.js` reads `window.__PDF_STUDIO_NAV` to render prev/next and highlight the current page. It is the whole reason no page carries hand-authored neighbor links: to add or remove a page you regenerate **only this one file**, not every page's markup. Emit one entry per report page in reading order (the same order as the cards; the landing page is not an entry — it is home, reached via each page's `← SITE_TITLE` header link):

```js
/* pdf-studio page navigation manifest — generated. Single source of truth for this
   site's page list; regenerate THIS FILE ONLY when pages are added or removed. */
window.__PDF_STUDIO_NAV = {
  "pages": [
    { "slug": "overview",  "href": "overview.html",  "kicker": "全体レポート", "title": "RETURNED_TITLE" },
    { "slug": "chapter-1", "href": "chapter-1.html", "kicker": "第1章",     "title": "RETURNED_TITLE" }
  ]
};
```

`slug` = the page basename without `.html`; `href` = `<slug>.html`; `kicker` = the same kicker label passed to that page in Phase 2 (第N章 / 全体レポート); `title` = the title the Phase 2 worker returned. It must be valid JavaScript — quote strings as JSON (the assignment is plain data, no logic). Then verify (see Success criteria).

## Phase 4 — Review the generated pages

The pages were authored by an agent against a written contract, and a contract violation here **does not break the page** — a callout whose variant contradicts its own text renders as a perfectly good box in the wrong color, and nobody notices. So read them back: apply **[[understanding-html-docs-review]]** to every page under `site/` (including `index.html`).

- **Under Claude Code**, dispatch one `understanding-html-docs-reviewer` subagent per page (multiple Agent calls in one message) so each review runs concurrently in a **fresh context**. This matters: the agent that authored a page cannot read it independently of having just written it.
- **Otherwise**, apply the `understanding-html-docs-review` skill once per page.

Fix what comes back (the review reports; it does not edit), then re-check. Report to the user what was found and fixed — a review whose findings are never surfaced is indistinguishable from one that never ran.

## Hand off to deployment

After building `site/`, tell the user the site is ready under `<WORK_DIR>/site/` and that [[pdf-studio-deploy-site]] can put it on the internet (as a subpath of the shared Cloudflare Pages library, Access-protected) — or offer to run it. If nothing has been deployed before, the one-time [[pdf-studio-initialize-site]] setup must run first. Do not deploy here: the split lets the user review the generated site before it goes public.

## Gotchas

- **A figure kept at the report's `../ocr/figures/…` path breaks only after deploy.** From `site/<slug>.html` that path still resolves (to the work dir one level up), so the page looks right in a local browser and the failure is invisible until [[pdf-studio-deploy-site]] publishes `site/` on its own and every figure 404s. Never trust the local render on this — run the `grep -n '\.\./' site/*.html` check in the Success criteria.
- **Restructuring is the deliverable.** A page whose heading sequence mirrors the source Markdown is a conversion, not an authored page — re-author it with the instruction to restructure (the `pdf-studio-site-page` procedure states the same rule).
- **`site/` is disposable and rebuilt from source.** When `site/` already exists the skill asks before clearing it; a clean rebuild (recommended) drops files no longer produced (renamed/removed chapters, stale audio, superseded assets) so they don't linger as orphans. Never hand-edit `site/` — edit the source `reports/` and regenerate. A later [[pdf-studio-deploy-site]] run publishes whatever is on disk, so an overwrite-only rebuild can leak orphans — prefer a clean rebuild before redeploying.

## Success criteria

- [ ] Every `reports/*.md` has a `site/<slug>.html`, and `index.html` has a card for each with a composed (not copied) summary; `overview` is the hero CTA.
- [ ] Each page carries a `lede` and a `keypoints` box, and no unrendered Markdown artifacts (verify: `grep -n '\*\*\|^#\{1,3\} ' site/*.html` → only hits inside `<pre>` blocks, if any).
- [ ] Every page was reviewed with [[understanding-html-docs-review]], its findings were fixed, and the user was told what they were.
- [ ] **`site/` is self-contained — nothing points outside it.** Verify: `grep -n '\.\./' site/*.html` → no hits (a `../` in a `src`/`href` escapes `site/` and 404s once deployed), and every `<img src>` resolves to a file that exists under `site/`. This is the check that catches a figure left at `../ocr/figures/…`: such a page renders perfectly in a local browser (the work dir is still one level up) and only breaks after [[pdf-studio-deploy-site]] publishes `site/` alone — so it cannot be caught by looking at the page.
- [ ] Reports with a matching audio slug have an in-page `<audio>` player; unmatched audio is listed on the index; every referenced audio file exists in `site/audio/`.
- [ ] The design system is bundled locally: all four of `site/assets/base.css`, `site/assets/base.js`, `site/assets/pdf-studio.css`, `site/assets/pdf-studio.js` exist, and every page's `<head>` keeps the theme-boot inline script (key `html-docs-theme`) and the `assets/base.js`, `nav-manifest.js`, and `assets/pdf-studio.js` references in that order (the manifest must load before `pdf-studio.js` reads it). (External references — web fonts, CDN libraries, remote images, report-embedded links — are allowed where a page needs them; they are not checked.)
- [ ] **Page navigation has a single source.** `site/nav-manifest.js` exists, assigns `window.__PDF_STUDIO_NAV` with one `pages` entry per report page in reading order, and is valid JS (loads without a console error). No page hand-authors a `<nav class="chapnav">` (verify: `grep -n 'class="chapnav"' site/*.html` → no hits; prev/next is rendered at runtime). Opening a middle page shows working ← prev / next → links; the first page has no prev and the last has no next.
- [ ] The user was told the site is built under `<WORK_DIR>/site/` and pointed to [[pdf-studio-deploy-site]] for putting it online.
