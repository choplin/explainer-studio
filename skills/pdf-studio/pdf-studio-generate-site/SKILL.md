---
name: pdf-studio-generate-site
description: This skill should be used when the user wants pdf-studio reports turned into a real website — authored web pages (not converted Markdown) browsable from a smartphone, built as a static site under a work dir's site/ from its reports/, with the audio/ guides playable in-page. Triggers on "レポートをWebサイトにして", "HTMLにして", "サイトを作って", "スマホで読めるようにして", "generate a site from the reports", "make a website from the reports". Should NOT trigger for deploying/hosting the built site (use pdf-studio-deploy-site), for producing the reports (use pdf-studio-summarize / pdf-studio-deep-dive), or for the audio guide (use pdf-studio-audio-dialogue / pdf-studio-audio-narrate).
user-invocable: true
---

# Generate Site — reports as an authored website

Turn a pdf-studio work dir into a **reading-guide website** under `<WORK_DIR>/site/`: a landing page with chapter cards, and one authored page per report with the matching audio guide playable in-page. This skill only *builds* the site; putting it on the internet is [[pdf-studio-deploy-site]]'s job — keeping the two apart lets the generated site be reviewed before it goes public.

The pages are **authored, not converted** — and authored as a **semantic IR**, not hand-written HTML. The `pdf-studio-site-page` procedure rewrites each report for web reading (lede, key-points box, scannable sections) as Markdown + fenced divs that name only *meaning*; the [[understanding-html-docs]] generator then binds that IR to the markup deterministically. Rendering the Markdown 1:1 into HTML is explicitly NOT the deliverable. What the generator guarantees, so the authoring worker cannot get it wrong: the `<head>`/theme-boot/asset order is always correct, an invented class or inline style is unrepresentable, an unknown callout variant is a hard build error, every table is wrapped in `.tablewrap`, and figure paths are rewritten to point inside the site root. What stays a reading judgment (is this passage a hazard or the key point) lives in the IR and is the author's call, guided by the `pdf-studio-site-page` rules.

