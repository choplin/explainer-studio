---
name: understanding-reading-site-base
description: The shared workflow for turning a work dir's reports/ into a reading-guide website — the scaffold, the parallel semantic-Markdown authoring, the single generator build, the semantic landing page, and the nav manifest. It owns the pipeline that pdf-studio-generate-site and paper-studio-generate-site both run; each consumer delegates here and supplies only its own page-ordering profile (which reports, in what order, with what kicker labels) and its document-type vocabulary. Use this skill when a reading-site generate-site skill delegates its build here, or when adding a new consumer of the same reading-site pipeline. Not user-invocable and not triggered directly by user requests — a generate-site consumer invokes it.
user-invocable: false
---

# understanding-reading-site-base — the shared reading-site build pipeline

This skill owns the **workflow shared by every skill that turns a work dir's
`reports/` into a reading-guide website** — today [[pdf-studio-generate-site]]
(book chapters) and [[paper-studio-generate-site]] (paper perspectives), and any
future skill of the same shape. It exists so the pipeline lives in **one place**
instead of being copy-pasted into each consumer and kept in sync by hand.

A consumer skill is a thin shell: it carries its own trigger description, its
**page-ordering profile** (which reports, in what order, with what kicker labels),
and its **document-type vocabulary** (the landing-page nouns — e.g. 読書ガイド vs
論文ガイド), and delegates the entire build to this skill. Everything mechanical —
scaffold, authoring, build, landing, nav — is here and identical for all consumers.

The output is a **reading-guide website** under `<WORK_DIR>/site/`: a landing page
with one card per report, and one authored page per report with its matching audio
guide playable in-page. This skill only *builds* the site; putting it on the
internet is [[pdf-studio-deploy-site]]'s job — keeping the two apart lets the
generated site be reviewed before it goes public.

## What the consumer supplies (the profile contract)

The pipeline is generic except for two things the consumer provides. The boundary
between consumer and this base is exactly this contract — keep it minimal.

### 1. The ordered page list — `[{ slug, kicker }]`

The consumer resolves `reports/*.md` into an **ordered list of `{ slug, kicker }`**
and hands it to the pipeline. This base does not care *how* the list was computed
(a fixed table, a natural-sort rule, whatever) — only that it satisfies these
invariants:

- **`overview` is first** and is the landing-page hero CTA / home page.
- Every report that actually exists under `reports/` appears **exactly once**;
  nothing that doesn't exist is listed.
- The order is **deterministic** (re-running produces the same order).
- Every `kicker` is **non-empty**.

This ordered list is the **single source of truth for the page navigation** — Phase 1
fixes it and Phase 3 emits it verbatim as `nav-manifest.js`. Reports are **not**
color-coded: color carries meaning in this design system, so a per-report hue would
collide with it. Which report you are on is answered by the nav, the title, and the
index — not by a color.

How each current consumer computes the list (this logic lives in the consumer, not
here):

- **pdf-studio**: `overview` → kicker `全体レポート` first, then `chapter-N` in
  natural order (`chapter-2` before `chapter-10`) with kicker `第N章`; any report
  matching neither is appended last in natural sort with a kicker derived from a
  title-case of its slug.
- **paper-studio**: a fixed perspective table — `overview`→`全体レポート`,
  `background`→`背景`, `method`→`手法`, `experiments`→`実験`, `discussion`→`議論`,
  `related-work`→`関連研究` — including only those that exist, keeping that order;
  any report not in the table is appended last in natural sort with a derived kicker.

### 2. The landing document-type vocabulary

The landing page names what kind of documents these are. The consumer supplies the
nouns; the pipeline drops them into `src/index.md` (Phase 2b). At minimum:

- **guide kicker** — the hero eyebrow (e.g. `読書ガイド` / `論文ガイド`).
- **cards-section heading** — the `##` above the card grid (e.g. `チャプター` / `レポート`).
- **count-chip unit** — the noun in the hero count chip (e.g. `章` / `レポート`).

