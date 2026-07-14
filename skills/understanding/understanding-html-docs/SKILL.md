---
name: understanding-html-docs
description: Shared resources for skills that explain something as a self-contained HTML document — the design system (typography, a meaning-only color model, callouts, chips), the progressive-enhancement kit (theme toggle, reading progress, table of contents, back-to-top), and the authoring contract that keeps the output deployable as static HTML. Other skills delegate to this skill to copy the base assets and follow the color/PE conventions, then layer their own context-specific markup on top. Use this skill when another skill asks to apply the understanding-html-docs design system or copy its base assets. Not typically invoked on its own.
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

Consuming skills copy the asset files verbatim and add their own stylesheet and
markup — they never edit these files per document.

## The reference site is the contract

**The normative source is the reference site at this skill's root** — `index.html`
and the six pages it links. It is written in the design system it documents, so the
contract and the worked example are the same artifact and cannot drift apart. It is
also the living catalog — every component, in both themes — and the worked example a
generated document is reviewed against.

| Page | Covers |
|---|---|
| `index.html` | The two consumption modes, the skeleton, the page index |
| `foundation.html` | What works with no class: headings, prose, tables, code, quotes |
| `color.html` | The meaning-only color model and the token layers |
| `components.html` | The classes you opt into: callout, keypoints, card, chip, aside… |
| `enhancement.html` | What `base.js` adds, and the preconditions it needs |
| `tier2.html` | The opt-in bundles: highlight, diff, diagram |
| `contract.html` | The rules, and how a generated document is reviewed against them |

Serve it over HTTP (`python3 -m http.server`) — the diagram component is an ES
module and will not render over `file://`.

The table below is an index into that site, not a second source of truth. When the
two disagree, the site wins — it is the one written in the system it describes.

## Assets

Under this skill's `assets/` (resolve relative to this skill's installed
directory):

- **`base.css`** — the design system: foundation (reset, typography, layout,
  base elements, tables), the color model, callouts, pullquote, chips, and the
  Tier 1 reading-UI components (kicker, lede, keypoints, card/card-grid, badge,
  aside), plus the styles the PE kit toggles.
- **`base.js`** — the progressive-enhancement kit: theme toggle (auto/light/dark),
  reading-progress bar, table of contents with scroll-spy, and back-to-top. All
  vanilla, no dependencies, no network. Every feature degrades to nothing if the
  script never loads. The TOC is **responsive**: a bottom-sliding overlay panel
  (☰ FAB) on narrow screens, and a **persistent sidebar index** in the left
  gutter beside the article on wide screens (≥ 79rem) — same nav and scroll-spy,
  only the layout branches (in `base.css`, no logic duplicated).
- **`assets/components/<name>/`** — the Tier 2 opt-in bundles (see below).

At this skill's root, alongside the reference site:

- **`docs/components.md`** — the **design of the component system**: what a component
  is for, the rules that decide where one lives and who owns it, and where the model
  runs out. Not needed to *author* a document; read it before *changing the base*.

## Principles

- **Self-contained and static-deployable.** The output is one or more HTML files
  that open with no server. `base.css`/`base.js` are local files with no network
  dependency — copy them next to the HTML, never hot-link them.
