# Authoring and verification

Read this reference completely at the start of Phase 2 and use its checklist after
the build.

## Per-report authoring

Apply [[explainer-reading-site-page]] to every report. Under Claude Code, dispatch
one isolated worker per report in parallel; otherwise apply the procedure once per
report.

Pass only:

- absolute source report path;
- absolute output path `<WORK_DIR>/src/<slug>.md`;
- site title;
- kicker from the Phase 1 ordered list;
- whether `<WORK_DIR>/ocr/figures/` exists;
- matching filename under `site/audio/`, or `none`.

The worker carries any `../ocr/figures/...` references unchanged; the generator
rewrites them. It does not author head markup, classes, prev/next links, or rewrites.
It returns only the source path, page title, and a 2–3 line card summary. Trust the
reply; do not re-read the finished source to compose the landing.

Optionally estimate reading time from `wc -m` at about 500 Japanese characters per
minute. Do not use `wc -w` for Japanese text.

## Landing source

Author `src/index.md` inline with:

```yaml
---
title: <SITE_TITLE>
site-name: <SITE_TITLE>
context-css:
  - reading-site.css
  - reading-nav.css
context-js:
  - nav-manifest.js
  - reading-nav.js
---
```

The landing is home, so it has no back arrow or prev/next link.

Compose:

1. A kicker with the consumer guide noun.
2. `# <SITE_TITLE>`.
3. A 2–3 sentence `.lede` based on the overview worker's summary.
4. `[全N<unit>]{.chip}` and `[🔊 N]{.chip}` counts.
5. A plain Markdown CTA to `overview.html`.
6. The consumer's cards-section `##` heading.
7. A filterable card grid with one card per page in profile order.

Use this card notation:

```markdown
:::: {.card-grid filter="絞り込む…"}
::: {.card}
::: {.kicker}
第1章
:::
### [章タイトル](chapter-1.html)
カード要約 2–3行。必要なときだけ ⏱ と 🔊 のチップ。
:::
::::
```

Each card uses the profile kicker, returned title linked to `<slug>.html`, and returned
summary. Add reading-time/audio chips only when applicable.

List audio without a matching report under `## 音声ガイド` using
`::: {.player src=audio/<file>}`.

Do not hand-write HTML, `ol.cards`, or a page template. The filter attribute becomes
`data-reading-filter`; the reading-nav bundle injects the search UI.

## Navigation manifest

After the build creates `site/assets/`, write:

```js
/* page navigation manifest — generated. Single source of truth for this site's page
   list; regenerate THIS FILE ONLY when pages are added or removed. */
window.__HTMLDOCS_NAV = {
  "pages": [
    { "slug": "overview",  "href": "overview.html",  "kicker": "全体レポート", "title": "RETURNED_TITLE" },
    { "slug": "chapter-1", "href": "chapter-1.html", "kicker": "第1章", "title": "RETURNED_TITLE" }
  ]
};
```

For every report page:

- `slug` is the basename without `.html`;
- `href` is `<slug>.html`;
- `kicker` comes from the fixed profile;
- `title` is the worker-returned title.

Quote strings as JSON and keep the global name exactly
`window.__HTMLDOCS_NAV`. Omit the landing. `reading-nav.js` reads this object to
render prev/next links and current-page state.

## Operational gotchas

- `site/` and `src/` are disposable. Ask before clearing an existing tree; if the
  user declines, warn that stale files may be deployed later.
- Never hand-edit generated `site/`; edit reports or semantic `src/` and regenerate.
- A heading sequence that merely mirrors a report is conversion, not authored
  restructuring.
- A failed build names the invalid source. Fix that source; do not weaken generator
  validation.
- Reuse `reading-site.css` through `--context` and `reading-nav` through
  `--component`. A consumer owns no forked shared assets.
- Write `nav-manifest.js` after the build because the generated `site/assets/`
  directory does not exist before it.

## Success checklist

- [ ] Every existing `reports/*.md` has `src/<slug>.md` and
      `site/<slug>.html`.
- [ ] `src/index.md` generated `site/index.html`, contains one composed card per
      report, and uses overview as the hero CTA and first page.
- [ ] No `index.html` template or hand-authored `ol.cards` exists; the landing uses
      `.card-grid filter=`.
- [ ] Page order and kickers exactly match the consumer profile.
- [ ] Every report source contains a lede and keypoints box.
- [ ] No generated page retains `../ocr/figures/...`; every `<img src>` resolves
      under `site/figures/`.
- [ ] Every report with matching audio has a player; unmatched audio appears on the
      landing; every referenced file exists under `site/audio/`.
- [ ] `site/assets/` contains `base.css`, `base.js`, `reading-site.css`,
      `reading-nav.css`, `reading-nav.js`, and `nav-manifest.js`.
- [ ] Report heads load `base.js`, `nav-manifest.js`, and `reading-nav.js` in that
      order.
- [ ] `nav-manifest.js` is valid JavaScript and contains one ordered entry per report,
      with no landing entry.
- [ ] Opening a middle page shows working previous/next links; endpoints omit the
      unavailable direction; the landing filter narrows cards.
- [ ] The user was told the site is ready under `<WORK_DIR>/site/` and was pointed
      to [[explainer-reading-site-deploy]].
