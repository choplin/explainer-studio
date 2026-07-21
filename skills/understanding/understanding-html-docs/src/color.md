---
title: Color model — understanding-html-docs
site-name: understanding-html-docs
context-css: color.css
back-link: "← Back to the index"
---

::: {.kicker}
COLOR
:::

# Color model

::: {.lede}
**Color carries meaning, and nothing else.** Everything that is colored without
meaning anything collapses into a single accent. Learn the code once and every
document reads the same way.
:::

## Colors that mean something

The mapping is fixed. **Never borrow a meaning color for decoration** — red says
"hazard", not "look here".

| Meaning | Token | Hue | Where it shows |
|---|---|---|---|
| Information | `--note` | blue | `.callout` |
| Advice | `--tip` | green | `.callout.tip` |
| Caution | `--warn` | amber | `.callout.warn` |
| Hazard | `--bad` | red | `.callout.danger` |
| Key insight | `--key` | violet | `.callout.key` |
| A highlighted phrase | `--mark` | yellow | `<mark>` |

## Colors that mean nothing — one accent

Links, the reading-progress bar, the current entry in the table of contents,
`.keypoints`, `.kicker`, the quote marks of a `.pullquote`. These are colored, but
the color is not saying anything. They all take `--accent`.

::: {.callout variant=key}
[No color-coding by position]{.label} — chapters and pages are not assigned their
own hues. A reader cannot tell "chapter 5 red" from "hazard red", so
position-coding would break the very code the semantic colors depend on. "Where am
I" is answered by navigation and headings, not by color.
:::

## Three token layers

Color reaches the screen through three layers. **A component rule may read only the
middle one.**

| Layer | Example | Who may read it |
|---|---|---|
| Primitives — raw color | `--n-900`, `--blue-strong` | Only the semantic tokens |
| Semantic tokens — roles | `--fg`, `--edge`, `--warn`, `--accent` | **Component rules** |
| The rules themselves | `.callout`, `.card`, … | — |

To re-theme, edit the primitive layer alone. Light and dark are not two palettes:
every token holds a `light-dark()` pair, so there is nothing to keep in sync.

## The primitive palette

Every color comes from these ramps. **A component rule never reads them directly** —
it goes through a semantic token.

### Neutral ramp — surfaces, text, borders

::: {.ramp tokens="--n-0,--n-100,--n-300,--n-500,--n-700,--n-850,--n-950"}
:::

### Chromatic ramp — one hue, one meaning

Each hue is spoken for by exactly one meaning. The ramp is deliberately no longer
than the meanings it serves, so **a color can never say two things**. Each swatch
shows its light step and its dark step.

:::: {.card-grid}
::: {.swatch bg="linear-gradient(90deg, var(--blue-strong) 50%, var(--blue-bright) 50%)" name="blue" namecolor="--accent" val="accent + note"}
:::
::: {.swatch bg="linear-gradient(90deg, var(--green-strong) 50%, var(--green-bright) 50%)" name="green" namecolor="--tip" val="tip"}
:::
::: {.swatch bg="linear-gradient(90deg, var(--amber-strong) 50%, var(--amber-bright) 50%)" name="amber" namecolor="--warn" val="warn"}
:::
::: {.swatch bg="linear-gradient(90deg, var(--red-strong) 50%, var(--red-bright) 50%)" name="red" namecolor="--bad" val="danger"}
:::
::: {.swatch bg="linear-gradient(90deg, var(--violet-strong) 50%, var(--violet-bright) 50%)" name="violet" namecolor="--key" val="key"}
:::
::: {.swatch bg="var(--mark)" name="yellow" val="<mark>"}
:::
::::

## When you want another color

::: {.keypoints}
### Before you add one

- **Try prose first.** Every color is one more thing the reader has to learn.
- If you still need it, then it is a **new meaning**. Define it as a semantic axis in the consuming skill's own stylesheet, on a hue that does not collide with the ones above.
- Never add a color for decoration.
:::

::: {.callout variant=danger}
[Never write a raw color]{.label} — `style="color:#e11"` bypasses the token layer
and breaks in dark theme. Always go through `var(--token)`.
:::
