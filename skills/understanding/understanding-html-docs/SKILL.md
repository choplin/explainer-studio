---
name: understanding-html-docs
description: The design system AND the deterministic generator for skills that explain something as a self-contained HTML document. It owns the visual language (typography, a meaning-only color model, callouts, chips), the progressive-enhancement kit (theme toggle, reading progress, table of contents, back-to-top), and a pandoc-based generator that binds a semantic intermediate representation (Markdown + fenced divs that name only meaning, `::: {.callout variant=danger}`) to that markup — so an unknown callout variant is a hard build error, every table is wrapped in .tablewrap, and an invented class or inline style is unrepresentable. The author writes only the meaning; the mechanical layer cannot be gotten wrong. Other skills delegate here to generate their pages from a semantic IR and copy the base assets, then layer their own context stylesheet and vocabulary on top; the output is plain static HTML that opens with no server. Use this skill when another skill produces understanding-html-docs pages or applies its design system.
---

# understanding-html-docs — design system + IR → page generator

This skill owns the resources shared across skills that render an **explanation as
a browsable web document** — [[understanding-explain-diff]] (a diff explained to a
reviewer), pdf-studio's / paper-studio's generate-site (reports as a reading site),
and future skills of the same shape. It exists so each such skill inherits one design
language, one interaction kit, and one generator instead of re-deriving them.

The idea:

> An explanation web document is a **foundation + a semantic design system + a
> progressive-enhancement kit**, plus a context layer the consuming skill owns.
> The first three are here; the context layer (what the document is *about*, and
> any heavy third-party libraries it needs) stays in the consuming skill.

