---
name: understanding-html-docs
description: Shared resources for skills that explain something as a self-contained HTML document — the design system (typography, a two-layer semantic/categorical color model, callouts, chips), the progressive-enhancement kit (theme toggle, reading progress, table of contents, back-to-top), and the authoring principles that keep the output deployable as static HTML. Other skills delegate to this skill to copy the base assets and follow the color/PE conventions, then layer their own context-specific markup on top. Use this skill when another skill asks to apply the understanding-html-docs design system or copy its base assets. Not typically invoked on its own.
---

# understanding-html-docs — shared HTML explanation-document resources

This skill owns the resources shared across skills that render an **explanation as
a browsable web document** — [[understanding-explain-diff]] (a diff explained to a
reviewer), pdf-studio's generate-site (reports as a reading site), and future
skills of the same shape. It exists so each such skill inherits one design
language and one interaction kit instead of re-deriving them.

The idea:

> An explanation web document is a **foundation + a semantic design system + a
> progressive-enhancement kit**, plus a context layer the consuming skill owns.
> The first three are here; the context layer (what the document is *about*, and
> any heavy third-party libraries it needs) stays in the consuming skill.

Consuming skills copy the two asset files verbatim and add their own stylesheet
and markup — they never edit these files per document.

## Assets

Both live under this skill's `assets/` (resolve relative to this skill's installed
directory):

- **`base.css`** — the design system: foundation (reset, typography, layout,
  base elements, tables), the color model, callouts, pullquote, chips, and the
  styles the PE kit toggles.
- **`base.js`** — the progressive-enhancement kit: theme toggle (auto/light/dark),
  reading-progress bar, table of contents with scroll-spy, and back-to-top. All
  vanilla, no dependencies, no network. Every feature degrades to nothing if the
  script never loads.

## Principles

- **Self-contained and static-deployable.** The output is one or more HTML files
  that open with no server. `base.css`/`base.js` are local files with no network
  dependency — copy them next to the HTML, never hot-link them.
