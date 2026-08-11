# Authoring and verification

Read this reference completely at the start of Phase 2 and use its checklist after
the build.

## Per-report authoring

Apply [[explainer-reading-site-page]] to every report. Under Claude Code, dispatch
one isolated worker per report in parallel; otherwise apply the procedure once per
report.

Before dispatch, resolve two exact attribution strings once in the site's report
language. Keep them concise enough for every heading and explicit enough to rule
out source authorship. For example in Japanese:

```text
EDITORIAL_STRUCTURE_LABEL: 編注
EDITORIAL_STRUCTURE_NOTE: 「編注」の付いた区分・見出しは、読解のために本サイトが追加したもので、原典にはありません。
```

Use the resolved values verbatim in the canonical block below and on every report
page. Individual workers never translate or rephrase them.

Pass only:

- absolute source report path;
- absolute canonical source-structure artifact path supplied by the consumer;
- absolute output path `<WORK_DIR>/src/<slug>.md`;
- site title;
- kicker from the Phase 1 ordered list;
- whether `<WORK_DIR>/ocr/figures/` exists;
- matching filename under `site/audio/`, or `none`;
- the following canonical site-wide authoring conventions, verbatim.

```text
CANONICAL SITE-WIDE AUTHORING CONVENTIONS
- EDITORIAL_STRUCTURE_LABEL: <exact site-wide value resolved above>
- EDITORIAL_STRUCTURE_NOTE: <exact site-wide value resolved above>
- Source-authored body headings use `{.source-structure}` and must match the
  canonical source-structure artifact in existence, hierarchy, title (or faithful
  display translation), and anchor.
- Site-authored body headings use `{.editorial-structure}`. They must not use
  source-native Part/Chapter/Section labels or source-like numbering. The
  reading-site filter renders their attribution in both the article and sidebar.
- Every flowing-body H2/H3 is exactly one of those two types. Component-internal
  and landing headings are exempt.
- Editorial headings may subdivide prose but never reparent source divisions.
  Group real chapters/sections under an editorial theme as list/table/card items,
  not by demoting their source headings into the editorial hierarchy.
- Every source-PDF page reference in prose uses `.p`: `[p31]{.p}` for one page,
  `[p31–p33]{.p}` for a range.
- A page reference never appears in a heading. Move an otherwise-unrepresented
  reference to the first following paragraph; delete a heading copy only when the
  following body already preserves it.
- Sentence punctuation follows the anchor: `… [p14]{.p}。`.
- Do not rewrite lookalikes in fenced/inline code, image alt text, or table-header
  placeholders such as `| [pNN] |`.
- Every report page opens with one kicker, one H1, one lede, then one keypoints box.
```

This block is deliberately both part of the page skill and part of the dispatch
contract. Isolated workers must not infer a site-wide vocabulary independently.

The worker carries any `../ocr/figures/...` references unchanged; the generator
rewrites them. It does not author head markup, presentation-only classes outside the
page skill's semantic vocabulary, prev/next links, or path rewrites.
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

If a returned summary contains a source-PDF page reference, preserve it with the
same canonical `.p` notation in landing prose. Never put it in the landing H1, cards
heading, or a card title.

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
- Restructuring is judged by comprehension and source attribution, not by whether
  the heading sequence differs from the report. Preserve source topology when it
  helps; add a typed editorial reading path only when it adds value.
- A failed build names the invalid source. Fix that source; do not weaken generator
  validation.
- Reuse `reading-site.css` through `--context`, the structure-provenance binding
  through `--filter`, and `reading-nav` through `--component`. A consumer owns no
  forked shared assets.
- Write `nav-manifest.js` after the build because the generated `site/assets/`
  directory does not exist before it.

## Whole-source consistency sweep

After every report page and `src/index.md` exist, but **before the build**, apply
[[explainer-reading-site-consistency-sweep]] once to the complete `src/*.md` set.
Pass all absolute source paths, the canonical conventions above, the canonical
source-structure artifact, and the fixed Phase 1 profile, plus the site title and
consumer landing vocabulary. Use one isolated sweep worker when the host supports
it; otherwise apply the procedure inline.

The sweep returns findings only. Apply each fix surgically to `src/`, then rerun the
sweep until it reports clean. Do not build first: the point of this fan-in gate is to
catch legal-but-wrong Markdown such as bare `[p31]` before it becomes internally
consistent but site-wide divergent HTML. A later source correction therefore needs
only the final one-pass build; never patch `site/` and never preserve generated
assets by hand across rebuilds.

## Success checklist

- [ ] Every existing `reports/*.md` has `src/<slug>.md` and
      `site/<slug>.html`.
- [ ] `src/index.md` generated `site/index.html`, contains one composed card per
      report, and uses overview as the hero CTA and first page.
- [ ] No `index.html` template or hand-authored `ol.cards` exists; the landing uses
      `.card-grid filter=`.
- [ ] Page order and kickers exactly match the consumer profile.
- [ ] Every report source contains a lede and keypoints box.
- [ ] Every flowing-body H2/H3 is typed as `.source-structure` or
      `.editorial-structure`; source headings agree with the canonical structure
      artifact, and editorial headings use no source-like structural label.
- [ ] Pages with editorial headings contain localized
      `editorial-structure-label` and `editorial-structure-note` frontmatter; the
      values exactly match the canonical site-wide strings; the
      generated article shows the subdued disclosure and every editorial heading
      marker, and the sidebar contains the same marker text.
- [ ] Every prose source-page reference uses `[pNN]{.p}` or
      `[pNN–pMM]{.p}`; none appears in a heading, and sentence punctuation follows
      the anchor. Code, image alt text, and table-header placeholders were left
      alone.
- [ ] The whole-source consistency sweep read every `src/*.md`, all findings were
      fixed, and its final result was clean before the build ran.
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
