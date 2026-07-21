# `reading-nav` component — reading-site navigation widgets

A **Tier 2 opt-in component** of the understanding-html-docs design system (see
`docs/components.md`). Include it in a **multi-page reading site** (a landing/index
page plus report pages, as pdf-studio / paper-studio generate) to add two runtime
navigation aids on top of `base.js`:

1. **An index live filter** — a search box inserted above whichever element the
   consumer marks `data-reading-filter`; typing hides its non-matching children.
   No-op if no element is marked.
2. **Manifest-driven page-to-page navigation** — prev/next links at the foot of a
   report page, plus an all-pages FAB drawer listing every page (current
   highlighted). Both are driven by one per-site data file (see *Markup contract*).

Like `comments`, this is **injected chrome with no authored markup** and **no
third-party engine** (vanilla JS/CSS, offline). It is Tier 2 because multi-page
navigation is a mode not every document wants — a single-page document (e.g. an
[[understanding-explain-diff]] page) never loads it.

**Document-type-neutral.** The widget hardcodes no chapter/section/book vocabulary:
the filter wording is generic ("絞り込む…" / "一致する項目がありません。"), and the
prev/next / all-pages labels come from the per-site manifest data the consumer
authors — not from the JS. This is what lets one bundle serve a pdf book (chapters),
a paper (perspectives), or any other multi-page reading site unchanged.

## Files

- `reading-nav.css` — the widget chrome: the filter input + empty state, the
  prev/next `.chapnav`, and the all-pages drawer (`.pagenav-panel` / `-backdrop`)
  and its list FAB (`.pages-btn`). All colors come from the base tokens.
- `reading-nav.js` — the behavior: the `data-reading-filter` index filter, and the
  page-nav that reads `window.__HTMLDOCS_NAV`, renders prev/next, and mounts an
  all-pages drawer into base.js's `.fab` stack.

## How to include

This is a **copy-mode component** (multi-page sites). Two steps:

1. **Copy the bundle in** — pass `--component reading-nav` to the generator
   (`build-site.sh` / `build.sh`). It copies `reading-nav.css` / `reading-nav.js`
   into the site's `assets/` next to `base.css` / `base.js`:

   ```bash
   scripts/build-site.sh <src-dir> <out-dir> \
     --assets <understanding-html-docs/assets> \
     --context <consumer-context-dir> \
     --component reading-nav
   ```

2. **Opt each page in** — reference the two files from the page frontmatter, so they
   are emitted after `base.css` / `base.js` in the fixed asset order:

   ```yaml
   context-css:
     - reading-nav.css        # (alongside any consumer content stylesheet)
   context-js:
     - nav-manifest.js        # the page-nav DATA — must load before the script
     - reading-nav.js         #   that reads it
   ```

   A hand-authored landing page (not run through the generator) links them directly:
   `<link rel="stylesheet" href="assets/reading-nav.css">` and
   `<script src="assets/reading-nav.js" defer></script>` (after `base.js` and after
   `nav-manifest.js`).

Load `reading-nav.js` **after** `base.js`: on init the all-pages button mounts into
base.js's `.fab` if it exists (so the list, ☰ TOC, and ↑ buttons share one column).
Two `defer` scripts run in document order, so listing `base.js` first is enough.

## Markup contract

- **Filter:** enhances the element the consumer marks with a `data-reading-filter`
  attribute (the component assumes no class name of its own). Its direct children are
  the filterable items; a non-match gets the component's `.rn-hidden` class. The
  attribute's **value, if any, is the placeholder text** (e.g.
  `data-reading-filter="レポートを絞り込む…"`); an empty attribute uses the neutral
  default "絞り込む…". The index markup and styling are the **consumer's**; this
  component owns only the filter input, the empty-state line, and the `.rn-hidden`
  rule. No marked element → the filter is a silent no-op.

  ```html
  <ol class="cards" data-reading-filter>…</ol>   <!-- neutral default placeholder -->
  ```
- **Page nav:** reads the per-site data global `window.__HTMLDOCS_NAV`, assigned by a
  `nav-manifest.js` the **consumer authors** and loads as a `context-js` entry before
  `reading-nav.js`. Shape:

  ```js
  window.__HTMLDOCS_NAV = {
    pages: [
      { slug: "overview", href: "overview.html", kicker: "<label>", title: "<title>" }
      // one entry per report page, in reading order; the landing page is NOT listed
    ]
  };
  ```

  `href` = the page basename; `kicker` = the compact neighbor label shown in
  prev/next and the drawer (consumer vocabulary — a chapter number, a perspective
  name, …); `title` = the fallback label. Missing manifest (e.g. the landing/library
  index) → the page nav is a no-op, so the same bundle is safe to ship on every page.

The nav **data** (which pages, order, labels) stays the consumer's; this component
owns only the nav **mechanism**.

## What this component owns vs. the consumer

This component owns the filter mechanism, the page-nav rendering, the drawer, and
all the widget chrome. The consumer owns the index markup it marks with
`data-reading-filter` (and its styling), and authors the `nav-manifest.js` data.
Including the two files (via `--component` + frontmatter) is the whole integration;
there is no vocabulary a document author must learn.