Keep every other landing-page string document-type neutral (see Phase 2b).

## When this applies

The input is a work dir (`<dir>/<name>/`) with at least one report under `reports/`.
`audio/` is optional — pages without audio simply get no player. If no report exists
yet, the consumer's summarize skill must run first; for audio on the pages, run
[[pdf-studio-audio-dialogue]] → [[pdf-studio-audio-narrate]] first.

The pages are **authored, not converted** — and authored as **semantic Markdown**,
not hand-written HTML. The [[pdf-studio-site-page]] procedure rewrites each report
for web reading (lede, key-points box, scannable sections) as Markdown + fenced divs
that name only *meaning*; the [[understanding-html-docs]] generator then binds that
semantic Markdown to the markup deterministically. Rendering the Markdown 1:1 into
HTML is explicitly NOT the deliverable. What the generator guarantees, so the
authoring worker cannot get it wrong: the `<head>`/theme-boot/asset order is always
correct, an invented class or inline style is unrepresentable, an unknown callout
variant is a hard build error, every table is wrapped in `.tablewrap`, and figure
paths are rewritten to point inside the site root. What stays a reading judgment
(is this passage a hazard or the key point) lives in the source and is the author's
call, guided by the `pdf-studio-site-page` rules.

The output is a **no-server static site** (openable by double-click, no build step)
that bundles its design system locally as progressive enhancement, so every page
stays fully readable if JS is disabled. Bundling the substrate is for portability and
durability (the artifact doesn't rot on external dependencies), not a ban on external
references: a page may pull in web fonts, remote images, or report-embedded links
where it needs them.

The design system is layered — all shared, none per-consumer:

- **base substrate** (`base.css` / `base.js`: reading-progress bar, table of contents
  with scroll-spy, theme toggle, back-to-top) and the **reading-nav** widgets
  (`reading-nav.css` / `reading-nav.js`: the index-card filter and runtime page nav)
  are owned by **[[understanding-html-docs]]** — consumed as the generator's
  `--assets` and pulled in with `--component reading-nav`.
- the **content context layer** (`pdf-studio.css` — content styling only) is owned by
  **[[pdf-studio-site-base]]**, passed to the generator as `--context` (the deploy
  library index uses the same layers).

If either `understanding-html-docs` or `pdf-studio-site-base` is not installed, stop
and say so rather than guessing an asset path.

The generator's runtime is **pandoc**, resolved by its own preflight (PATH → bundled
`nix develop` → fail). It runs once, in Phase 3, over the whole `src/` dir.

## Phase 1 — Scaffold

1. Inventory `reports/*.md`, `audio/*` (`.m4a`, also `.mp3`/`.wav` for hand-added
   files), and `ocr/figures/*` if the figure harvest ran. **Fix the page order now**
   by resolving the consumer's profile into the ordered `[{ slug, kicker }]` list
   (see the profile contract) — this order is the single source of truth for the
   page navigation (the `nav-manifest.js` written in Phase 3).
