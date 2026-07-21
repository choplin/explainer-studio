---
title: Progressive enhancement — understanding-html-docs
site-name: understanding-html-docs
back-link: "← Back to the index"
---

::: {.kicker}
ENHANCEMENT
:::

# Progressive enhancement

::: {.lede}
`base.js` reads your markup and builds the reading UI from it. **You never author any of it** — you author the structure it reads.
:::

## What it adds

All of this is live on this page right now: the theme button in the header, the progress bar at the top of the viewport, the table of contents (a sidebar on a wide screen, a ☰ panel on a narrow one), and the back-to-top button.

| Feature | Built from |
| --- | --- |
| Theme toggle (auto / light / dark) | `header.site`, plus the boot snippet in `<head>` |
| Reading-progress bar | The extent of `main article` |
| Table of contents, with scroll-spy | The `h2` / `h3` inside `main article` |
| Back to top | Scroll position |

## What it needs from you

These are the preconditions of the kit. Meet them and everything above appears; miss one and the feature that depends on it **degrades silently** — nothing errors, the UI is simply not there.

::: {.keypoints}
### Preconditions

- A `main > article`. The kit targets the **first** one and reads the headings inside it.
- Real `h2` / `h3` section headings. No headings, no table of contents.
- A `header.site` for the theme button to mount into (without one it floats).
- The boot snippet in `<head>`, with the same storage key as `base.js`.
:::

::: {.callout variant=warn}
[A page with fewer than two h2s gets no TOC]{.label} — that is by design, not a bug. There is nothing to navigate.
:::

## It is a layer, not a dependency

Every feature degrades to nothing if the script never loads. Write the semantic Markdown first and let the kit enrich it — the document must read correctly with JavaScript disabled, and light/dark still works, because that lives in `base.css`.

::: {.pullquote}
If the page needs the script to make sense, the markup was wrong.
:::

## Opting out

A document whose shape does not fit the kit — several `article` elements under `main`, say — simply does not load `base.js`, and keeps its own scripts. `base.css` still gives it the whole design system and automatic light/dark. The preconditions above then do not apply to it.
