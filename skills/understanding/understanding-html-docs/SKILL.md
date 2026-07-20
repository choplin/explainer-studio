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

Consuming skills copy the asset files verbatim and add their own context stylesheet
and content — the content as a semantic IR run through
[[understanding-html-docs-generate]] (see *Consuming this base*) — and never edit
these files per document.

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
  layer on top of a page that already reads correctly. The semantic markup comes
  first (authored as IR, generated to HTML); the kit only enriches it.

## Consuming this base

**The standard path is to generate pages from a semantic IR, not to hand-write
HTML.** [[understanding-html-docs-generate]] takes Markdown + fenced divs that name
only the *meaning* (`::: {.callout variant=danger}`) and deterministically emits the
HTML: a pandoc template owns the structural boilerplate (head skeleton, theme-boot
key, asset order, `header.site` / `main article`) and a Lua filter binds each meaning
to its markup. So the mechanical work the author used to do by hand — steps 3–5 of the
old checklist — is generated, and the wiring mistakes it was on the author to avoid
become unrepresentable (an invented class, an inline color, an unwrapped table, an
unknown callout variant). This is the route every consumer takes (pdf-studio,
paper-studio, explain-diff); reach for it first.

That path introduces an **authoring-time build** (pandoc) — a deliberate reversal of
the old "No build step" prohibition, recorded in
[`docs/components.md`](docs/components.md). The build runs at authoring time only:
**the output is still plain static HTML** that opens on a double-click, with no server
and no build tooling.

Two output shapes, selected on the generator's command line:

- **Copy mode** (multi-page sites, the default): `base.css`/`base.js` and any context
  assets are copied into a shared `assets/` directory and linked from every page. One
  stylesheet serves the whole site — what the reference site itself does.
  (`build-site.sh`, or `build.sh` without `--inline`.)
- **Inline mode** (a single self-contained file): `base.css`/`base.js` are folded into
  the page as `<style>`/`<script>` and the `assets/` dir is dropped, yielding one
  portable file (remote CDN engines stay external). The base stays the source of
  truth — the file is re-generated, never hand-tuned. (`build.sh --inline`;
  [[understanding-explain-diff]] takes this route.)

The generator owns the structural wiring the author used to hand-place: the asset link
order (`base.css` → context CSS → `base.js` → context JS), the theme-boot snippet whose
storage key must match `base.js`'s `THEME_KEY`, and the `header.site` / `main article` /
`h2`–`h3` skeleton `base.js` wires from. See [[understanding-html-docs-generate]] for
the IR dialect and how a consumer injects its own vocabulary (context stylesheet +
filter directives + optional template variant).

Whichever path produced it, **review every page** with
[[understanding-html-docs-review]]. Determinism removes the *mechanical* half of the
review (a class that does not exist, an unwrapped table — now impossible to emit); the
*semantic* half (is this the right variant, is this actually the takeaway) remains a
reading task and moves from the HTML to the compact IR. A document nobody reads back
against the contract is the failure this base exists to prevent.

### Hand-authoring HTML — the fallback route

Writing the HTML directly, against the *Semantics → element / class* index below, is
now the **exception, not the default** — an escape hatch for a one-off the generator
cannot yet express, or an environment where pandoc is unavailable. It forfeits every
guarantee the generator buys: nothing stops an invented class, an inline color, an
unwrapped table, or an unknown callout variant, so each must be avoided by hand and
caught only in review. If you take this route: copy `base.css`/`base.js` into
`assets/`; link them base-first (`base.css` before the context stylesheet); inline the
theme-boot snippet in `<head>` before first paint with a storage key matching
`base.js`'s `THEME_KEY`, and load `base.js` deferred; give the page the `header.site` /
`main article` / `h2`–`h3` structure `base.js` wires from (fewer than two `h2`s = no
TOC); author against the index below; and lean harder on
[[understanding-html-docs-review]], because the mechanical contract is back on you.

## Semantics → element / class (index)

**Foundation — carried by the element alone**, no class: `main > article` (the
document body), `header.site` / `footer` (page chrome), `h1` (title), `h2`/`h3`
(sections — the TOC and progress bar are built from these), `p`, `ul`/`ol`,
`table` (always inside `.tablewrap`), `code` / `pre > code`, `blockquote`, `hr`,
`mark`, `a`, and `figure` > `img` + `figcaption` (an illustration with its
caption — `img`/`svg`/`video` are clamped to the column so nothing overflows on
a phone, and never scaled up past their natural size; author a figure with a
real `alt` and a `figcaption`, never a bare `<img>`).

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

**Injected by the `comments` component (Tier 2) — never authored:**
`.comments-panel`, `.comments-backdrop`, `.comments-fab`, `.comments-composer`,
`.comments-cmenu`, `.comments-selbtn`, `.comment-card`, `.comment-anchored`, and
their descendants. These exist only when the `comments` bundle is shipped.

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

That is a reading task, so the work is **reviewed**, not linted. Run
[[understanding-html-docs-review]] on every page produced — it reads the contract and
the **IR** (the standard path generates the HTML from IR, so the review moves to the
compact source) and reports where the markup and the meaning have come apart: a
callout whose variant contradicts its own text (or that should not have been a callout
at all), a `.keypoints` that is not the takeaways, a meaning color spent on
decoration, a heading used to make a line bold. The purely *mechanical* failures the
old checklist watched for — a class that does not exist, a name borrowed from another
system (`warning`/`error`/`info`), an unwrapped table — are no longer review findings:
the generator makes them impossible to emit (an unknown variant fails the build). What
remains is the semantic half, which no generator can settle. (Only on the
hand-authored fallback route are those mechanical checks still the reviewer's job.)

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
| `components/comments/` | a browser-side review layer — select text / right-click a block to comment, list panel in the right gutter, localStorage + JSON/Markdown export (**no markup to author**) | — none; vanilla & offline |

The `comments` bundle is the odd one out: it has **no third-party engine** and
**no markup contract** (the reader creates comments at runtime; nothing is
authored into the document). It is Tier 2 because commenting is a mode not every
document wants — not because it needs an online viewer. It is independent of
`base.js` (its scope is `main`, not `main article`), so it works both on a
reading page and on an [[understanding-explain-diff]] page.

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
