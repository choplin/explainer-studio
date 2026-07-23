# Markup, review, and component contract

Read this reference completely when reviewing output, selecting Tier 2 components,
or changing the design system.

## Review ownership

There is no general generated-document review pass or class linter.

The errors that matter are often well-formed: a green `.callout.tip` around a hazard
renders correctly while saying the opposite of the truth. Generation therefore
splits review into two parts:

- The **mechanical half** is absorbed by the generator. Unknown variants fail, raw
  HTML is dropped, tables are wrapped, and template wiring is generated.
- The **semantic half** remains a reading judgment. Low-stakes PDF/Paper reading
  sites skip a standalone semantic review by policy. A consumer with high-stakes
  axes internalizes the check into its own completion criteria, as
  [[explainer-diff]] does for `risk`, `tested`, and `verified`.

A general reviewer cannot validate consumer-specific axes it does not own.

## Meaning → generated element/class

This is the generator's allowlist and the canonical vocabulary for discussing
generated markup. Authors still use the notation in
[`authoring-contract.md`](authoring-contract.md), not these classes directly.

Foundation uses elements without opt-in classes: `main > article`, `header.site`,
`footer`, `h1`, `h2`, `h3`, `p`, `ul`, `ol`, `table` inside `.tablewrap`, `code`,
`pre > code`, `blockquote`, `hr`, `mark`, `a`, and `figure > img + figcaption`.
Media is clamped to the reading column and never scaled past natural size.

| Meaning | Generated class |
|---|---|
| Supporting information | `.callout` |
| Advice | `.callout.tip` |
| Caution | `.callout.warn` |
| Hazard | `.callout.danger` |
| Key insight | `.callout.key` |
| Callout lead-in | `.callout .label` |
| Section takeaway | `.keypoints` |
| Louder line / eyebrow / opening paragraph | `.pullquote` / `.kicker` / `.lede` |
| Bordered peer blocks | `.card` / `.card-grid` |
| Filter target | `data-reading-filter` on `.card-grid` |
| Small labels | `.chip`, `.chip.accent`, `.badge` |
| Quiet remark | `.aside` |
| Scrollable table | `.tablewrap > table` |

`base.js` injects `.progress`, `.theme-btn`, `.fab`, `.toc-btn`, `.toc-backdrop`,
and `.toc-panel`; never author them.

The comments bundle injects `.comments-panel`, `.comments-backdrop`, `.comments-fab`,
`.comments-composer`, `.comments-cmenu`, `.comments-selbtn`, `.comment-card`,
`.comment-anchored`, and descendants.

The reading-nav bundle injects `.filter`, `.filter-empty`, `.chapnav`,
`.pagenav-panel`, `.pagenav-backdrop`, `.pages-btn`, and `.rn-hidden`. It enhances
an index marked with `data-reading-filter`; the index markup remains consumer-owned.

Forbidden output includes an undefined class, a raw color in a style attribute, a
component rule reading primitive tokens such as `--n-*` or `--blue-strong`, a table
outside `.tablewrap`, a meaning color used decoratively, an ad-hoc hue, or a Tier 2
marker without its bundle.

## Tier 2 opt-in components

Each bundle lives under `assets/components/<name>/` and ships only when selected:

| Component | Purpose | Third-party engine |
|---|---|---|
| `highlight` | Highlight `pre code` blocks | highlight.js v11 |
| `diff` | Render `pre.diff-source` + `div.diff-render` pairs | diff2html v3 |
| `diagram` | Render `pre.mermaid` | mermaid v11 |
| `comments` | Browser-side local review, exportable as JSON/Markdown | None |
| `reading-nav` | Card filter, prev/next, and all-pages drawer from a nav manifest | None |

Every bundle has an `include.md` that is the source of truth for its version-pinned
CDN tags, markup, ordering, escaping, and validity rules. Follow it for both copy and
inline mode.

`comments` has no authored markup and no third-party engine. It remains Tier 2 because
commenting is an optional document mode. It is independent of `base.js` and scopes
itself to `main`.

## Changing or adding a component

Before editing, read [`../docs/components.md`](../docs/components.md) completely.
That document defines the tier model, ownership, promotion criterion, review surface,
and where the model deliberately stops.

A component change must keep these artifacts aligned:

1. CSS/JS in `base.css`, `base.js`, or a Tier 2 bundle.
2. A semantic binding in `filters/htmldocs.lua` when the vocabulary is not already
   expressible.
3. Its authoring notation in `authoring-contract.md`.
4. Its meaning→markup entry in this reference.
5. A demonstration in the reference site's `src/` and regenerated `site/`.
6. For Tier 2, the bundle's `include.md`.

A class missing from the meaning→markup index must not become authorable.

## Operational gotchas

- Copy assets into output; never reference the installed skill directory.
- Keep the theme-boot storage key in `template.html` aligned with `base.js`'
  `THEME_KEY`, or the saved theme flashes and silently stops applying.
- `base.js` targets the first `main article`. A multi-article page must omit it and
  supply its own scripts/template, as [[explainer-diff]] does.
- The generator catches structural vocabulary errors, not semantic
  misclassification. Apply the review ownership above.
- The substrate is offline; heavy CDN-backed renderers require an online viewer
  unless the consumer explicitly vendors them.
