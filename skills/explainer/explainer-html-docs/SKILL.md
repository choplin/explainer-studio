---
name: explainer-html-docs
description: 'The design system AND the deterministic generator for skills that explain something as a self-contained HTML document. It owns the visual language (typography, a meaning-only color model, callouts, chips), the progressive-enhancement kit (theme toggle, reading progress, table of contents, back-to-top), and a pandoc-based generator that binds semantic Markdown (Markdown + fenced divs that name only meaning, `::: {.callout variant=danger}`) to that markup — so an unknown callout variant is a hard build error, every table is wrapped in .tablewrap, and an invented class or inline style is unrepresentable. The author writes only the meaning; the mechanical layer cannot be gotten wrong. Other skills delegate here to generate their pages from semantic Markdown and copy the base assets, then layer their own context stylesheet and vocabulary on top; the output is plain static HTML that opens with no server. Use this skill when another skill produces explainer-html-docs pages or applies its design system.'
---

# explainer-html-docs — design system + semantic Markdown → page generator

This skill owns the shared design system, progressive-enhancement kit, and
deterministic generator used by [[explainer-diff]], the PDF/Paper reading sites, and
future explanation documents of the same shape.

The contract has two layers:

- The author writes **semantic Markdown**: Markdown plus fenced divs that name
  meaning (`::: {.callout variant=danger}`), never presentation.
- The generator binds that meaning to markup through `assets/template.html` and
  `filters/htmldocs.lua`.

Consumers copy the generated assets into their output and may add a context
stylesheet, context scripts, a consumer filter, or a template variant. They never
edit this skill's assets per document.

## Required reading by task

Read only the reference that the current task needs:

- **Authoring or generating a page/site:** read
  [`references/authoring-contract.md`](references/authoring-contract.md) completely
  before writing semantic Markdown or running a build. It contains the frontmatter,
  full semantic notation, consumer-extension contract, commands, and copy/inline
  behavior.
- **Reviewing generated output, using Tier 2 components, or changing the base:**
  read [`references/markup-and-components.md`](references/markup-and-components.md)
  completely. It contains the canonical meaning→markup index, review ownership,
  opt-in component rules, component-change checklist, and operational gotchas.
- **Designing or promoting a component:** also read
  [`docs/components.md`](docs/components.md) completely before editing. It is the
  existing normative design rationale and remains at this path for consumers that
  already link to it.

## The reference site is the contract

The normative worked example and visual catalog is the committed reference site under
`site/`:

| Page | Covers |
|---|---|
| `site/index.html` | Consumption modes, skeleton, page index |
| `site/foundation.html` | Classless headings, prose, tables, code, quotes |
| `site/color.html` | Meaning-only color model and token layers |
| `site/components.html` | Tier 1 semantic components |
| `site/enhancement.html` | `base.js` behavior and preconditions |
| `site/tier2.html` | Opt-in highlight, diff, diagram, comments, reading-nav bundles |
| `site/contract.html` | Generation and review contract |

The site is generated from `src/*.md` by this skill itself. When a summary elsewhere
disagrees with the site, the site wins. Edit the semantic source, then run
`scripts/build-reference-site.sh`; never hand-edit generated files under `site/`.
Serve `site/` over HTTP when inspecting the diagram component because ES modules do
not render over `file://`.

## Owned resources

Resolve all paths relative to this skill's installed directory:

- `assets/base.css`: foundation, meaning-only colors, Tier 1 components, and styles
  toggled by progressive enhancement.
- `assets/base.js`: dependency-free theme toggle, reading progress, responsive TOC
  with scroll-spy, and back-to-top.
- `assets/template.html`: generated page skeleton, theme boot, asset order,
  `header.site`, and `main article`.
- `assets/components/<name>/`: Tier 2 opt-in bundles.
- `filters/htmldocs.lua`: semantic vocabulary binding, hard validation, table
  wrapping, and figure-path rewriting.
- `scripts/build.sh`: build one page; `scripts/build-site.sh`: build a source
  directory; `scripts/preflight.sh`: resolve pandoc from PATH or bundled
  `nix develop`; `scripts/inline.awk`: fold local assets into a single page.
- `flake.nix` / `flake.lock`: pinned fallback runtime.

## Invariants

- **Use generation as the only authoring route.** Do not hand-write the page shell,
  asset links, base classes, inline colors, or table wrappers.
- **Preserve hard failures.** An unknown callout variant and a `.player` without
  `src=` must fail generation. Raw HTML is disabled with `-f markdown-raw_html`, so
  invented classes and inline styles cannot pass through.
- **Keep generated markup deterministic.** `template.html` owns structural
  boilerplate and asset order; `htmldocs.lua` owns meaning→markup and wraps every
  table in `.tablewrap`.
- **Copy local assets into each output.** Never link to the installed skill path.
  The static output remains readable without a server and without `base.js`.
- **Use color only for meaning.** `note`/`tip`/`warn`/`danger`/`key` and `<mark>`
  have fixed meanings. Everything else uses `--accent`; never color-code chapters or
  sections by position.
- **Let consumers own content semantics.** A consumer may add a non-conflicting
  semantic axis through its own stylesheet and filter. It must review any
  high-stakes semantic choices it introduces.
- **Keep heavy renderers opt-in.** Highlight.js, diff2html, and mermaid integrations
  live in Tier 2 bundles and may use version-pinned CDNs. The base substrate itself
  stays local and offline-capable.
- **Treat structure as opt-in.** A consumer needing several `article` elements or no
  `base.js` supplies a template variant; it does not fork the design system.

## Generation order

1. Read `references/authoring-contract.md`.
2. Author semantic Markdown and any consumer-owned context/filter/template.
3. Run `scripts/build.sh` for one page or `scripts/build-site.sh` for a site.
4. If a Tier 2 bundle is needed, pass repeatable `--component <name>` and follow that
   bundle's `include.md`.
5. Apply the review ownership described in
   `references/markup-and-components.md`: generated mechanics need no standalone
   review, while consumer-defined high-stakes semantics do.

The output shapes are:

- **Copy mode** (default): pages share a generated `assets/` directory.
- **Inline mode** (`build.sh --inline`): local CSS/JS is folded into one portable
  HTML file; remote CDN engines remain external.

## Completion checks

- The build succeeds with no unknown vocabulary.
- Generated pages use the template/filter route and contain no hand-authored base
  markup or inline presentation.
- All referenced local assets were copied into the output.
- Every explanatory figure has meaningful alternative text and a caption.
- Any selected Tier 2 bundle follows its own `include.md`.
- Any consumer-defined high-stakes semantic axis was checked by that consumer.
- After changing this base, regenerate the reference site and confirm its generated
  diff is intentional.