- **Base owns design; the consuming skill owns content.** This base is an
  *opt-in component library* — it owns the visual language, the interaction kit,
  and the wiring of any rendering engine a document needs (including a diagram
  engine's palette hook); a consuming skill defines only what the document says
  and what it means (e.g. a domain-specific risk axis). The full rationale — the
  three-tier component model and the promotion criterion — is in
  [`docs/components.md`](docs/components.md). Heavy renderers (diff2html, mermaid,
  highlight.js) live in the base as opt-in components under `assets/components/`.
- **The substrate is offline; heavy components assume an online viewer.** The
  foundation, color model, and PE kit render with no network. A heavy component
  that renders via a third-party engine pulls it version-pinned from a CDN by
  default (vendoring is the offline opt-in); only that rendering needs the network.
- **Color carries meaning, and nothing else.** The semantic hues
  (`note`/`tip`/`warn`/`danger`/`key`, plus `<mark>`) each mean exactly one thing,
  and everything else that is colored — links, the progress bar, the TOC's current
  entry, `.keypoints` — takes the single global `--accent`. **Documents are not
  color-coded by position** (no per-chapter or per-section hue): a reader cannot
  tell "chapter 5 red" from "hazard red", so position-coding would destroy the very
  code the semantic colors rely on. "Where am I" is answered by navigation and
  headings. A consuming skill may add its *own* semantic axis (e.g. a risk axis) in
  its own stylesheet, but the hue it picks must not collide with an existing meaning.
- **Structure is a reference, not a mandate.** The contract binds how meaning is
  expressed, not how the document is shaped. A document whose job needs a different
  skeleton — several `article` elements under `main`, no `base.js` — is not in
  violation; it simply forgoes the parts of the kit it opted out of.
- **Progressive enhancement, not dependence.** Everything `base.js` adds is a
  layer on top of a page that already reads correctly. Author the semantic HTML
  first; let the kit enrich it.

## Consuming this base

Two consumption modes; pick by the output shape:

- **Copy mode** (multi-page sites): copy `base.css`/`base.js` into a shared
  `assets/` directory and `<link>`/`<script src>` them from every page. One
  stylesheet serves the whole site. This is the default, and what the reference
  site itself does.
- **Inline mode** (a single self-contained file): paste `base.css` into a
  `<style>` element and, if the DOM fits the kit, `base.js` into a `<script>`.
  Use this when the output must stay one portable file. The base stays the source
  of truth — the file is re-inlined on each regeneration; never hand-tune the
  inlined copy.

A copy-mode generation step should:

1. Copy `assets/base.css` and `assets/base.js` into the output's `assets/`.
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
4. Give the page the structure `base.js` wires from: a `header.site` (where the
   theme button mounts), a `main article`, and `h2`/`h3` section headings. A page
   with fewer than two `h2`s simply gets no TOC.
5. Author the markup against the index below (the reference site has the detail).
6. **Review every page produced** with [[understanding-html-docs-review]]. A generated
   document nobody reads back against the contract is the failure this base exists to
   prevent.

## Semantics → element / class (index)

**Foundation — carried by the element alone**, no class: `main > article` (the
document body), `header.site` / `footer` (page chrome), `h1` (title), `h2`/`h3`
(sections — the TOC and progress bar are built from these), `p`, `ul`/`ol`,
`table` (always inside `.tablewrap`), `code` / `pre > code`, `blockquote`, `hr`,
`mark`, `a`.

**Components — opted into with a class:**

| To express | Author |
|---|---|
| General supporting information | `.callout` (the base variant *is* note) |
| Advice worth following | `.callout.tip` |
| Something to be careful about | `.callout.warn` |
| A hazard — this breaks, this destroys | `.callout.danger` (**not** `warning`, not `error`) |
| The key insight | `.callout.key` |
| A bold lead-in inside a callout | `.callout .label` |
| What a section boils down to | `.keypoints` — a heading + `ul` inside |
| One line, said louder | `.pullquote` |
| An eyebrow above a heading | `.kicker` |
| The opening paragraph | `.lede` |
| A bordered block, and a grid of them | `.card` / `.card-grid` |
| A small outlined label | `.chip` (`.chip.accent` to accent it) |
| A small filled status/count marker | `.badge` |
| A quiet remark, carrying no meaning-color | `.aside` (the class — not a bare `<aside>`) |
| A horizontally scrollable table | `.tablewrap` > `table` |

**Injected by `base.js` — never authored:** `.progress`, `.theme-btn`, `.fab`,
`.toc-btn`, `.toc-backdrop`, `.toc-panel`.

**Forbidden:** a class nothing defines; a raw color in a `style` attribute
(`style="color:#e11"` — go through `var(--token)`); a primitive (`--n-*`,
`--blue-strong`) read from a component rule; a `<table>` outside `.tablewrap`; a
meaning color used as decoration; a new ad-hoc hue; a Tier 2 marker without its
bundle.

## Reviewing a document — [[understanding-html-docs-review]]

There is deliberately **no linter**. A checker can establish that a class *exists*,
and that is worth almost nothing here: the errors that matter are **well-formed**. A
`.callout.tip` wrapped around a hazard passes every conceivable class check, renders
as a perfectly good green box, and tells the reader the opposite of the truth.

> Whether a class exists is not the question. Whether it was used as intended is.

That is a reading task, so a generated document is **reviewed**, not linted. Run
[[understanding-html-docs-review]] on every page produced — it reads the contract and
the document and reports where the markup and the meaning have come apart: a callout
whose variant contradicts its own text (or that should not have been a callout at
all), a `.keypoints` that is not the takeaways, a meaning color spent on decoration,
a class borrowed from another system (`warning`/`error`/`info` render as a plain
note), a heading used to make a line bold, a Tier 2 marker whose bundle was never
shipped.

Under Claude Code the `understanding-html-docs-reviewer` subagent wraps it, so the
review runs in a **fresh context** — the agent that just authored the page cannot
read it independently of having written it.

## Opt-in components (Tier 2)

A document that needs a heavy renderer pulls in an **opt-in component** instead of
re-deriving the integration. Each lives in its own bundle under
`assets/components/<name>/` and is copied **only by a consumer that uses it**, so a
document that renders no diffs never ships diff2html.

| Component | Renders | Third-party engine (CDN by default) |
|-----------|---------|-------------------------------------|
| `components/highlight/` | syntax-highlighted code blocks (`pre code`, auto-detected or `language-xxx`) | highlight.js v11 |
| `components/diff/` | git diffs (`pre.diff-source` + `div.diff-render` pairs, unified↔side-by-side) | diff2html v3 |
| `components/diagram/` | mermaid diagrams (`pre.mermaid`) | mermaid v11 |

Each bundle carries its own CSS/JS plus an **`include.md`** that is the source of
truth for wiring it: the CDN tags (version-pinned; vendor locally for the offline
opt-in), the markup contract, and the escaping/validity rules the engine needs.
**Follow the bundle's `include.md`** — copy-mode (link/`src` the files) or
inline-mode (paste them into `<style>`/`<script>`, keeping only the CDN engine
external).

## Adding a component

Changing the design system is a different job from authoring a document. What a
component is for, what decides whether it belongs in the base at all, and where the
model runs out are in **[`docs/components.md`](docs/components.md)** — read it first.

Whatever you add exists in three places at once, and they must agree: the rule in
`base.css` (or a bundle), a demo on the reference site (the catalog a review judges
against), and a row in the *Semantics → element / class* index above. A class missing
from that index is reported as a **forbidden class** by
[[understanding-html-docs-review]] in every document that uses it.

## Gotchas

- **Copy, don't reference.** The assets must be copied into each output so the
  document stays self-contained. Never link to this skill's install path.
- **Boot key must match.** If the inline `<head>` snippet's storage key drifts
  from `base.js`'s `THEME_KEY`, the saved theme silently stops applying and the
  page flashes on load.
- **`base.js` targets the first `main article`.** A page that puts several
  `article` elements directly under `main` would mis-target the first one — so such
  a page should not load `base.js`, and keeps its own scripts instead
  (`base.css`'s design system and auto light/dark still work with no JS).
  [[understanding-explain-diff]] takes that route. This is a supported choice, not a
  violation — the PE preconditions simply do not apply to it.
- **Nothing here fails loudly.** A misspelled class, an inline hex color, a callout
  whose variant contradicts its own text — each renders plausibly and is never
  noticed. That is what [[understanding-html-docs-review]] is for; run it on what you
  generate.
