---
name: paper-studio-generate-site
description: This skill should be used when the user wants paper-studio reports turned into a real website — authored web pages (not converted Markdown) browsable from a smartphone, built as a static site under a work dir's site/ from its reports/ (overview + background / method / experiments / discussion / related-work), with the overview's audio guide playable in-page. Triggers on "論文レポートをWebサイトにして", "この論文サマリをHTMLにして", "サイトを作って", "スマホで読めるようにして", "generate a site from the paper reports". Should NOT trigger for deploying/hosting the built site (use pdf-studio-deploy-site), for producing the reports (use paper-studio-summarize), or for the audio guide (use pdf-studio-audio-dialogue / pdf-studio-audio-narrate).
user-invocable: true
---

# Generate Site — paper reports as an authored website

Turn a paper-studio work dir into a **reading-guide website** under `<WORK_DIR>/site/`: a landing page with report cards, and one authored page per report (overview + the in-scope perspective reports) with the matching audio guide playable in-page. This skill only *builds* the site; putting it on the internet is [[pdf-studio-deploy-site]]'s job — keeping the two apart lets the generated site be reviewed before it goes public.

paper-studio and pdf-studio share the same work-dir conventions and the same site design system, so this skill is the **paper-tuned sibling** of [[pdf-studio-generate-site]]: it reuses the generic per-page authoring worker ([[pdf-studio-site-page]]), the context-layer assets ([[pdf-studio-site-base]]), and the base substrate ([[understanding-html-docs]]) unchanged, and differs only in what a paper's report set needs — a **fixed perspective order** (not chapter numbering) and **perspective kicker labels** (背景 / 手法 / … instead of 第N章). Do not re-derive the shared mechanics here; follow the referenced skills for them.

> **Sync note:** the scaffold (Phase 1), page review (Phase 4), Gotchas, and Success criteria below are deliberately kept identical to [[pdf-studio-generate-site]] — the only paper-specific delta is the report order and the kicker labels. If the shared site pipeline changes (a new phase, a nav change, an asset added), update **both** skills so they don't drift.

The pages are **authored, not converted**: the `pdf-studio-site-page` procedure rewrites each report for web reading (lede, key-points box, scannable sections) against a bundled design system. Rendering the Markdown 1:1 into HTML is explicitly NOT the deliverable. The output is a **no-server static site** (openable by double-click, no build step) that bundles its design system locally as progressive enhancement, so every page stays fully readable if JS is disabled.

The design system is layered: the **base substrate** (`base.css` / `base.js`) is owned by the **[[understanding-html-docs]]** skill, and the **context layer** (`pdf-studio.css` / `pdf-studio.js`) is owned by **[[pdf-studio-site-base]]** (the deploy library index uses the same two layers, which is why paper-studio reuses them rather than forking a parallel set). This skill's own `assets/` holds only the templates `page.html` and `index.html` (paper-tuned). If either `understanding-html-docs` or `pdf-studio-site-base` is not installed, stop and say so rather than guessing an asset path.

## When this applies

The input is a paper-studio work dir (`<dir>/<slug>/`) with at least one report under `reports/` — typically `overview.md` plus the perspective reports produced by [[paper-studio-summarize]]. `audio/` is optional — pages without audio simply get no player. If no report exists yet, run [[paper-studio-summarize]] first; for the overview audio on the page, run [[pdf-studio-audio-dialogue]] (pointed at `reports/overview.md`) → [[pdf-studio-audio-narrate]] first.

Because the work-dir layout is identical to pdf-studio's, [[pdf-studio-generate-site]] would also *build* on these artifacts — but it would order the pages by `chapter-N` natural sort and label them 第N章, which is wrong for a paper's perspective report set. This skill exists to fix exactly that: the report order and the kicker labels. Everything else is delegated to the shared skills above.

## Report order and kicker labels (the paper-specific part)

A paper's reports are not chapters; they are **fixed perspectives**. Order the pages by this canonical sequence and label each with its perspective kicker:

| report slug (`reports/<slug>.md`) | page order | kicker label |
|-----------------------------------|-----------|--------------|
| `overview`      | 1 | 全体レポート |
| `background`    | 2 | 背景 |
| `method`        | 3 | 手法 |
| `experiments`   | 4 | 実験 |
| `discussion`    | 5 | 議論 |
| `related-work`  | 6 | 関連研究 |

- `overview` is always first and is the landing-page hero CTA.
- Include only the reports that actually exist under `reports/` (the run may have produced a subset — "overview only", or a chosen subset of perspectives). Keep the canonical order for whichever are present; do not renumber.
- Any report whose slug is **not** in the table (a hand-added or deep-dived report, e.g. a `pdf-studio-deep-dive` output) is appended **after** the canonical ones, in natural sort, with a kicker derived from its slug (e.g. a readable title-case of the slug). Do not drop it.
- This order is the **single source of truth for the page navigation** — it becomes the `nav-manifest.js` (Phase 3) from which prev/next and the page list are rendered at runtime. Reports are **not** color-coded: color carries meaning in this design system, so a per-report hue would collide with it. Which report you are on is answered by the nav, the title, and the index — not by a color.

