---
name: understanding-html-docs-generate
description: Deterministically render an understanding-html-docs page from a semantic intermediate representation (Markdown + fenced divs) instead of hand-authoring HTML. A pandoc template owns the structural boilerplate (head skeleton, theme-boot key, asset link order, header.site / main article) and a Lua filter binds each meaning to its markup, validates the vocabulary (an unknown callout variant is a hard error), and wraps every table in .tablewrap — so the mechanical layer cannot be gotten wrong. The AI writes only the meaning; the semantic choice of which component a passage is stays the author's and is still reviewed. Use this skill when a consumer (e.g. pdf-studio's generate-site) produces understanding-html-docs pages and wants the structure generated rather than typed. Delegates to understanding-html-docs for the design contract; the output is reviewed with understanding-html-docs-review.
---

# understanding-html-docs-generate — IR → page, deterministically

The design system ([[understanding-html-docs]]) binds a *meaning* to a
*presentation* ("this is a hazard", never "make this box red"). This skill factors
that binding into two layers so the mechanical half is generated, not typed:

- **The author writes a semantic IR** — Markdown with fenced divs that name only
  the meaning (`::: {.callout variant=danger}`).
- **The generator binds meaning → markup** — a pandoc template for the structural
  boilerplate, a Lua filter for the component vocabulary.

What determinism buys, and what it does not:

- **Buys:** the head/theme-boot/asset-order are always correct (the author never
  writes them); an invented class or inline `style` is unrepresentable; an unknown
  callout variant is a **hard error at generation**, not a silent unstyled box;
  every `<table>` is wrapped in `.tablewrap`.
- **Does not buy:** whether a passage *is* a hazard (`danger`) or the key point
  (`key`) is a reading judgment no generator can make. That choice lives in the IR
  and is still reviewed — see [[understanding-html-docs-review]]. Determinism
  guarantees the IR→HTML mapping, not the correctness of the IR's meaning.

## The IR dialect

Frontmatter carries the page chrome:

```yaml
---
title: Page title — Site name
site-name: understanding-html-docs   # header.site link text
context-css: color.css               # optional: a consumer context stylesheet
back-link: "← Back to the index"     # optional: footer link text (omit for none)
---
```

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

### Consumer-specific vocabulary

A consumer that needs its own components (e.g. the color page's `swatch` / `ramp`,
or explain-diff's risk axis) adds:

1. a **context stylesheet** referenced via the `context-css` frontmatter var, and
2. **filter directives** for the new vocabulary (see the `ramp` / `swatch` rules in
   `filters/htmldocs.lua` as the worked example).

This is how both the IR vocabulary *and* its rendering are injected per consumer.

## Generating

Runtime is **pandoc**, resolved by the preflight (PATH → bundled `nix develop` →
fail); see [`docs/skill-runtime-and-dependencies.md`](../../../docs/skill-runtime-and-dependencies.md).

One page:

```bash
scripts/build.sh <ir.md> <out-dir> \
  --assets <understanding-html-docs/assets> \
  [--context <dir-of-context-css>]
```

A whole site (each `ir/*.md` → `out/<name>.html`, sharing one asset set):

```bash
scripts/build-site.sh <ir-dir> <out-dir> \
  --assets <understanding-html-docs/assets> [--context <dir>]
```

`base.css` / `base.js` (and any context `*.css`) are copied verbatim into
`<out-dir>/assets/`. Inter-page navigation is authored as links in the IR — the
reference site links each page home from its `header.site` and lists the pages from
the index; no manifest is needed for that shape.

## After generating

Review every page with [[understanding-html-docs-review]]. Determinism removes the
*mechanical* half of the review (class exists, table wrapped — now impossible to
fail); the *semantic* half (is this the right variant, is this actually the
takeaway) remains a reading task, and moves from the HTML to the compact IR.
