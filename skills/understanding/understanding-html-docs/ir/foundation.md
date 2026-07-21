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
The foundation is carried by element selectors. **No classes needed** — write plain semantic HTML and it is already styled.
:::

## Meaning to element

| To express | Author |
| --- | --- |
| The body of the document | `main` > `article` |
| Page chrome | `header.site` / `footer` |
| The document title | `h1` |
| A section / subsection | `h2` / `h3` |
| Prose | `p` |
| A list, ordered or not | `ul` / `ol` |
| Tabular data | `table` — always inside `.tablewrap` |
| Code, inline or as a block | `code` / `pre` > `code` |
| A quotation | `blockquote` |
| An illustration and its caption | `figure` > `img` + `figcaption` |
| A break in the subject | `hr` |
| A highlighted phrase | `mark` |
| A link | `a` |

::: {.callout}
[Headings are not decoration]{.label} — the table of contents and the reading-progress bar are built from `h2` / `h3`. Do not promote a line to a heading just to make it bold.
:::

## Prose

A paragraph is a `p`. Links take [the single accent](index.html), and inline `code` reads as a code surface against the page. A phrase can be lifted with [this highlighter band (mark)]{.mark}.

> A quotation is set apart by a rule and muted text. Use it for actually quoting a source — not for a remark of your own (that is `.aside` or `.callout`).

- The foundation applies itself through element selectors
- Components are opted into with a class

---

## Tables

Every `<table>` goes inside `.tablewrap`. Without it, a wide table breaks out of the column on a narrow screen.

| Layer | How it applies |
| --- | --- |
| Foundation | Element selectors. No class. |
| Component | Opted into with a class. |
| Tier 2 | Only on a page that ships the bundle. |

```{.nohighlight}
<div class="tablewrap">
  <table>…</table>
</div>
```

## Figures

An illustration is a `figure` holding an `img` and a `figcaption` — never a bare `img`. `img`, `svg` and `video` are clamped to the text column, so an asset authored at any pixel width cannot push the page into horizontal scroll on a phone. They are never scaled *up*: a small crop stays small rather than being stretched soft.

```{.nohighlight}
<figure>
  <img src="figures/fig-p031-1.jpg" alt="what the figure shows">
  <figcaption>The caption.</figcaption>
</figure>
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
