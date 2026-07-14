# The component system

Why this design system is shaped the way it is, and what governs a change to it.
Read it before adding, moving, or refusing a component.

It is not a manual. The catalog, the color model, the forbidden list, the bundles,
and the consumption modes are all in [`../SKILL.md`](../SKILL.md) and the reference
site — the site is the contract, and it is written in the system it documents. This
document carries only what neither of them can state: what a component *is for*,
what rule decides where it goes, and where the model runs out.

---

## 1. What a component is

A component is **a unit of the document's vocabulary that binds a meaning to a
presentation.** The author writes "this is a hazard", never "make this box red"; the
reader learns the code once and reads faster everywhere after.

So the catalog is a **vocabulary, not a component library** in the software sense.
Adding to it is not a feature — it is a change to the language every document is
written in, and every authoring agent must hold it. That is the bar a new component
has to clear.

Two properties follow, and between them they generate the rest of the system.

**Meaning is the interface.** A component is chosen for what it *says*, not how it
looks. This is why color carries exactly one meaning, and why a component with two
plausible meanings is a design error rather than a convenience.

**The vocabulary must be closed and small.** It has to be held in one head — an
authoring agent picking a class, a reviewer judging whether the pick was right. A
vocabulary too large to hold is one nobody can be held to. This is the reason to
resist a new component even when its CSS is free.

Both properties rest on one fact, which SKILL.md states and which is worth taking
seriously here: **nothing type-checks any of this.** A wrong class does not fail —
it renders plausibly and misleads. Correctness is therefore a *reading judgement*,
which is why enforcement is a review and not a linter, and why the catalog it judges
against must stay small enough to read.

---

## 2. The architecture

### The tiers sort by cost, not importance

Tier 0 (foundation), Tier 1 (the class catalog and `base.js`), Tier 2 (opt-in
bundles) are not a ranking. They sort components by **what it costs to ship one that
a document never uses.**

That is the whole rule, and it decides where a new component goes. Pure CSS has no
marginal cost, so gating it behind a bundle is machinery for nothing. **A bundle is
justified by a real inclusion cost** — a network-loaded engine, or JS that would
otherwise be forced on every document. Not by a component being large, or advanced,
or new.

### `base.js` is the enhancement kit, not a component runtime

Two consequences that are invisible in the code and easy to violate:

- **Component JS belongs in that component's bundle.** Putting it in `base.js` ships
  it to every document, which is exactly what the cost axis exists to prevent.
- **A component that carries an internal heading pollutes the table of contents.**
  `base.js` indexes *every* `h2`/`h3` inside `main article` (`base.js:78`) to build
  the TOC, the sidebar index, and the progress bar. `.keypoints` is styled for an
  `h2` but the reference site demonstrates it with an `h3` for this reason. A
  component wants the smallest heading that works, or none.

### Base owns the wiring; the consumer owns the meaning

The **promotion criterion**: a component belongs in the base when it is a *generic
document-reading pattern*, and stays in the consuming skill when it encodes *that
consumer's domain*. The line runs between how a thing looks and how its engine is
wired (base) and what it means (consumer).

Two rulings pin it, because the code alone cannot:

- A diagram engine's **palette hook**, so diagrams inherit the document's colors, is
  **base**. It is engine wiring, not content.
- The **meaning** of explain-diff's high/med/low risk axis is **consumer**. The base
  hands it hues; it does not know what they rank.

The base owns engine wiring for a reason: a consumer that re-derives an integration
drifts from it. The bundle is what it inherits instead of re-deriving.

### The contract is the stylesheet — and three artifacts must agree

This is the load-bearing structural fact of the whole system, and it is why a
framework was never adopted (§3).

**A class that is not in `base.css` does not exist.** The vocabulary an authoring
agent may use and the vocabulary the CSS supports are therefore the same set — which
is what makes the closed vocabulary of §1 actually enforceable rather than
aspirational.

But that set is expressed in three places, and they must not drift:

| Artifact | Its role |
|---|---|
| `base.css` (or a bundle's CSS) | the component **exists** |
| the reference site demo | the component is **known** — it is the catalog, and what a review judges documents against |
| SKILL.md's *Semantics → element / class* index | the component is **permitted** — [[understanding-html-docs-review]] uses this index as its allowlist |

A component present in one and absent from another is worse than absent from all
three. A class in `base.css` but missing from the index is reported as a **forbidden
class in every document that uses it**; a class with no demo cannot be judged at all.
This is why "add a component" is never a one-file change.

---

## 3. Where the model runs out

### Tier 1 is not unconditionally free

The cost axis says pure CSS costs nothing to include, and that is true only up to a
point. In **inline mode** (SKILL.md) `base.css` is pasted into every generated
document, so each pure-CSS component in it is paid for by documents that never use
it.

So the horizon is: **`base.css` for what most documents use, a CSS-only bundle for
the niche** — and a CSS-only bundle is a legitimate shape, not a degenerate one
(`diagram/diagram.css` is three lines). "Most documents" is checkable: the consumers
are `understanding-explain-diff` and `pdf-studio`. If neither would reach for it,
it is niche.

### The review surface is what limits growth, not the CSS

Writing a component is O(1) and cheap — usually a CSS rule and a demo. But every
component adds a permanent cell to a surface that is checked **by eye**: *components
× {light, dark} × {narrow, wide}* (the layout changes at 79rem, where the table of
contents becomes a sidebar index). Across the catalog that is O(N), and it is the
thing that will stop the catalog from growing. Any plan that assumes the CSS is the
constraint is looking at the wrong number.

### What does not belong here

The base makes **explanation documents** — a diff explained to a reviewer, a paper
explained to a reader. A component that exists to help someone *perform a task*
rather than *understand* one is product documentation: Tabs and CodeGroup switching
between per-OS install commands, a copy-to-clipboard button.

If one of those starts to feel necessary, treat it as a **signal, not a
requirement**: the output has drifted toward product documentation, and the question
to ask is whether the base still serves a single document type — not how quickly the
component can be added.

### Standing prohibitions, and what would reopen them

Absence leaves no trace in the code. An agent who cannot see why something is missing
will helpfully add it back.

- **No CSS framework.** Not because frameworks are bad — Bulma fits every constraint
  this system has — but because the contract *is* the stylesheet (§2). A framework
  breaks that: you would either expose its whole combinatorial surface to an
  authoring agent or police a foreign vocabulary the CSS still happily supports.
  *Reopen if* the documents come to need an application-UI vocabulary (nav bars,
  modals, forms); at that point the calculus genuinely changes.
- **No build step.** The runtime floor is shell + jq and the distribution model is
  *an agent copies files by instruction*. `core + bundle + include.md` already
  achieves opt-in with plain file copies. *Reopen if* the substrate ever needs to be
  tree-shaken per document.
- **No linter.** `check.sh` is deliberately absent, not missing; SKILL.md gives the
  argument. The one line worth repeating: the errors that matter are well-formed, so
  a class check proves almost nothing.
- **No new hue, and no color-coding by position.** SKILL.md's color principle is the
  rule; the design consequence is that **prose is preferred to another color**, and a
  component that needs a new hue to be legible is usually a component that needs a
  better name.
