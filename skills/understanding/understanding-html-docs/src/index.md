---
title: Writing an explanation document — understanding-html-docs
site-name: understanding-html-docs
---

::: {.kicker}
REFERENCE
:::

# Writing an explanation document

::: {.lede}
A design system and a progressive-enhancement kit for writing an
explanation as a readable web document. This site is itself written
in it — **what you see here is everything there is**.
:::

## Wire it in

Two modes; pick by the shape of the output.

:::: {.card-grid}
::: {.card}
**Copy — a multi-page site**

Put `base.css` / `base.js` in a
shared `assets/` directory and reference them
from every page. This site uses this mode.
:::
::: {.card}
**Inline — one file**

Paste `base.css` into a
`<style>` and `base.js` into a
`<script>`, and ship a single portable
HTML file.
:::
::::

Either way, **copy the assets**. Never link to the
base's install path — the document would stop being
self-contained.

## The skeleton — what the template emits

You never hand-write this. You write only the body — a `#` title,
`##` / `###` sections, prose — as semantic Markdown, and the generator
wraps it in the page skeleton below. It is shown here as the **output
contract**, not as something to author: the theme button mounts into
`header.site`, and the table of contents and the reading-progress bar
are built from the `h2` / `h3` headings (your `##` / `###`) inside
`main > article`.

```{.nohighlight}
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>…</title>
  <script>try{var t=localStorage.getItem('html-docs-theme');if(t==='dark')document.documentElement.classList.add('theme-dark');else if(t==='light')document.documentElement.classList.add('theme-light');}catch(e){}</script>
  <link rel="stylesheet" href="assets/base.css">
  <script src="assets/base.js" defer></script>
</head>
<body>
  <header class="site"><a href="index.html">Site name</a></header>
  <main>
    <article>
      <h1>Document title</h1>
      <p class="lede">One opening paragraph.</p>
      <section>
        <h2>A section</h2>
        <p>Body text.</p>
      </section>
    </article>
  </main>
</body>
</html>
```

::: {.callout variant=danger}
[The boot key must match]{.label} — the storage
key in the `<head>` snippet has to be the same as
`base.js`'s `THEME_KEY`. If they drift, the
saved theme silently stops applying and the page flashes on load.
:::

## Write it

::: {.keypoints}
### The pages

- [Foundation](foundation.html) — what works with
  no class at all: headings, prose, tables, code, quotes.
- [Color model](color.html) — color carries
  meaning and nothing else. The token layers.
- [Components](components.html) — the parts you
  opt into with a class: callout, keypoints, card.
- [Progressive enhancement](enhancement.html) —
  what `base.js` adds, and what it needs from
  your markup.
- [Tier 2 components](tier2.html) — optional
  bundles with a heavy engine: highlighting, diffs,
  diagrams.
- [Contract & review](contract.html) —
  the rules, and how a generated document is reviewed against them.
:::

::: {.aside}
There is no inter-page navigation yet. Come back to this index
from each page.
:::
