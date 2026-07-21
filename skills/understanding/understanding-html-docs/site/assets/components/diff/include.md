# `diff` component — render git diffs with diff2html

A **Tier 2 opt-in component** of the understanding-html-docs design system (see
`docs/components.md`). Include it only in a
document that shows diffs — a consumer that renders no diffs never copies this
folder and never loads diff2html.

**Third-party engine:** [diff2html](https://github.com/rtfpessoa/diff2html) v3,
loaded from a CDN. This component **assumes an online viewer** for the diff
rendering — the base substrate (base.css/base.js) still works offline; only the
diff view here needs the network. To run fully offline, vendor the two diff2html
files locally and point the tags below at them (the offline opt-in).

## Files

- `diff.css` — presentation tweaks that make diff2html sit correctly on top of
  `base.css` (which styles all tables). Layout-only; does not touch diff row
  colors.
- `diff.js` — renders each diff pair and wires the format toggle.

## How to include

Copy-mode (multi-page site — files linked next to `base.css`):

```html
<!-- in <head>, after base.css -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/diff2html@3/bundles/css/diff2html.min.css">
<script src="https://cdn.jsdelivr.net/npm/diff2html@3/bundles/js/diff2html-ui.min.js"></script>
<link rel="stylesheet" href="assets/diff.css">
<!-- at the end of <body> -->
<script src="assets/diff.js"></script>
```

Inline-mode (single self-contained file, e.g. explain-diff): keep the two
diff2html CDN tags in `<head>`, paste the contents of `diff.css` into a
`<style>` block after the base stylesheet, and paste the contents of `diff.js`
into a `<script>` at the end of `<body>`. Only diff2html stays external.

The tags use the `@3` major range (exact pinning is not required here); vendor
the files locally if you need the offline opt-in.

## Markup contract

For each diff, emit a hidden `<pre class="diff-source">` holding a **valid unified
diff**, immediately followed by an empty `<div class="diff-render">`:

```html
<pre class="diff-source" hidden>diff --git a/src/foo.ts b/src/foo.ts
--- a/src/foo.ts
+++ b/src/foo.ts
@@ -10,6 +10,8 @@ function process()
 context line (HTML-escaped: List&lt;Foo&gt;)
-removed line
+added line</pre>
<div class="diff-render"></div>
```

Optional format toggle (renders once; the buttons re-render in the chosen mode):

```html
<p class="diff-format-toggle" role="group">
  <button type="button" data-diff-format="line-by-line">Unified</button>
  <button type="button" data-diff-format="side-by-side">Side by side</button>
</p>
```

## Rules the renderer depends on

- **HTML-escape all diff content** (`&`→`&amp;`, `<`→`&lt;`, `>`→`&gt;`) inside
  `pre.diff-source`. Raw generics (`List<Foo>`) or `->` arrows otherwise swallow
  the rest of the document. The browser un-escapes `textContent` before diff2html
  parses it, so escaping never corrupts the rendered diff.
- **Keep every excerpt a parseable unified diff.** diff2html renders nothing (or
  a broken view) on malformed input. When shortening, drop *whole hunks* — never
  delete lines inside a hunk (it invalidates the `@@` line counts). Always retain
  the `diff --git` / `---` / `+++` file headers so file names appear.
- Each `pre.diff-source` must be **immediately** followed by its
  `div.diff-render` (the script pairs them by `previousElementSibling`).

## What this component owns vs. the consumer

This component owns *how a diff renders* (the engine, the tweaks, these rules).
The consumer owns *which* diffs to show and the prose around them. It does not
impose any page-level color axis — diff2html's own red/green stays inside the
collapsed viewer and is not a document-level color system.