## Phase 1 — Scaffold

1. Inventory `reports/*.md`, `audio/*` (`.m4a`, also `.mp3`/`.wav` for hand-added files), and `ocr/figures/*` if the OCR figure harvest ran (paper-studio always runs MinerU, so `ocr/figures/` normally exists). Fix the page order now per the canonical table above — this order is the single source of truth for the nav (`nav-manifest.js`, Phase 3).
2. **If `<WORK_DIR>/site/` already exists, ask the user before clearing it** (no prompt is needed when it doesn't exist yet). A clean rebuild (recommended) does `rm -rf <WORK_DIR>/site` first so that anything no longer produced leaves no orphan behind — which matters because a later [[pdf-studio-deploy-site]] run publishes whatever is on disk. If the user declines, build over the existing tree and warn that orphaned files may remain and would be published on the next deploy. Clearing is safe: everything under `site/` is reproducible from `reports/`, `audio/`, and `ocr/figures/`, and hand-added audio lives in the **source** `audio/` (not `site/`), so it is never touched. Then create `<WORK_DIR>/site/assets/` and `site/audio/` and copy the **four asset files** into `site/assets/` — the base substrate `understanding-html-docs/assets/base.css` and `.../base.js`, and the context layer `pdf-studio-site-base/assets/pdf-studio.css` and `.../pdf-studio.js` — plus the audio files into `site/audio/`. Copy each verbatim; never edit them per site. `site/` is disposable — never hand-edit it (edit `reports/` and regenerate instead).
3. **Copy the figures into the site** — if `<WORK_DIR>/ocr/figures/` exists, copy it **whole** to `site/figures/` (`cp -R <WORK_DIR>/ocr/figures site/figures`). Copy every crop, not only the ones the reports embed: the pages are authored in parallel by workers that each see one report, so at this point nobody knows the union of referenced figures; a handful of unreferenced crops is harmless. **This is what makes the site self-contained.** The reports embed figures as `../ocr/figures/…` (a path relative to `reports/`, correct for reading the Markdown); a page that keeps that path resolves *outside* `site/`, which still renders locally but 404s the moment [[pdf-studio-deploy-site]] publishes `site/` alone. `pdf-studio-site-page` rewrites the path to `figures/…` — this step is what puts a file there for it to point at.

## Phase 2 — Author pages (parallel)

Author one page per report by applying the **[[pdf-studio-site-page]]** procedure (its restructuring rules and class catalog live in that skill; it is the same generic worker pdf-studio uses). Run the reports **in parallel**:

- **Under Claude Code**, dispatch one `pdf-studio-site-page` subagent per report (multiple Agent calls in one message) so each page is authored in an isolated context and they run concurrently.
- **Otherwise**, apply the `pdf-studio-site-page` skill once per report.

Pass only the per-page inputs, all absolute paths:

- source report path; **template path** = this skill's `paper-studio-generate-site/assets/page.html`; output path `site/<slug>.html`
- site title (= the paper title, from `reports/overview.md`'s `<h1>`); **kicker label** = the perspective label from the canonical table (全体レポート / 背景 / 手法 / 実験 / 議論 / 関連研究, or the derived label for an appended report)
- whether `site/figures/` exists (from Phase 1 step 3), so the worker knows the report's `../ocr/figures/X` references are rewritten to `figures/X` — the site must not reference anything outside `site/`
- matching audio file name under `site/audio/` (or "none") — for a paper this is usually just `overview.m4a` for the overview page

The worker does **not** author prev/next links: page-to-page navigation is rendered at runtime by `pdf-studio.js` from the `nav-manifest.js` you write in Phase 3. Each returns only the output path, the page title, and a 2–3 line card summary. Do not read the finished pages back — trust the replies. (Optionally estimate reading time from the report's length — `wc -m` (character count, not `wc -w`: Japanese isn't space-delimited) at ~500 Japanese chars/min — to put a ⏱ chip on the card in Phase 3.)

## Phase 3 — Landing page (orchestrator, inline)

Write `site/index.html` from this skill's `assets/index.html`: hero (site title = the paper title, a 2–3 sentence lede composed from the overview card summary, report/audio count chips, CTA to `overview.html`), then one card per page in canonical order — kicker, returned title, returned summary. Give each card a ⏱ reading-time chip and a 🔊 chip when they apply. Audio files with no matching report get inline players under 音声ガイド.

**Then write `site/nav-manifest.js`** — the single source of truth for page-to-page navigation, from the fixed canonical order. Every page loads it (a `<script src="nav-manifest.js">` line already in both templates), and `pdf-studio.js` reads `window.__PDF_STUDIO_NAV` to render prev/next and highlight the current page. Emit one entry per report page in reading order (the landing page is not an entry — it is home, reached via each page's `← SITE_TITLE` header link):

```js
/* paper-studio page navigation manifest — generated. Single source of truth for this
   site's page list; regenerate THIS FILE ONLY when pages are added or removed. */
window.__PDF_STUDIO_NAV = {
  "pages": [
    { "slug": "overview",   "href": "overview.html",   "kicker": "全体レポート", "title": "RETURNED_TITLE" },
    { "slug": "background", "href": "background.html", "kicker": "背景",       "title": "RETURNED_TITLE" }
  ]
};
```

`slug` = the page basename without `.html`; `href` = `<slug>.html`; `kicker` = the same perspective label passed to that page in Phase 2; `title` = the title the Phase 2 worker returned. It must be valid JavaScript — quote strings as JSON (the assignment is plain data, no logic). Keep the `window.__PDF_STUDIO_NAV` global name verbatim — it is what the shared `pdf-studio.js` reads. Then verify (see Success criteria).

## Phase 4 — Review the generated pages

The pages were authored by an agent against a written contract, and a contract violation here **does not break the page** — a callout whose variant contradicts its own text renders as a perfectly good box in the wrong color, and nobody notices. So read them back: apply **[[understanding-html-docs-review]]** to every page under `site/` (including `index.html`).

- **Under Claude Code**, dispatch one `understanding-html-docs-reviewer` subagent per page (multiple Agent calls in one message) so each review runs concurrently in a **fresh context**. This matters: the agent that authored a page cannot read it independently of having just written it.
- **Otherwise**, apply the `understanding-html-docs-review` skill once per page.

Fix what comes back (the review reports; it does not edit), then re-check. Report to the user what was found and fixed — a review whose findings are never surfaced is indistinguishable from one that never ran.

## Hand off to deployment

After building `site/`, tell the user the site is ready under `<WORK_DIR>/site/` and that [[pdf-studio-deploy-site]] can put it on the internet (as a subpath of the shared Cloudflare Pages library, Access-protected) — or offer to run it. If nothing has been deployed before, the one-time [[pdf-studio-initialize-site]] setup must run first. Do not deploy here: the split lets the user review the generated site before it goes public.

## Gotchas

- **A figure kept at the report's `../ocr/figures/…` path breaks only after deploy.** From `site/<slug>.html` that path still resolves (to the work dir one level up), so the page looks right in a local browser and the failure is invisible until [[pdf-studio-deploy-site]] publishes `site/` on its own and every figure 404s. Never trust the local render on this — run the `grep -n '\.\./' site/*.html` check in the Success criteria.
- **Restructuring is the deliverable.** A page whose heading sequence mirrors the source Markdown is a conversion, not an authored page — re-author it (the `pdf-studio-site-page` procedure states the same rule).
- **`site/` is disposable and rebuilt from source.** Never hand-edit `site/` — edit the source `reports/` and regenerate. A later [[pdf-studio-deploy-site]] run publishes whatever is on disk, so prefer a clean rebuild before redeploying.
- **Reuse, don't fork, the shared assets.** The four asset files come from `understanding-html-docs` and `pdf-studio-site-base` (the `pdf-studio.css`/`.js` names are the shared context layer, not a pdf-studio-only dependency). Copy them as-is; only this skill's own `page.html`/`index.html` templates are paper-tuned.

## Success criteria

- [ ] Every `reports/*.md` present has a `site/<slug>.html`, and `index.html` has a card for each with a composed (not copied) summary; `overview` is the hero CTA and the first page.
- [ ] Pages are ordered by the canonical perspective sequence (overview → background → method → experiments → discussion → related-work → any appended reports), and each carries its perspective kicker (全体レポート / 背景 / 手法 / 実験 / 議論 / 関連研究), not 第N章.
- [ ] Each page carries a `lede` and a `keypoints` box, and no unrendered Markdown artifacts (verify: `grep -n '\*\*\|^#\{1,3\} ' site/*.html` → only hits inside `<pre>` blocks, if any).
- [ ] Every page was reviewed with [[understanding-html-docs-review]], its findings were fixed, and the user was told what they were.
- [ ] **`site/` is self-contained — nothing points outside it.** Verify: `grep -n '\.\./' site/*.html` → no hits, and every `<img src>` resolves to a file that exists under `site/`.
- [ ] Reports with a matching audio slug have an in-page `<audio>` player; unmatched audio is listed on the index; every referenced audio file exists in `site/audio/`.
- [ ] The design system is bundled locally: all four of `site/assets/base.css`, `site/assets/base.js`, `site/assets/pdf-studio.css`, `site/assets/pdf-studio.js` exist, and every page's `<head>` keeps the theme-boot inline script (key `html-docs-theme`) and the `assets/base.js`, `nav-manifest.js`, and `assets/pdf-studio.js` references in that order (the manifest must load before `pdf-studio.js` reads it).
- [ ] **Page navigation has a single source.** `site/nav-manifest.js` exists, assigns `window.__PDF_STUDIO_NAV` with one `pages` entry per report page in reading order, and is valid JS (loads without a console error). No page hand-authors a `<nav class="chapnav">` (verify: `grep -n 'class="chapnav"' site/*.html` → no hits). Opening a middle page shows working ← prev / next → links; the first page has no prev and the last has no next.
- [ ] The user was told the site is built under `<WORK_DIR>/site/` and pointed to [[pdf-studio-deploy-site]] for putting it online.