- **Base owns design; the consuming skill owns content.** This base is an
  *opt-in component library* — it owns the visual language, the interaction kit,
  and the wiring of any rendering engine a document needs (including a diagram
  engine's palette hook); a consuming skill defines only what the document says
  and what it means (e.g. a domain-specific risk axis). The full rationale — the
  three-tier component model (foundation / pure-CSS UI + PE kit / heavy opt-in
  components) and the promotion criterion — is recorded in the design ADR
  `docs/2026-07-10-html-docs-component-library-design.md` (my-agent-skills repo).
  *(Heavy renderers such as diff2html/mermaid still live in the consumer's markup
  today; moving them into base opt-in components under `assets/components/` is
  tracked as follow-up implementation.)*
- **The substrate is offline; heavy components assume an online viewer.** The
  foundation, color model, and PE kit (`base.css`/`base.js`) render with no
  network — copy them next to the HTML, never hot-link them. A heavy component
  that renders via a third-party engine (a diff renderer, a diagram engine) pulls
  it version-pinned from a CDN by default (vendoring is the offline opt-in); only
  that rendering needs the network. The base substrate itself stays CDN-free.
- **Color carries one meaning.** The model is two disjoint layers — never blur
  them, and never introduce a third ad-hoc color; prefer prose over a new hue.
  - **Semantic** (meaning): callout variants (`note`/`tip`/`warn`/`danger`/`key`)
    and inline `<mark>` map a fixed hue to a fixed meaning. A consuming skill may
    define *additional* semantic axes in its own stylesheet (e.g. a risk axis),
    but each hue still means exactly one thing across the whole document.
  - **Categorical** (wayfinding): a `hue-N` class tints `--cat`/`--cat-soft` for
    sections/chapters/documents, so "where am I" is answerable by color. It falls
    back to the global accent when unset. Interactive color (links) stays the
    single global accent.
- **Progressive enhancement, not dependence.** Everything `base.js` adds is a
  layer on top of a page that already reads correctly. Author the semantic HTML
  first; let the kit enrich it.

## Consuming this base

There are two consumption modes; pick by the output shape:

- **Copy mode** (multi-page sites): copy `base.css`/`base.js` into a shared
  `assets/` directory and `<link>`/`<script src>` them from every page. One
  stylesheet serves the whole site. This is the default; steps below describe it.
- **Inline mode** (a single self-contained file): paste `base.css` into a
  `<style>` element and, if the DOM fits the kit, `base.js` into a `<script>`.
  Use this when the output must stay one portable file (e.g. it is published or
  emailed as a lone `.html`). The base stays the source of truth — the file is
  re-inlined on each regeneration; never hand-tune the inlined copy.

A copy-mode generation step should:

1. Copy `assets/base.css` and `assets/base.js` (from this skill's installed
   directory) into the output's `assets/` directory.
2. Add its own context stylesheet next to them and link both from each page,
   base first:
   ```html
   <link rel="stylesheet" href="assets/base.css">
   <link rel="stylesheet" href="assets/<context>.css">
   ```
3. Put the **theme boot snippet** inline in `<head>` (before first paint, so the
   saved theme applies with no flash), and load `base.js` deferred. The boot
   snippet's storage key must match `base.js`'s `THEME_KEY`:
   ```html
   <script>try{var t=localStorage.getItem('html-docs-theme');if(t==='dark')document.documentElement.classList.add('theme-dark');else if(t==='light')document.documentElement.classList.add('theme-light');}catch(e){}</script>
   <script src="assets/base.js" defer></script>
   ```
4. Give the page the semantic structure `base.js` wires from: a `header.site`
   (where the theme button mounts), a `main article`, and `h2`/`h3` section
   headings (the TOC and reading-progress build on these). A page with fewer than
   two `h2`s simply gets no TOC.
5. Author context markup using the class catalog below plus its own classes.

## Class catalog (base.css)

Foundation is automatic from element selectors (`body`, `main`, `h1`–`h3`, `p`,
`blockquote`, `code`, `pre`, `mark`, `footer`). Named components:

| Class | Purpose |
|-------|---------|
| `header.site` | Sticky top bar; the theme button mounts here |
| `.callout` | Semantic message box (base = note/info) |
| `.callout.tip` / `.warn` / `.danger` / `.key` | Meaning + color + icon variants |
| `.callout .label` | Bold colored lead-in inside a callout |
| `.pullquote` | Emphatic single line; quote marks in the categorical hue |
| `.chip` | Small muted label; `.chip.accent` for an accented one |
| `.tablewrap` > `table` | Horizontally scrollable table wrapper |
| `.hue-1` … `.hue-6` | Categorical hue (sets `--cat`/`--cat-soft`) |

PE classes (`.progress`, `.theme-btn`, `.fab`, `.toc-backdrop`, `.toc-panel`) are
injected/toggled by `base.js`; author markup does not use them directly.

## Gotchas

- **Copy, don't reference.** The assets must be copied into each output so the
  document stays self-contained. Never link to this skill's install path.
- **Keep the two color layers disjoint.** If a consumer adds a semantic axis, it
  must not reuse a categorical `hue-N` color or the global accent for it, and vice
  versa — overlapping hues destroy the "color = one meaning" signal.
- **Boot key must match.** If the inline `<head>` snippet's storage key drifts
  from `base.js`'s `THEME_KEY`, the saved theme silently stops applying and the
  page flashes on load.
- **`base.js` targets `main article`.** Its reading-progress bar and TOC assume
  the document body is one `main > article`. A page that instead puts several
  `article` elements directly under `main` will mis-target the first one — such a
  consumer should either wrap its content in a single outer `article` or skip
  `base.js` and keep its own scripts (`base.css`'s auto light/dark still works
  without any JS). `understanding-explain-diff` takes the latter route.
