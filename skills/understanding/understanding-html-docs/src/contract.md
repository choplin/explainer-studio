---
title: Contract & review — understanding-html-docs
site-name: understanding-html-docs
back-link: "← Back to the index"
---

::: {.kicker}
CONTRACT
:::

# Contract & review

::: {.lede}
A wrong choice in this system does not fail — it renders *plausibly*. So the rules are written down, and a generated document is read back against them.
:::

## Why a contract at all

Nothing here raises an error. A misspelled variant draws a plain note. An inline hex color looks right until the reader switches to dark. An unwrapped table looks right until the screen is narrow. The failure always survives as a plausible-looking success — which means it will not be found by looking at the page, only by comparing the page against a rule.

## The rules

::: {.keypoints}
### Forbidden

- **A class nothing defines.** Not in `base.css`, not in the page's own `<style>`, not in a shipped component's `include.md`.
- **A raw color in a `style` attribute.** It bypasses the token layer and breaks in dark theme. Go through `var(--token)`.
- **A primitive read from a component rule.** Component CSS reads semantic tokens only; the semantic tokens are the only layer allowed to name a primitive.
- **A `<table>` outside `.tablewrap`.**
- **A meaning color used as decoration**, and any new ad-hoc hue. Prefer prose over another color.
- **A Tier 2 marker without its bundle.**
:::

The structure of the document is **not** constrained. This site's shape is a reference worth copying, not a mandate: a document whose job needs a different skeleton — several `article` elements under `main`, no `base.js` — is not in violation. It just does not get the parts of the kit it opted out of.

## Not linted — and no general review

There is deliberately **no linter**. A checker can tell you that a class *exists* — and knowing that is worth almost nothing, because the errors that matter are all **well-formed**. A `.callout.tip` wrapped around a hazard passes every conceivable class check, renders as a perfectly good green box, and tells the reader the opposite of the truth.

::: {.pullquote}
Whether a class exists is not the question. Whether it was used as intended is.
:::

That question is a *semantic* one, and once the page is generated from the source it splits in a way that leaves no general review step to run. The **mechanical** half — a nonexistent class, a name borrowed from another system, an unwrapped table, an inline color — is made **impossible to emit** by the generator, so there is nothing to review. The **semantic** half is either low-stakes cosmetic, which a reading site skips by policy, or a consuming skill's own axis, which that skill **internalizes as its own completion check** (as `understanding-explain-diff` does for its `risk`/`tested`/`verified` values).

::: {.keypoints}
### The semantic gap the generator cannot close

- A callout whose variant does not match what it says — and one that should not have been a callout at all.
- A `.keypoints` that is not the section's takeaways.
- A meaning color spent on decoration.
- A heading used to make a line bold, and a section with no heading, invisible to the table of contents.
- A Tier 2 marker whose bundle was never shipped.
:::

## Adding a component

::: {.keypoints}
### What it has to satisfy

- Styled with semantic tokens only — never a primitive.
- Holds up in both light and dark.
- The prose still reads with no JavaScript (progressive enhancement).
- Carries a meaning color *or* no color — never a meaning color for emphasis.
- **Demonstrated on one of these pages.** This site is the living catalog — the worked example that documents what every component means.
:::

::: {.pullquote}
A component that is not shown here does not exist.
:::
