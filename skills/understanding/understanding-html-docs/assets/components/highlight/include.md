# `highlight` component — syntax-highlight code blocks with highlight.js

A **Tier 2 opt-in component** of the understanding-html-docs design system (see
`docs/2026-07-10-html-docs-component-library-design.md`). Include it only in a
document whose code blocks should be colorized — a consumer that needs no
highlighting never copies this folder and never loads highlight.js.

**Third-party engine:** [highlight.js](https://highlightjs.org/) v11, loaded from
a CDN. This component **assumes an online viewer** for the highlighting — the base
substrate (base.css/base.js) still works offline, and unhighlighted code is fully
readable on the base `pre`/`code` styling; only the token coloring here needs the
network. To run fully offline, vendor the highlight.js bundle locally and point
the tag below at it (the offline opt-in).

## Files

- `highlight.css` — a GitHub-flavored token theme authored as `light-dark()`
  pairs, so it follows the document theme with no JS and no second stylesheet.
  Colors only: it never sets a background or padding on `.hljs`, so the code
  panel (background, border, monospace) stays owned by `base.css`.
- `highlight.js` — highlights every `<pre><code>` on load (`hljs.highlightAll`).

## How to include

Copy-mode (multi-page site — files linked next to `base.css`):

```html
<!-- in <head>, after base.css -->
<script src="https://cdn.jsdelivr.net/npm/@highlightjs/cdn-assets@11/highlight.min.js" defer></script>
<link rel="stylesheet" href="assets/highlight.css">
<!-- at the end of <body> (or deferred in <head>) -->
<script src="assets/highlight.js" defer></script>
```

Load order matters: the highlight.js bundle must define the global `hljs` before
`highlight.js` runs. Two `defer` scripts execute in document order, so listing
the CDN bundle first is enough.

Inline-mode (single self-contained file): keep the highlight.js CDN tag in
`<head>`, paste the contents of `highlight.css` into a `<style>` block after the
base stylesheet, and paste `highlight.js` into a `<script>` at the end of
`<body>`. Only the highlight.js engine stays external.

The tag uses the `@11` major range (exact pinning is not required here); vendor
the bundle locally if you need the offline opt-in.

## Markup contract

The base markup is unchanged — one `<pre><code>` per block:

```html
<pre><code class="language-ts">const x: number = 1;</code></pre>
```

- **Language is optional.** With no class, highlight.js auto-detects. Add
  `class="language-xxx"` to force a language (more reliable for short snippets).
- **Opt a block out** with `class="nohighlight"` (or `no-highlight`, or
  `language-plaintext`) on the `<code>` — it keeps the plain base treatment.
- **HTML-escape the code** (`&`→`&amp;`, `<`→`&lt;`, `>`→`&gt;`) exactly as for any
  `<pre><code>`. highlight.js reads `textContent`, so escaping never corrupts the
  highlighted output, and unescaped `<…>` would otherwise be parsed as markup.

## What this component owns vs. the consumer

This component owns *how code is colorized* (the engine, the token theme, the
load wiring). The consumer owns *which* code to show and the prose around it. The
token palette is the design system's own light/dark theme, not a page-level color
axis — it never collides with the semantic/categorical layers, which carry
meaning elsewhere in the document.
