---
title: Foundation — explainer-html-docs
site-name: explainer-html-docs
back-link: "← Back to the index"
---

::: {.kicker}
FOUNDATION
:::

# Foundation

::: {.lede}
The foundation is what plain Markdown gets you. **No fenced-div class needed** — write ordinary Markdown and it is already styled.
:::

## What you write

Write ordinary Markdown — the foundation styles it with no class to reach for.

| To express | Write |
| --- | --- |
| The document title | a `#` heading |
| A section / subsection | a `##` / `###` heading |
| Prose | a plain paragraph (blank line between) |
| A list, ordered or not | `- ` items / `1. ` items |
| Tabular data | a Markdown table — **wrapped in `.tablewrap` automatically** |
| Code, inline or as a block | inline `code`, or a fenced code block |
| A quotation | a `>` blockquote |
| An illustration and its caption | `![caption](path)` |
| A break in the subject | `---` |
| A highlighted phrase | `[phrase]{.mark}` |
| A link | `[text](url)` |

The document body (`main > article`) and the page chrome (`header.site` / `footer`) are **not** yours to write — the template emits them around your content. See [the skeleton](index.html).

::: {.callout}
[Headings are not decoration]{.label} — the table of contents and the reading-progress bar are built from your `##` / `###` headings. Do not promote a line to a heading just to make it bold.
:::

## Prose

A paragraph is just a blank-line-separated block of text. Links take [the single accent](index.html), and inline `code` reads as a code surface against the page. A phrase can be lifted with [this highlighter band (mark)]{.mark}.

> A quotation is set apart by a rule and muted text. Use it for actually quoting a source — not for a remark of your own (that is `.aside` or `.callout`).

- The foundation is plain Markdown — no class to reach for
- Components are opted into with a fenced-div class

---

## Tables

Write a plain Markdown table — the generator wraps every one in `.tablewrap` automatically, so a wide table scrolls inside its column instead of breaking out on a narrow screen. You never write the wrapper yourself.

| Layer | How it applies |
| --- | --- |
| Foundation | Plain Markdown. No class. |
| Component | Opted into with a fenced-div class. |
| Tier 2 | Only on a page that ships the bundle. |

The wrapper the generator emits around your table:

```{.nohighlight}
<div class="tablewrap">
  <table>…</table>
</div>
```

## Figures

Write an illustration as `![caption](path)`; the generator emits a `figure` holding an `img` and a `figcaption` — never a bare `img`. `img`, `svg` and `video` are clamped to the text column, so an asset authored at any pixel width cannot push the page into horizontal scroll on a phone. They are never scaled *up*: a small crop stays small rather than being stretched soft.

```{.nohighlight}
![The caption.](figures/fig-p031-1.jpg)
```

::: {.callout}
[The plate stays light in dark mode]{.label} — a figure is usually a crop off a white page, or a transparent PNG of dark strokes. A dark backing would erase it, so the image sits on a light plate in both themes and the border seats it against the surface.
:::

::: {.callout variant=warn}
[A relative path can escape the document]{.label} — an `src` is resolved against the page, not against where the content was written. A path that reaches outside what actually gets deployed still renders locally and 404s in production. Point at assets that ship with the document.
:::

## Code

The base renders code blocks unhighlighted. If you want syntax highlighting, ship the [Tier 2 highlight component](tier2.html).

```{.nohighlight}
<link rel="stylesheet" href="assets/base.css">
<script src="assets/base.js" defer></script>
```

## The column

Everything above sits in one centered column. Its width is not a per-page decision made in CSS — it is a **layout variant**, chosen at build time and emitted as a `layout-*` class on `<body>`. Three steps of one quantity:

| Variant | Measure | Reach for it when |
| --- | --- | --- |
| `narrow` | 48rem (~46 JA chars/line) | short, prose-only documents |
| `standard` | 56rem (~54 JA chars/line) | nearly everything — this is the default |
| `wide` | 64rem (~62 JA chars/line) | reference material built around tables, diagrams and code |

A variant sets that one measure and nothing else. Everything downstream derives from it: the sidebar index's offset in the gutter, the floating buttons' column, and the viewport width at which the table of contents becomes a persistent rail.

::: {.callout}
[The article is centered on its own]{.label} — in every variant. The sidebar index is positioned in the gutter beside the column; it never shifts the column to make room for itself, so the text you are reading stays in the middle of the viewport whether the index is showing or not.
:::

Pick one with `layout:` in the page's frontmatter, or set the default for a whole site with `build.sh --layout` / `build-site.sh --layout`. The most specific wins: a page's own `layout:` overrides the site-wide flag, which overrides `standard`. An unknown name fails the build, like every other base variant.

## When content is wider than the column

A wider variant is **not** the answer to one oversized table. Content that outgrows the measure scrolls inside its own box — that is what lets a single measure serve a page that also carries a nine-column table or a long line of code. Both `pre` and the automatic `.tablewrap` do this for you.

The scrollbar is left to the platform: whatever your system does everywhere else, it does here. Styling it at all would opt the box out of the overlay behavior most systems use and pin a permanent band under every code block and table — there is no setting in between — so nothing is declared and the bar stays native.

Both demonstrate it here. This table is deliberately wider than any variant's measure — every column a layout variant decides, which is more than fits. Drag it sideways:

| Variant | Measure | JA chars/line | Sidebar rail appears at | Rail left edge | FAB stack right edge | Footer cap | Bottom-sheet width | Reach for it when |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `narrow` | 48rem | ~46 | 79rem viewport | gutter − 15rem | 50vw − 27.5rem | 48rem | 48rem | short, prose-only documents |
| `standard` | 56rem | ~54 | 87rem viewport | gutter − 15rem | 50vw − 31.5rem | 56rem | 56rem | nearly everything — the default |
| `wide` | 64rem | ~62 | 95rem viewport | gutter − 15rem | 50vw − 35.5rem | 64rem | 64rem | tables, diagrams and code |

Every number above is derived from the measure alone — that is the point of the variant setting exactly one thing. And the code block below carries one long line:

```{.nohighlight}
scripts/build.sh report.md site/ --assets explainer-html-docs/assets --context my-skill/assets --component reading-nav --layout wide --inline
```

::: {.callout variant=tip}
[Nothing to author]{.label} — the overflow behavior is on the `pre` and `.tablewrap` elements themselves, so it works wherever they appear, including inside a callout or a card. There is no class to add and no opt-in.
:::

::: {.callout variant=warn}
[An overlay scrollbar says nothing at rest]{.label} — on macOS and most touch platforms the bar fades out, so a table clipped at its right edge can read as the whole table. Put the columns a reader must not miss on the left, and do not let a table be the only place a fact appears.
:::
