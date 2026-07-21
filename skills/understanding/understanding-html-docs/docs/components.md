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

The `comments` bundle is the worked example of the *second* clause without the
first: it loads **no engine** and needs no network (its highlight, storage, and
export are all vanilla), yet it is Tier 2 — because commenting is a mode most
documents do not want, and its JS has no business being shipped to every document
via `base.js`. Engine-free is not the same as costless; opt-in JS is a real
inclusion cost, so the bundle is the right home.

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
| the reference site demo | the component is **known** — it is the catalog documenting what the component means |
| SKILL.md's *Semantics → element / class* index | the component is **permitted** — the generator uses this index as its allowlist |

A component present in one and absent from another is worse than absent from all
three. A class in `base.css` but missing from the index **cannot be authored into a
document** (the generator emits only indexed markup); a class with no demo has nothing
documenting what it means. This is why "add a component" is never a one-file change.

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
- **No build step — reversed (2026-07); authoring now builds, output still does
  not. The build is the one path — there is no hand-authoring route.** The original
  rule: a runtime floor of shell + jq, distribution by *an agent copies files by
  instruction*, and no build anywhere. It has been deliberately overturned **for
  authoring** — every page is now written as semantic Markdown (Markdown + fenced divs) and
  run through a **pandoc** build that emits the HTML (the generator this skill owns; see
  SKILL.md, *Producing a page*). What changed is only the *authoring* side: a page is
  generated, not typed, and pandoc is a real runtime resolved by preflight, so the
  shell+jq floor no longer holds for producing a page. What did **not** change is the
  *output* — the generated site is still plain static HTML that opens on a double-click,
  ships no build tooling, and needs no server. The no-build property that actually
  mattered to a reader is intact; only the author builds now. Why it was worth
  overturning: the copy-by-instruction model could never *guarantee* the mechanical
  contract — an invented class, an inline color, an unwrapped table, an unknown callout
  variant all rendered plausibly and shipped — and the generator makes those
  structurally impossible (unknown variant = hard build error, every table wrapped, raw
  HTML dropped). That is the trade the reversal makes: an authoring-time build in
  exchange for a mechanical contract that cannot be gotten wrong. The reversal went all
  the way — hand-authoring was kept as a fallback for one release (2026-07) and then
  **removed**, because a fallback that forfeits the mechanical contract is exactly the
  hole the generator exists to close. *Reopen* the question only if pandoc becomes
  unavailable at authoring time and those guarantees are judged not worth the runtime —
  and that would mean re-introducing an authoring path, not flipping a switch.
- **No linter.** `check.sh` is deliberately absent, not missing; SKILL.md gives the
  argument. The one line worth repeating: the errors that matter are well-formed, so
  a class check proves almost nothing. **Reversing "No build step" did not reverse
  this.** The generator is not a linter: it enforces the *mechanical* contract at
  generation time (an unknown variant fails the build) — that is generation refusing to
  emit malformed markup, not a checker passing judgment on a finished document. The
  errors that matter are still well-formed — a `tip` wrapped around a hazard builds
  cleanly and lies — so the *semantic* gap the generator cannot close stays real. But
  it earns no general review step: it is either low-stakes cosmetic (a reading site
  skips it) or a consumer's own axis that the consuming skill internalizes (see
  SKILL.md's *On reviewing a generated document*).
- **No new hue, and no color-coding by position.** SKILL.md's color principle is the
  rule; the design consequence is that **prose is preferred to another color**, and a
  component that needs a new hue to be legible is usually a component that needs a
  better name.