The output is a **no-server static site** (openable by double-click, no build step) that bundles its design system locally (`assets/base.js` from understanding-html-docs: reading-progress bar, table of contents with scroll-spy, light/dark theme toggle, back-to-top; plus `assets/pdf-studio.js`: the index filter and runtime page nav) as progressive enhancement, so every page stays fully readable if JS is disabled. Bundling the substrate is for **portability and durability** (the artifact doesn't rot on external dependencies), **not** a ban on external references: a page may pull in web fonts, remote images, report-embedded links, or heavy third-party libraries from a CDN where it needs them.

The design system is layered: the **base substrate** (`base.css` / `base.js`) is owned by the **[[understanding-html-docs]]** skill — pdf-studio consumes it as the generator's `--assets` base — and the **pdf-studio context layer** (`pdf-studio.css` / `pdf-studio.js`) is owned by **`pdf-studio-site-base`**, passed to the generator as `--context` (the library index uses the same two layers). This skill's own `assets/` holds only the `index.html` landing-page template. If either `understanding-html-docs` or `pdf-studio-site-base` is not installed, stop and say so rather than guessing an asset path.

## When this applies

The input is a pdf-studio work dir (`<dir>/<name>/`) with at least one report under `reports/`. `audio/` is optional — pages without audio simply get no player. If no report exists yet, run [[pdf-studio-summarize]] first; for audio on the pages, run [[pdf-studio-audio-dialogue]] → [[pdf-studio-audio-narrate]] first.

The generator's runtime is **pandoc**, resolved by its own preflight (PATH → bundled `nix develop` → fail). It runs once, in Phase 2, over the whole `ir/` dir.

## Phase 1 — Scaffold

1. Inventory `reports/*.md`, `audio/*` (`.m4a`, also `.mp3`/`.wav` for hand-added files), and `ocr/figures/*` if the figure harvest ran. Fix the page order now: `overview` first, the rest naturally sorted (`chapter-2` before `chapter-10`) — this order is the **single source of truth for the page navigation** (the `nav-manifest.js` written in Phase 3). Chapters are **not** color-coded: color carries meaning in this design system, so a per-chapter hue would collide with it. Which chapter you are in is answered by the nav, the title, and the index — not by a color.
2. **If `<WORK_DIR>/site/` already exists, ask the user before clearing it** (no prompt is needed when it doesn't exist yet). A clean rebuild (recommended) does `rm -rf <WORK_DIR>/site <WORK_DIR>/ir` first so that anything no longer produced (renamed/removed chapters, stale narration, superseded assets) leaves no orphan behind — which matters because a later [[pdf-studio-deploy-site]] run publishes whatever is on disk. If the user declines, build over the existing tree instead and warn that orphaned files may remain and would be published on the next deploy. Clearing is safe: everything under `site/` and `ir/` is reproducible from `reports/`, `audio/`, and `ocr/figures/`, and hand-added audio lives in the **source** `audio/` (not `site/`), so it is never touched. Then create `<WORK_DIR>/ir/` (the semantic layer Phase 2 writes) and `<WORK_DIR>/site/audio/`, and copy the audio files into `site/audio/`. **You do NOT copy the four design-system assets here** — the generator copies `base.css`/`base.js` (from `--assets`) and `pdf-studio.css`/`pdf-studio.js` (from `--context`) into `site/assets/` when it runs in Phase 2. `site/` and `ir/` are disposable — never hand-edit `site/` (edit `reports/` and regenerate); the editable semantic layer is `ir/`.
3. **Copy the figures into the site** — if `<WORK_DIR>/ocr/figures/` exists, copy it **whole** to `site/figures/` (`cp -R <WORK_DIR>/ocr/figures site/figures`). Copy every crop, not only the ones the reports embed: the pages are authored in parallel by workers that each see one report, so at this point nobody knows the union of referenced figures; a handful of unreferenced crops is harmless (Pages allows 25 MiB per file and 20,000 files). **This is what makes the site self-contained.** The reports embed figures as `../ocr/figures/…` (a path relative to `reports/`); the generator's filter rewrites that prefix to `figures/…` at generation time, so this step is what puts a file there for the rewritten path to point at.

## Phase 2 — Author IR, then generate (parallel authoring + one build)

**2a — Author one IR file per report** by applying the **`pdf-studio-site-page`** procedure (its restructuring rules and IR vocabulary live in that skill). It writes a semantic IR (`<WORK_DIR>/ir/<slug>.md`), NOT HTML. Run the reports **in parallel**:

- **Under Claude Code**, dispatch one `pdf-studio-site-page` subagent per report (multiple Agent calls in one message) so each page is authored in an isolated context and they run concurrently.
- **Otherwise**, apply the `pdf-studio-site-page` skill once per report.

Pass only the per-page inputs, all absolute paths:

- source report path; output IR path `<WORK_DIR>/ir/<slug>.md`
- site title; kicker label (第N章 / 全体レポート)
- whether `<WORK_DIR>/ocr/figures/` exists (from Phase 1 step 3) — the worker carries the report's `../ocr/figures/X` references as-is and the generator rewrites them
- matching audio file name under `site/audio/` (or "none")

The worker does **not** author prev/next links, `<head>`, classes, or figure-path rewrites: navigation is rendered at runtime by `pdf-studio.js` from the `nav-manifest.js` you write in Phase 3 (loaded via each IR's `context-js` frontmatter), and the mechanical markup is the generator's guarantee. Each returns only the IR path, the page title, and a 2–3 line card summary. Do not read the finished IR back for the card — trust the replies. (Optionally estimate reading time from the report's length — e.g. `wc -m` (character count, not `wc -w`: Japanese isn't space-delimited) at ~500 Japanese chars/min — to put a ⏱ chip on the card in Phase 3.)

**2b — Generate the pages.** Once every IR is written, build them all in one pass with the generator's site builder:

```bash
understanding-html-docs/scripts/build-site.sh <WORK_DIR>/ir <WORK_DIR>/site \
  --assets understanding-html-docs/assets \
  --context pdf-studio-site-base/assets
```

This renders each `ir/<slug>.md` → `site/<slug>.html`, and copies the four design-system assets (`base.css`/`base.js` from `--assets`, `pdf-studio.css`/`pdf-studio.js` from `--context`) verbatim into `site/assets/`. A bad IR (unknown callout variant, `.player` without `src=`) **fails the build loudly** — fix the offending IR and re-run. Resolve the skill directories the same way the rest of the skill does (siblings under the skills root); if `understanding-html-docs` or `pdf-studio-site-base` is missing, stop and say so.

## Phase 3 — Landing page + nav manifest (orchestrator, inline)

Write `site/index.html` from `pdf-studio-generate-site/assets/index.html` (hand-authored HTML — the landing page is composed by you from the card replies, not generated from a report): hero (site title = the book title, a 2–3 sentence lede composed from the overview card summary, chapter/audio count chips, CTA to `overview.html`), then one card per page in order — kicker, returned title, returned summary. Give each card a ⏱ reading-time chip and a 🔊 chip when they apply. Audio files with no matching report get inline players under 音声ガイド.

**Then write `site/assets/nav-manifest.js`** — the single source of truth for page-to-page navigation, from the fixed Phase 1 order. It lives under `site/assets/` (next to the copied assets) because every generated page references it as a `context-js` asset (`assets/nav-manifest.js`); it is data, not one of the four copied assets, so the generator's `--context` copy never produces it — you write it here directly. `pdf-studio.js` reads `window.__PDF_STUDIO_NAV` to render prev/next and highlight the current page. It is the whole reason no page carries hand-authored neighbor links: to add or remove a page you regenerate **only this one file**. Emit one entry per report page in reading order (the landing page is not an entry — it is home, reached via each page's `← SITE_TITLE` header link):

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

`slug` = the page basename without `.html`; `href` = `<slug>.html`; `kicker` = the same kicker label passed to that page in Phase 2; `title` = the title the Phase 2 worker returned. It must be valid JavaScript — quote strings as JSON. Then verify (see Success criteria).

## Hand off to deployment

After building `site/`, tell the user the site is ready under `<WORK_DIR>/site/` and that [[pdf-studio-deploy-site]] can put it on the internet (as a subpath of the shared Cloudflare Pages library, Access-protected) — or offer to run it. If nothing has been deployed before, the one-time [[pdf-studio-initialize-site]] setup must run first. Do not deploy here: the split lets the user review the generated site before it goes public.

## Gotchas

- **`site/` and `ir/` are disposable and rebuilt from source.** When they already exist the skill asks before clearing; a clean rebuild (recommended) drops files no longer produced so they don't linger as orphans. Never hand-edit `site/` — edit the source `reports/` (or, for a semantic fix, the `ir/`) and regenerate. A later [[pdf-studio-deploy-site]] run publishes whatever is on disk, so prefer a clean rebuild before redeploying.
- **Restructuring is the deliverable.** An IR whose heading sequence mirrors the source Markdown is a conversion, not an authored page — re-author it with the instruction to restructure (the `pdf-studio-site-page` procedure states the same rule).
- **A failed build points at one IR.** The generator fails loudly on an invalid IR (unknown variant, `.player` missing `src=`); the message names the file — fix that `ir/*.md` and re-run Phase 2b. The mechanical error classes — an invented class, an unwrapped table, a figure pointing outside the site — are structurally impossible here, not review-caught: the generator cannot emit them.

## Success criteria

- [ ] Every `reports/*.md` has an `ir/<slug>.md` and a generated `site/<slug>.html`, and `index.html` has a card for each with a composed (not copied) summary; `overview` is the hero CTA.
- [ ] Each page carries a `lede` and a `keypoints` box (present in the IR, rendered by the generator).
- [ ] **`site/` is self-contained — nothing points outside it.** The generator's figure-path rewrite guarantees no page keeps a `../ocr/figures/…` reference (the old `grep '\.\./'` review catch is now a generation-time guarantee, not a check). Every `<img src>` resolves to a file under `site/figures/`.
- [ ] Reports with a matching audio slug have an in-page player (from the IR's `.player` directive); unmatched audio is listed on the index; every referenced audio file exists in `site/audio/`.
- [ ] The design system is bundled locally: all four of `site/assets/base.css`, `site/assets/base.js`, `site/assets/pdf-studio.css`, `site/assets/pdf-studio.js` exist (copied by the generator), plus `site/assets/nav-manifest.js` (written in Phase 3). Every generated page's `<head>` carries the theme-boot inline script and loads `assets/base.js`, `assets/nav-manifest.js`, `assets/pdf-studio.js` in that order (guaranteed by the template + the `context-js` frontmatter order). (External references — web fonts, CDN libraries, remote images — are allowed where a page needs them; they are not checked.)
- [ ] **Page navigation has a single source.** `site/assets/nav-manifest.js` exists, assigns `window.__PDF_STUDIO_NAV` with one `pages` entry per report page in reading order, and is valid JS (loads without a console error). No page hand-authors a `<nav class="chapnav">` (verify: `grep -n 'class="chapnav"' site/*.html` → no hits; prev/next is rendered at runtime). Opening a middle page shows working ← prev / next → links; the first page has no prev and the last has no next.
- [ ] The user was told the site is built under `<WORK_DIR>/site/` and pointed to [[pdf-studio-deploy-site]] for putting it online.
