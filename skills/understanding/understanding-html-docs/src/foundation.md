---
title: Foundation — understanding-html-docs
site-name: understanding-html-docs
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
