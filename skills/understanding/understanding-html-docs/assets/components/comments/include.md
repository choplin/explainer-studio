# `comments` component — a browser-side review layer (Google-Docs-style)

A **Tier 2 opt-in component** of the understanding-html-docs design system (see
`docs/components.md`). Include it in a document that a reader should be able to
**comment on in the browser**: select text (or right-click a block), write a
comment, and see every comment in a list panel in the right gutter — the same
mental model as commenting in Google Docs.

The link between the body and the panel is two-way: clicking a **comment card**
scrolls the document to its anchor, and clicking a **highlighted location in the
body** focuses the matching card in the panel. Editing happens **inline in the
card** (the body text becomes a textarea in place; ⌘/Ctrl+Enter saves, Esc
cancels) — not in a floating popup.

**No third-party engine, fully offline.** Unlike `highlight`/`diff`/`diagram`,
this component pulls nothing from a CDN — it is vanilla JS/CSS with no network
dependency, so it works over `file://` and offline. It is Tier 2 (opt-in, not in
the base) only because commenting is a mode not every document wants, not because
it needs an online viewer.

**Independent of `base.js`.** The anchor scope is `main` (not `main article`), so
it works both on a base.js reading page (one `main article`) and on an
understanding-explain-diff page (several `article.chunk` under `main`, no
`base.js`). Load it alongside `base.js` or on its own.

## Files

- `comments.css` — the review chrome: the right-gutter list panel (a slide-in
  overlay on narrow screens, a persistent column in the right gutter on wide
  screens, mirroring base.js's left-gutter TOC), the composer popup, the
  right-click menu, the selection button, and the anchor highlight. All colors
  come from the base tokens (`--accent`, `--card`, `--line`, …) so it follows the
  document theme. Nothing here carries a semantic meaning-color — comments are
  interaction chrome, not part of the document's meaning.
- `comments.js` — the behavior: selection/right-click capture, the composer,
  localStorage persistence (keyed per document), re-anchoring on load, and
  JSON/Markdown export & JSON import.

## How to include

Copy-mode (multi-page site — files linked next to `base.css`):

```html
<!-- in <head>, after base.css -->
<link rel="stylesheet" href="assets/comments.css">
<!-- at the end of <body> (or deferred in <head>, after base.js) -->
<script src="assets/comments.js" defer></script>
```

Inline-mode (single self-contained file, e.g. understanding-explain-diff): paste
`comments.css` into a `<style>` after the base stylesheet and `comments.js` into
a `<script>` at the end of `<body>`. Nothing stays external.

Load `comments.js` **after** `base.js` when both are present: on init the toggle
button mounts into base.js's `.fab` stack if it already exists (so the 💬 toggle
and the ☰ TOC button share one column on narrow screens); with `base.js` absent
or not yet run, it creates its own standalone toggle. Two `defer` scripts run in
document order, so listing `base.js` first is enough.

### Where the list panel sits (overlay vs. pinned gutter)

By default the list panel is a **slide-in overlay** opened by the 💬 toggle —
safe at any width, it never overlaps the content. This is the right choice for a
wide document (e.g. understanding-explain-diff's ~1080px column), where there is
no room for a permanent side column.

To **pin the list in the right gutter** (always visible, Google-Docs-style, the
mirror of base.js's left TOC), add `class="comments-gutter"` to `<html>`. The
gutter geometry assumes a ~48rem main column and pins at the 79rem breakpoint,
just like the TOC. If your main column is wider than 48rem, set
`--comments-doc-width` to its `max-width` so the offset tracks it — but note a
wider column only clears gutter room on a wider viewport, so either raise the
79rem breakpoint in your own stylesheet or leave the class off and use the
overlay. Below the breakpoint (or with the class absent) the overlay + 💬 toggle
is always the fallback.

## Markup contract

**There is none to author.** Comments are created by the reader at runtime; the
component reads the document's existing semantic markup and needs no wrapper
elements, no data attributes, and no classes on the content. It attaches to a
page that already reads correctly (progressive enhancement) and injects all of
its own UI. This is the one Tier 2 component with an empty markup contract.

Two optional hooks:

- **`<meta name="comments-doc-id" content="…">`** in `<head>` pins the
  localStorage key for the document. Without it the key derives from
  `location.pathname` + `document.title` — fine for a file opened in place, but
  set an explicit id if the same document is served from more than one path (or
  its title changes) and comments must follow it.
- **Stable ids / `data-chunk-id`** already on blocks make anchors survive
  regeneration better (see below). Nothing to add for comments specifically —
  the anchoring just uses them when present.

## How anchoring works (and its limits)

- **Text comments** store a text quote (the exact string plus ~32 chars of
  prefix/suffix to disambiguate repeats) relative to the nearest block, and a
  structural CSS selector to that block. On load the block is re-found by
  selector and the quote is re-located inside it, then painted with the **CSS
  Custom Highlight API** — so the document DOM is **never mutated** (no wrapper
  `<mark>`; the diff/selection/anchoring of the underlying content is untouched).
  Browsers without the Highlight API fall back to a quiet accent rail on the
  block.
- **Block comments** (right-click with no selection) store just the block
  selector and mark the whole block with the accent rail.
- **Orphaned comments** — if a document is regenerated and a block's structural
  position or quoted text changes, a comment may not re-anchor. It is **not
  lost**: it still shows in the panel, flagged "対象が見つかりません", and stays in
  storage and in exports. Anchors are most durable on content with stable `id`s
  or `data-chunk-id`s; purely positional anchors (`p:nth-of-type(n)`) drift if
  earlier siblings are inserted or removed.

## Persistence, round-trip, and privacy

- Comments live in **`localStorage`**, keyed `html-docs-comments:<doc-id>`, so
  they persist across reloads **in that browser only**. They are not written back
  into the HTML file and are not shared between viewers automatically.
- To move comments off one machine, use the panel's toolbar. Export **shows the
  text in a copy panel** (pre-selected, with a copy button) rather than
  downloading a file — so it works everywhere, including a sandboxed Artifact
  iframe, and is quicker to paste onward. Two formats:
  **⤓{} JSON** (round-trip) and **⤓md Markdown** (a readable list — quote, body,
  resolved-state, anchor selector — for a human author or an agent to act on).
  Import is the mirror image: **⤒** opens a paste panel — paste an exported JSON
  and it is merged in, deduped by id (no file picker, to match the copy flow).
- Because storage is per-browser and local, nothing here transmits comment text
  anywhere. A reviewer copies their JSON/Markdown export and sends it to the
  author out of band; the author (or an agent) imports or reads it.

## What this component owns vs. the consumer

This component owns *the entire commenting mechanism* — the interaction, the
anchoring, the storage, the panel, the export format. The consumer owns only the
document being commented on and the decision to include the component at all.
Unlike the semantic layer, comments add no vocabulary a document author must
learn: including the two files is the whole integration.