And that design system is not authored by hand — it is **generated**. The skill
factors the binding of *meaning* to *presentation* ("this is a hazard", never "make
this box red") into two layers so the mechanical half is produced, not typed:

- **The author writes a semantic IR** — Markdown with fenced divs that name only
  the meaning (`::: {.callout variant=danger}`).
- **The generator binds meaning → markup** — a pandoc template for the structural
  boilerplate, a Lua filter for the component vocabulary.

Consuming skills run their content (as a semantic IR) through this skill's generator
and copy the asset files verbatim, adding their own context stylesheet and content —
and never edit these files per document.

## The reference site is the contract

**The normative source is the reference site under this skill's `site/`** — `site/index.html`
and the six pages it links. It is itself **generated from `src/*.md` by this skill's
own generator** (dogfood): the contract is written in the design system it documents,
from the same IR any consumer writes, so the contract and the worked example are the
same artifact and cannot drift apart. It is also the living catalog — every component,
in both themes — and the worked example a generated document mirrors.

| Page | Covers |
|---|---|
| `site/index.html` | The two consumption modes, the skeleton, the page index |
| `site/foundation.html` | What works with no class: headings, prose, tables, code, quotes |
| `site/color.html` | The meaning-only color model and the token layers |
| `site/components.html` | The classes you opt into: callout, keypoints, card, chip, aside… |
| `site/enhancement.html` | What `base.js` adds, and the preconditions it needs |
| `site/tier2.html` | The opt-in bundles: highlight, diff, diagram |
| `site/contract.html` | The rules, and why generation needs no general review |

Serve `site/` over HTTP (`cd site && python3 -m http.server`) — the diagram
component is an ES module and will not render over `file://`.

**Regenerating it:** `scripts/build-reference-site.sh` rebuilds all seven pages from
`src/*.md` into `site/` (the committed artifact — no manual copy step). The six
base pages build with the default template and filter; `tier2.html` is the one page
whose Tier 2 component markup the base dialect cannot express, so it builds with
`assets/template-tier2.html` (adds the `comments-gutter` class + the component `<head>`
tags) and `filters/tier2.lua` (emits the `pre.mermaid` / `pre.diff-source` / highlight
contracts from plain fenced code blocks). Editing a page means editing its IR and
regenerating — never hand-editing the generated HTML.

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
- **`assets/template.html`** — the pandoc template the generator uses for the
  structural boilerplate (head skeleton, theme-boot key, asset link order,
  `header.site` / `main article`).
- **`assets/components/<name>/`** — the Tier 2 opt-in bundles (see below).

The generator machinery, also under this skill's root:

- **`filters/htmldocs.lua`** — the pandoc Lua filter that binds each meaning to its
  markup, validates the vocabulary (an unknown callout variant is a hard error), and
  wraps every table in `.tablewrap`.
- **`scripts/build.sh`** — render one IR file into a page; **`scripts/build-site.sh`**
  — render a whole `ir/*.md` dir into a multi-page site; plus `scripts/preflight.sh`
  (resolves pandoc: PATH → bundled `nix develop` → fail) and `scripts/inline.awk`
  (the inline-mode fold).
- **`flake.nix` / `flake.lock`** — the pinned pandoc runtime the preflight falls back
  to; see [`docs/skill-runtime-and-dependencies.md`](../../../docs/skill-runtime-and-dependencies.md).

At this skill's root:

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

## Producing a page — IR → HTML, deterministically

**A page is generated from a semantic IR — this is the one route.** The generator
takes Markdown + fenced divs that name only the *meaning* (`::: {.callout
variant=danger}`) and deterministically emits the HTML: `assets/template.html` owns the
structural boilerplate (head skeleton, theme-boot key, asset order, `header.site` /
`main article`) and `filters/htmldocs.lua` binds each meaning to its markup. So the
mechanical work — the asset link order, the theme-boot snippet whose storage key must
match `base.js`'s `THEME_KEY`, the `header.site` / `main article` / `h2`–`h3` skeleton
`base.js` wires from — is generated, and the wiring mistakes that used to be on the
author become **unrepresentable** (an invented class, an inline color, an unwrapped
table, an unknown callout variant). Every consumer takes this route (pdf-studio,
paper-studio, explain-diff).

What determinism buys, and what it does not:

- **Buys:** the head/theme-boot/asset-order are always correct (the author never
  writes them); an invented class or inline `style` is unrepresentable; an unknown
  callout variant is a **hard error at generation**, not a silent unstyled box;
  every `<table>` is wrapped in `.tablewrap`.
- **Does not buy:** whether a passage *is* a hazard (`danger`) or the key point
  (`key`) is a reading judgment no generator can make. That choice lives in the IR
  and is still reviewed — see *Reviewing a document* below. Determinism guarantees
  the IR→HTML mapping, not the correctness of the IR's meaning.

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

### The IR dialect

Frontmatter carries the page chrome:

```yaml
---
title: Page title — Site name
site-name: understanding-html-docs   # header.site link text
context-css: color.css               # optional: one consumer stylesheet…
# context-css:                       # …or a list, emitted after base.css in order
#   - pdf-studio.css
context-js:                          # optional: consumer scripts, emitted (defer)
#   - nav-manifest.js                #   after base.js in list order — data first,
#   - pdf-studio.js                  #   then the logic that reads it
back-link: "← Back to the index"     # optional: footer link text (omit for none)
---
```

`context-css` and `context-js` each accept **one value or a YAML list**; a scalar is
just a one-element list (so an existing single `context-css:` is unchanged). Asset
order in `<head>` is fixed: `base.css` → `context-css[]` → `base.js` → `context-js[]`.
`build.sh --context <dir>` copies every `*.css` **and** `*.js` from that dir verbatim
into the output `assets/`, so each referenced file resolves.

Body vocabulary (everything the author reaches for):

| To express | Author |
|---|---|
| General information | `::: {.callout}` … `:::` (the bare note variant) |
| Advice / caution / hazard / key insight | `::: {.callout variant=tip\|warn\|danger\|key}` |
| A bold lead-in inside a callout | `[Label]{.label}` at the paragraph start |
| What a section boils down to | `::: {.keypoints}` with `### Title` + a `- ` list |
| A grid of peer blocks | `:::: {.card-grid}` wrapping `::: {.card}` blocks |
| A small outlined / filled label | `[text]{.chip}` · `[text]{.chip .accent}` · `[text]{.badge}` |
| Opening paragraph / eyebrow / louder line | `::: {.lede}` · `::: {.kicker}` · `::: {.pullquote}` (emitted as `<p class>`) |
| A quiet remark | `::: {.aside}` |
| A highlighted phrase | `[text]{.mark}` (emitted as `<mark>`) |
| Tabular data | a plain Markdown table — **wrapped in `.tablewrap` automatically** |
| A code sample | a ` ```{.nohighlight} ` fenced block |
| Foundation (headings, prose, lists, blockquote, links, code, hr) | plain Markdown |

Rules the generator enforces (so you cannot get them wrong):

- `variant=` must be one of `tip` / `warn` / `danger` / `key` (or omitted for note).
  Anything else — `warning`, `error`, a typo — **fails the build**.
- Every table is wrapped; never hand-write `.tablewrap`.
- `-f markdown-raw_html` is on: raw HTML in the IR is **not** passed through, so an
  invented class or inline color cannot slip in.

#### Consumer-specific vocabulary

A consumer that needs its own components (e.g. the color page's `swatch` / `ramp`,
or [[understanding-explain-diff]]'s risk / verify axes) supplies:

1. a **context stylesheet** referenced via the `context-css` frontmatter var;
2. **filter directives** for the new vocabulary — a consumer Lua filter passed with
   `--filter`, chained after `htmldocs.lua` so its rules bind on top of the base
   (see the `ramp` / `swatch` rules in `filters/htmldocs.lua`, and explain-diff's
   `filters/explain-diff.lua`, as worked examples); and, for a heavier consumer:
3. a **template variant** via `--template`, when the page skeleton itself differs
   from the default single `main > article` (e.g. explain-diff's multi-`article`
   walkthrough with its own header and bottom scripts).

This is how the IR vocabulary, its rendering, *and* the page skeleton are injected
per consumer. Both the base and consumer filters run in one `--lua-filter` chain,
so `base vocabulary + consumer vocabulary` compose.

The **pdf-studio** consumer adds these (their markup carries a raw `<audio>` / must
point inside the site root, so the filter guarantees the structure the author cannot
hand-write under `-f markdown-raw_html`):

| To express | Author | Emits |
|---|---|---|
| A source-PDF page anchor | `[p31]{.p}` | `<span class="p">p31</span>` (native span — no filter needed) |
| An in-page audio-guide player | `::: {.player src=audio/ch-1.m4a}` `:::` (optional `label="…"`, default `🔊 音声ガイド`) | `<div class="player"><span>…</span><audio controls preload="none" src="…"></audio></div>` |
| A harvested figure | `![caption](../ocr/figures/fig-p031-1.jpg)` | `<img src="figures/fig-p031-1.jpg" …>` — the `../ocr/figures/` prefix is rewritten to `figures/` at generation time, so no page points outside the site root (the caller's `grep '../'` review check becomes unnecessary) |

`.player` without a `src=` is a **hard error at generation** (like an unknown callout
variant). The page-to-page nav data (`window.__PDF_STUDIO_NAV`) is *not* the
generator's concern — it is a per-site `nav-manifest.js` the consumer authors and
loads as a `context-js` entry (before the script that reads it).

### Generating

Runtime is **pandoc**, resolved by the preflight (PATH → bundled `nix develop` →
fail); see [`docs/skill-runtime-and-dependencies.md`](../../../docs/skill-runtime-and-dependencies.md).

One page:

```bash
scripts/build.sh <ir.md> <out-dir> \
  --assets <understanding-html-docs/assets> \
  [--context <dir-of-context-css>] \
  [--template <consumer-template>] [--filter <consumer-filter.lua>]... [--inline]
```

By default the page is **copy-mode**: `base.css` / `base.js` and any context
`*.css` / `*.js` are copied into `<out-dir>/assets/` and the page links them.
`--inline` folds those local assets into the page as `<style>` / `<script>` and
drops the `assets/` dir, yielding **one self-contained file** (remote CDN engines
stay external). Inline is opt-in — a single-file consumer (explain-diff) asks for
it; a multi-page site (pdf-studio) stays copy-mode so pages share one asset set.
`--template` / `--filter` are the consumer hooks from *Consumer-specific
vocabulary* above; both compose with `--inline`.

A whole site (each `ir/*.md` → `out/<name>.html`, sharing one asset set):

```bash
scripts/build-site.sh <ir-dir> <out-dir> \
  --assets <understanding-html-docs/assets> [--context <dir>]
```

`base.css` / `base.js` (and any context `*.css`) are copied verbatim into
`<out-dir>/assets/`. Inter-page navigation is authored as links in the IR — the
reference site links each page home from its `header.site` and lists the pages from
the index; no manifest is needed for that shape.

### On reviewing a generated document

There is deliberately **no general review pass and no linter** for these documents.
That is a decision, and the reasoning is worth keeping.

A checker can establish that a class *exists*, and that is worth almost nothing here:
the errors that matter are **well-formed**. A `.callout.tip` wrapped around a hazard
passes every conceivable class check, renders as a perfectly good green box, and tells
the reader the opposite of the truth.

> Whether a class exists is not the question. Whether it was used as intended is.

So the review that would matter is a *semantic* reading task, not a mechanical one.
But once the page is generated deterministically from the IR, that review splits, and
neither half justifies a standalone review skill:

- **The mechanical half** — a class that does not exist, a name borrowed from another
  system (`warning`/`error`/`info`), an unwrapped table, an inline color — is made
  **impossible to emit** by the generator (an unknown variant is a hard build error;
  raw HTML is dropped). There is nothing left to review.
- **The semantic half** — is this the right variant, is this actually the takeaway,
  does `risk=high` match the change — is either **low-stakes and cosmetic** for a
  reading site (pdf-studio / paper-studio deliberately skip it as YAGNI) or
  **high-stakes but consumer-specific**, in which case the consuming skill
  **internalizes it as its own completion check** — e.g. [[understanding-explain-diff]]
  self-checks that each chunk's `risk` / `tested` / `verified` value matches its
  content. A general reviewer blind to a consumer's own axes cannot do that check
  anyway.

Net: the mechanical review is absorbed by the generator and the high-stakes semantic
review belongs to the consumer that defines the axes, so there is no general
`understanding-html-docs` review step to run. A consumer that layers high-stakes
semantic axes owns reviewing them; a low-stakes reading site skips review by policy.

## Semantics → element / class (index)

This is the class vocabulary the generator emits — its allowlist. A class in
`base.css` but missing from this index cannot appear in a document (see
[`docs/components.md`](docs/components.md) §2). It is not a
hand-authoring target — the author writes the IR dialect above, and the generator emits
this markup — but it is the canonical map from *meaning* to the element/class it
becomes.

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
bundle. The generator makes these unrepresentable from the IR; the index keeps them
nameable so the review can still speak of them.

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
`base.css` (or a bundle), a demo on the reference site (the catalog documenting what
each component means), and a row in the *Semantics → element / class* index above. A
class missing from that index cannot be authored into a document — the generator emits
only the indexed markup. A new vocabulary item also needs its **IR-dialect** entry
(above) and, if it is not a plain class/variant, a binding rule in
`filters/htmldocs.lua`.

## Gotchas

- **Copy, don't reference.** The assets must be copied into each output so the
  document stays self-contained. Never link to this skill's install path.
- **Boot key must match.** The generator inlines the theme-boot snippet, but if its
  storage key ever drifts from `base.js`'s `THEME_KEY`, the saved theme silently stops
  applying and the page flashes on load — keep `template.html` and `base.js` in sync.
- **`base.js` targets the first `main article`.** A page that puts several
  `article` elements directly under `main` would mis-target the first one — so such
  a page should not load `base.js`, and keeps its own scripts instead
  (`base.css`'s design system and auto light/dark still work with no JS).
  [[understanding-explain-diff]] takes that route (its own template variant). This is
  a supported choice, not a violation — the PE preconditions simply do not apply to it.
- **Nothing here fails loudly at the *semantic* level.** The generator refuses a
  misspelled class or an unknown variant, but a callout whose variant contradicts its
  own text builds cleanly and misleads. There is no general review step to catch that
  (see *On reviewing a generated document* above): a low-stakes reading site skips it,
  and a consumer with high-stakes axes internalizes the check itself (as
  [[understanding-explain-diff]] does for `risk`/`tested`/`verified`).