2. **If `<WORK_DIR>/site/` already exists, ask the user before clearing it** (no
   prompt is needed when it doesn't exist yet). A clean rebuild (recommended) does
   `rm -rf <WORK_DIR>/site <WORK_DIR>/src` first so that anything no longer produced
   (renamed/removed reports, stale narration, superseded assets) leaves no orphan
   behind — which matters because a later [[pdf-studio-deploy-site]] run publishes
   whatever is on disk. If the user declines, build over the existing tree instead and
   warn that orphaned files may remain and would be published on the next deploy.
   Clearing is safe: everything under `site/` and `src/` is reproducible from
   `reports/`, `audio/`, and `ocr/figures/`, and hand-added audio lives in the
   **source** `audio/` (not `site/`), so it is never touched. Then create
   `<WORK_DIR>/src/` (the semantic layer Phase 2 writes) and `<WORK_DIR>/site/audio/`,
   and copy the audio files into `site/audio/`. **You do NOT copy the design-system
   assets here** — the generator copies `base.css`/`base.js` (from `--assets`),
   `pdf-studio.css` (from `--context`), and `reading-nav.css`/`reading-nav.js` (from
   `--component reading-nav`) into `site/assets/` when it runs in Phase 3. `site/` and
   `src/` are disposable — never hand-edit `site/` (edit `reports/` and regenerate);
   the editable semantic layer is `src/`.
3. **Copy the figures into the site** — if `<WORK_DIR>/ocr/figures/` exists, copy it
   **whole** to `site/figures/` (`cp -R <WORK_DIR>/ocr/figures site/figures`). Copy
   every crop, not only the ones the reports embed: the pages are authored in parallel
   by workers that each see one report, so at this point nobody knows the union of
   referenced figures; a handful of unreferenced crops is harmless (Pages allows
   25 MiB per file and 20,000 files). **This is what makes the site self-contained.**
   The reports embed figures as `../ocr/figures/…` (a path relative to `reports/`);
   the generator's filter rewrites that prefix to `figures/…` at generation time, so
   this step is what puts a file there for the rewritten path to point at.

## Phase 2 — Author every semantic source (reports + landing)

Everything under `src/` is authored here as semantic Markdown; nothing is
hand-written HTML. Phase 3 builds them all in one pass.

**2a — Author one source file per report** by applying the **[[pdf-studio-site-page]]**
procedure (its restructuring rules and semantic-Markdown vocabulary live in that skill;
it is the generic worker every consumer uses). It writes semantic Markdown
(`<WORK_DIR>/src/<slug>.md`), NOT HTML. Run the reports **in parallel**:

- **Under Claude Code**, dispatch one `pdf-studio-site-page` subagent per report
  (multiple Agent calls in one message) so each page is authored in an isolated context
  and they run concurrently.
- **Otherwise**, apply the `pdf-studio-site-page` skill once per report.

Pass only the per-page inputs, all absolute paths:

- source report path; output source path `<WORK_DIR>/src/<slug>.md`
- site title; **kicker label** = the kicker for that slug from the Phase 1 ordered list
- whether `<WORK_DIR>/ocr/figures/` exists (from Phase 1 step 3) — the worker carries
  the report's `../ocr/figures/X` references as-is and the generator rewrites them
- matching audio file name under `site/audio/` (or "none")

The worker does **not** author prev/next links, `<head>`, classes, or figure-path
rewrites: navigation is rendered at runtime by `reading-nav.js` (the html-docs
reading-nav component) from the `nav-manifest.js` you write in Phase 3 (loaded via each
source's `context-js` frontmatter), and the mechanical markup is the generator's
guarantee. Each returns only the source path, the page title, and a 2–3 line card
summary. Do not read the finished source back for the card — trust the replies.
(Optionally estimate reading time from the report's length — `wc -m` (character count,
not `wc -w`: Japanese isn't space-delimited) at ~500 Japanese chars/min — to put a
⏱ chip on the card in Phase 2b.)

**2b — Author the landing source `src/index.md`** (orchestrator, inline). The landing
is a generated page like any other — authored as semantic Markdown, **not** hand-written
HTML — composed by you from the Phase 2a card replies. Use this frontmatter (the
landing is home, so `site-name` has no back-arrow and there is no prev/next):

```yaml
---
title: <SITE_TITLE>
site-name: <SITE_TITLE>
context-css:
  - pdf-studio.css
  - reading-nav.css
context-js:
  - nav-manifest.js
  - reading-nav.js
---
```

Then the body, reaching only for the semantic vocabulary (the generator rejects raw
HTML and invented classes):

- **Hero** — `::: {.kicker}` with the consumer's guide kicker (読書ガイド / 論文ガイド),
  `# <SITE_TITLE>`, a `::: {.lede}` of 2–3 sentences composed from the `overview` card
  summary, count chips as `[全N<unit>]{.chip}` / `[🔊 N]{.chip}` using the consumer's
  count-chip unit, and a prominent plain-link CTA to the overview inviting the reader
  in — e.g. `[全体レポートを読む →](overview.html)` (a Markdown link, not a styled button).
- **Card index** — the consumer's cards-section heading as `## <heading>` (チャプター /
  レポート), then a filterable card grid:

  ```markdown
  :::: {.card-grid filter="絞り込む…"}
  ::: {.card}
  ::: {.kicker}
  第1章
  :::
  ### [章タイトル](chapter-1.html)
  カード要約 2–3行。⏱ と 🔊 は該当時のみチップで。
  :::
  ::::
  ```

  One `::: {.card}` per page in the Phase 1 order — its kicker, the returned title
  linked to `<slug>.html`, and the returned summary. Add a ⏱ reading-time chip and a
  🔊 chip (`[…]{.chip}`) where they apply. The `filter=` attribute is what opts this
  grid into the reading-nav live filter (the generator emits `data-reading-filter`);
  keep the placeholder document-type neutral (`絞り込む…`), never "章を絞り込む".
- **Unmatched audio** — any audio file with no matching report page goes under a
  `## 音声ガイド` heading as inline players: `::: {.player src=audio/<file>}` `:::`.

Compose the landing from the card replies — do not re-read the finished report sources.

**Then write `site/assets/nav-manifest.js`** is deferred to Phase 3 (it lives under
the generated `site/assets/`, which the build creates).

## Phase 3 — Build once, then the nav manifest

**3a — Build every source in one pass** with the generator's site builder. This
renders `src/index.md` → `site/index.html` and each `src/<slug>.md` → `site/<slug>.html`
together, and copies the design-system assets verbatim into `site/assets/`:

```bash
understanding-html-docs/scripts/build-site.sh <WORK_DIR>/src <WORK_DIR>/site \
  --assets understanding-html-docs/assets \
  --context pdf-studio-site-base/assets \
  --component reading-nav
```

`build-site.sh` globs `src/*.md`, so the landing (`src/index.md`) builds as a normal
page — no special-casing. A bad source (unknown callout variant, `.player` without
`src=`) **fails the build loudly** — fix the offending source and re-run. Resolve the
skill directories the same way the rest of the pipeline does (siblings under the skills
root); if `understanding-html-docs` or `pdf-studio-site-base` is missing, stop and say
so.

**3b — Write `site/assets/nav-manifest.js`** — the single source of truth for
page-to-page navigation, from the fixed Phase 1 order. It lives under `site/assets/`
(next to the copied assets) because every generated report page references it as a
`context-js` asset; it is data, not one of the copied design-system assets, so neither
`--context` nor `--component` produces it — you write it here directly. `reading-nav.js`
reads `window.__HTMLDOCS_NAV` to render prev/next and highlight the current page. It is
the whole reason no page carries hand-authored neighbor links: to add or remove a page
you regenerate **only this one file**. Emit one entry per report page in reading order
(the landing is not an entry — it is home, reached via each page's `← SITE_TITLE`
header link):

```js
/* page navigation manifest — generated. Single source of truth for this site's page
   list; regenerate THIS FILE ONLY when pages are added or removed. */
window.__HTMLDOCS_NAV = {
  "pages": [
    { "slug": "overview",  "href": "overview.html",  "kicker": "全体レポート", "title": "RETURNED_TITLE" },
    { "slug": "chapter-1", "href": "chapter-1.html", "kicker": "第1章",     "title": "RETURNED_TITLE" }
  ]
};
```

`slug` = the page basename without `.html`; `href` = `<slug>.html`; `kicker` = the same
kicker from the Phase 1 ordered list; `title` = the title the Phase 2a worker returned.
It must be valid JavaScript — quote strings as JSON. Keep the `window.__HTMLDOCS_NAV`
global name verbatim — it is what the shared `reading-nav.js` reads. Then verify (see
Success criteria).

## Hand off to deployment

After building `site/`, tell the user the site is ready under `<WORK_DIR>/site/` and
that [[pdf-studio-deploy-site]] can put it on the internet (as a subpath of the shared
Cloudflare Pages library, Access-protected) — or offer to run it. If nothing has been
deployed before, the one-time [[pdf-studio-initialize-site]] setup must run first. Do
not deploy here: the split lets the user review the generated site before it goes
public.

## Gotchas

- **`site/` and `src/` are disposable and rebuilt from source.** When they already
  exist the skill asks before clearing; a clean rebuild (recommended) drops files no
  longer produced so they don't linger as orphans. Never hand-edit `site/` — edit the
  source `reports/` (or, for a semantic fix, the `src/`) and regenerate. A later
  [[pdf-studio-deploy-site]] run publishes whatever is on disk, so prefer a clean
  rebuild before redeploying.
- **The landing is a generated page, not hand-written HTML.** It is authored as
  `src/index.md` (semantic Markdown) and built with everything else — there is no
  `index.html` template to fill. The filterable card index is `:::: {.card-grid
  filter="…"}`, never a hand-authored `ol.cards`; the reading-nav bundle injects the
  search box at runtime.
- **Restructuring is the deliverable (report pages).** A source whose heading sequence
  mirrors the source Markdown is a conversion, not an authored page — re-author it with
  the instruction to restructure (the `pdf-studio-site-page` procedure states the same
  rule).
- **A failed build points at one source.** The generator fails loudly on an invalid
  source (unknown variant, `.player` missing `src=`); the message names the file — fix
  that `src/*.md` and re-run Phase 3a. The mechanical error classes — an invented class,
  an unwrapped table, a figure pointing outside the site — are structurally impossible
  here, not review-caught: the generator cannot emit them.
- **Reuse, don't fork, the shared assets.** The content context layer (`pdf-studio.css`)
  comes from `pdf-studio-site-base` (the name is the shared context layer, not a
  pdf-studio-only dependency) and is passed as `--context`; the reading-site nav widgets
  come from understanding-html-docs' `reading-nav` component via `--component reading-nav`.
  A consumer owns only its trigger, its ordering profile, and its landing vocabulary.

## Success criteria

- [ ] Every `reports/*.md` present has a `src/<slug>.md` and a generated
      `site/<slug>.html`, and `src/index.md` → `site/index.html` has a card for each
      with a composed (not copied) summary; `overview` is the hero CTA and first page.
- [ ] The landing is generated from `src/index.md` — **no `index.html` template exists**
      and no page hand-authors `ol.cards` (the card index is `.card-grid filter=`).
- [ ] Pages are ordered by the consumer's profile and each carries its profile kicker
      (e.g. pdf: overview → 第N章 natural order; paper: overview → 背景 → 手法 → …).
- [ ] Each report page carries a `lede` and a `keypoints` box (present in the source,
      rendered by the generator).
- [ ] **`site/` is self-contained — nothing points outside it.** The generator's
      figure-path rewrite guarantees no page keeps a `../ocr/figures/…` reference. Every
      `<img src>` resolves to a file under `site/figures/`.
- [ ] Reports with a matching audio slug have an in-page player; unmatched audio is
      listed on the index; every referenced audio file exists in `site/audio/`.
- [ ] The design system is bundled locally: all of `site/assets/base.css`, `base.js`,
      `pdf-studio.css`, `reading-nav.css`, `reading-nav.js` exist (copied by the
      generator), plus `site/assets/nav-manifest.js` (written in Phase 3b). Every
      generated report page's `<head>` loads `assets/base.js`, `assets/nav-manifest.js`,
      `assets/reading-nav.js` in that order (guaranteed by the template + `context-js`).
- [ ] **Page navigation has a single source.** `site/assets/nav-manifest.js` assigns
      `window.__HTMLDOCS_NAV` with one `pages` entry per report page in reading order,
      and is valid JS. Opening a middle page shows working ← prev / next → links; the
      first has no prev and the last has no next. The landing filter narrows the cards.
- [ ] The user was told the site is built under `<WORK_DIR>/site/` and pointed to
      [[pdf-studio-deploy-site]] for putting it online.
