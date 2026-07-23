# Authoring and generation contract

Read this reference completely before authoring semantic Markdown or running the
generator.

## Semantic Markdown frontmatter

Frontmatter carries page chrome and asset selection:

```yaml
---
title: Page title — Site name
site-name: explainer-html-docs
context-css: color.css
# context-css:
#   - reading-site.css
context-js:
#   - nav-manifest.js
#   - reading-nav.js
back-link: "← Back to the index"
---
```

`context-css` and `context-js` each accept one value or a YAML list. A scalar is a
one-element list. Asset order is fixed:

1. `base.css`
2. `context-css[]`
3. `base.js`
4. `context-js[]`

`build.sh --context <dir>` copies every flat `*.css` and `*.js` file from that
consumer-owned directory into the output `assets/` directory.

## Base authoring vocabulary

| To express | Author |
|---|---|
| General information | `::: {.callout}` … `:::` |
| Advice, caution, hazard, key insight | `::: {.callout variant=tip\|warn\|danger\|key}` |
| Bold lead-in inside a callout | `[Label]{.label}` at the paragraph start |
| Section takeaway | `::: {.keypoints}` with `### Title` and a list |
| Grid of peers | `:::: {.card-grid}` around `::: {.card}` blocks |
| Filterable card index with reading-nav | `:::: {.card-grid filter="絞り込む…"}` |
| Outlined / accented / filled label | `[text]{.chip}` / `[text]{.chip .accent}` / `[text]{.badge}` |
| Opening paragraph / eyebrow / louder line | `::: {.lede}` / `::: {.kicker}` / `::: {.pullquote}` |
| Quiet remark | `::: {.aside}` |
| Highlighted phrase | `[text]{.mark}` |
| Tabular data | Plain Markdown table; wrapping is automatic |
| Figure | A Markdown image with meaningful alternative text and a caption |
| Code sample that must not be highlighted | A fenced block with `.nohighlight` |
| Headings, prose, lists, quotes, links, code, rules | Plain Markdown |

The generator enforces these rules:

- `variant=` is `tip`, `warn`, `danger`, `key`, or omitted for the note variant.
  `warning`, `error`, typos, and other values fail the build.
- Every table is wrapped in `.tablewrap`; never author that wrapper.
- Author figures with meaningful alternative text and a `figcaption`; never emit a
  bare image or use an empty/decorative alt for explanatory content.
- Raw HTML is disabled, so invented classes, inline colors, and hand-written
  structural markup are not passed through.

## Consumer-specific vocabulary

A consumer adding semantic components supplies:

1. A context stylesheet selected through `context-css`.
2. A consumer Lua filter passed with `--filter`, chained after `htmldocs.lua`.
3. Only when the page skeleton differs, a template variant passed with `--template`.

Use the `ramp` / `swatch` rules in `filters/htmldocs.lua` and
[[explainer-diff]]'s filter/template as worked examples. Base and consumer filters
run in one Lua-filter chain, so their vocabularies compose.

The PDF reading-site consumer also uses:

| To express | Author | Emits |
|---|---|---|
| Source-page anchor | `[p31]{.p}` | `<span class="p">p31</span>` |
| Audio player | `::: {.player src=audio/ch-1.m4a}` … `:::`; optional `label=` | `.player` containing a label and native `<audio>` |
| Harvested figure | `![caption](../ocr/figures/fig-p031-1.jpg)` | An image whose source is rewritten to `figures/fig-p031-1.jpg` |

A `.player` without `src=` fails generation. The reading-nav widget is a Tier 2
component; its per-site data is a consumer-authored `nav-manifest.js` assigning
`window.__HTMLDOCS_NAV`, loaded before `reading-nav.js`.

## Commands

Pandoc is resolved by preflight in this order: PATH, bundled `nix develop`, then
failure.

Build one page:

```bash
scripts/build.sh <src.md> <out-dir> \
  --assets <explainer-html-docs/assets> \
  [--context <dir>] [--component <name>]... \
  [--template <consumer-template>] [--filter <consumer-filter.lua>]... [--inline]
```

Default copy mode copies `base.css`, `base.js`, flat context CSS/JS, and selected
component bundles into `<out-dir>/assets/`. `--inline` folds local assets into the
page and removes the asset directory; version-pinned remote engines remain external.

`--component <name>` is repeatable. It copies flat CSS/JS from
`assets/components/<name>/` into the output. The page must still list the copied
files in its `context-css` / `context-js` frontmatter. `--context` copies only the
consumer's flat asset directory, never the nested component tree.

Build a whole site:

```bash
scripts/build-site.sh <src-dir> <out-dir> \
  --assets <explainer-html-docs/assets> [--context <dir>] [--component <name>]...
```

Each `src/*.md` becomes `out/<name>.html` and all pages share one asset set.

## What generation guarantees

Generation guarantees:

- correct head, theme boot, and asset order;
- hard failure for unknown base variants;
- no raw HTML, invented base class, or inline style from the source;
- `.tablewrap` around every table;
- deterministic figure-path rewriting.

Generation cannot decide whether content was classified correctly. Whether a passage
is a hazard, a tip, or the key point remains an authoring judgment. Review ownership
for that semantic half is defined in
[`markup-and-components.md`](markup-and-components.md).
