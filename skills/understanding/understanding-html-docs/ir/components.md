---
title: Components — understanding-html-docs
site-name: understanding-html-docs
back-link: "← Back to the index"
---

::: {.kicker}
COMPONENTS
:::

# Components

::: {.lede}
The parts you opt into with a class. **A class selects a meaning, not a look** —
you reach for `danger` because the thing is dangerous, and red is the consequence.
:::

## Callout — a message box that means something

Lifts a passage out of the prose. The variant fixes the meaning, and the meaning
fixes the color and the icon. The bare `.callout` class is itself the note
(information) variant.

| To say | Author |
|---|---|
| General supporting information | `.callout` |
| Advice worth following | `.callout.tip` |
| Something to be careful about | `.callout.warn` |
| A hazard — this breaks, this destroys | `.callout.danger` |
| The key insight | `.callout.key` |

::: {.callout}
[Note]{.label} — general supporting information.
:::

::: {.callout variant=tip}
[Tip]{.label} — advice worth following.
:::

::: {.callout variant=warn}
[Warn]{.label} — something to be careful about.
:::

::: {.callout variant=danger}
[Danger]{.label} — a hazard, a destructive step.
:::

::: {.callout variant=key}
[Key]{.label} — the key insight.
:::

`.label` is an optional lead-in, bolded in the callout's own meaning color. Those
five are the only variants — `warning` and `error` do not exist, and writing one renders a plain note instead of failing.

```{.nohighlight}
<div class="callout danger">
  <span class="label">Danger</span> — body text.
</div>
```

## Keypoints — what a section boils down to

A few lines that carry the section. Being a takeaway is not something a color
should say, so this box takes no meaning color — it is drawn in the accent.

::: {.keypoints}
### This section in short

- Put a heading (`h2`/`h3`) and a `ul` inside it
- The color is the accent — there is nothing to choose
- Never a meaning color (tip / warn / danger)
:::

```{.nohighlight}
<div class="keypoints">
  <h3>This section in short</h3>
  <ul><li>A takeaway</li></ul>
</div>
```

## Card / Card grid — things that are peers

A bordered block, and a grid that lays a set of them out and reflows. For items
that stand side by side as equals. The content is up to you.

:::: {.card-grid}
::: {.card}
**Card**

A bordered block. A neutral container.
:::
::: {.card}
**Any content**

Headings, prose, lists, code — whatever fits.
:::
::: {.card}
**Reflows**

The grid changes its column count with the width.
:::
::::

```{.nohighlight}
<div class="card-grid">
  <div class="card">…</div>
  <div class="card">…</div>
</div>
```

## Chip / Badge — small labels

`.chip` is an outlined, muted pill for a tag or a classification. `.badge` is its
filled counterpart, for a status or a count that should carry weight.

[muted chip]{.chip}
[accent chip]{.chip .accent}
[NEW]{.badge}
[3]{.badge}

```{.nohighlight}
<span class="chip">a tag</span>
<span class="chip accent">a louder tag</span>
<span class="badge">NEW</span>
```

## Setting the rhythm of the prose

### Kicker — an eyebrow above a heading

::: {.kicker}
KICKER
:::

### Lede — the opening paragraph

::: {.lede}
Slightly larger and muted, it forms the way in to the body. One per document or page.
:::

### Pullquote — one line, said louder

::: {.pullquote}
The quote marks take the accent, and one line in the prose raises its voice.
:::

### Aside — a quiet remark

::: {.aside}
A footnote-ish remark with no icon and no meaning color. It does not raise its
voice the way a callout does; it just steps slightly aside from the prose. This is
the class, not the bare `<aside>` element.
:::

```{.nohighlight}
<p class="kicker">KICKER</p>
<h2>A heading</h2>
<p class="lede">The opening paragraph.</p>
<p class="pullquote">One line, said louder.</p>
<div class="aside">A quiet remark.</div>
```
