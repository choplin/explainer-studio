---
name: explainer-reading-site-consistency-sweep
description: "Internal fan-in worker invoked by explainer-reading-site-generate-base after every semantic source is authored and before the site is built. Reads the complete src set and returns findings about page-anchor markup and cross-page structural drift; it does not edit files."
user-invocable: false
---

# Reading-site source consistency sweep

Parallel page authors work in isolated contexts. Each page can be internally
coherent and build successfully while the finished site mixes markup vocabularies
or structural conventions. This procedure is the whole-set pass at the fan-in
boundary: read every semantic source together, compare them against one canonical
authoring contract, and return findings only.

The generator catches unknown markup. It cannot catch an author who omits required
markup and writes legal plain Markdown, so a successful build is not a substitute
for this sweep.

## When this applies

`explainer-reading-site-generate-base` applies this procedure after all report pages
and `src/index.md` have been authored, and before the one site build. When isolated
subagents are available, dispatch one sweep worker so only its findings return to
the orchestrator; otherwise apply it inline. It is not invoked directly by users.

## Inputs provided by the caller

If any is missing, report what is missing and stop.

- Absolute paths to **every** semantic source under `<WORK_DIR>/src/`, including
  `index.md`.
- The canonical site-wide authoring conventions passed identically to every page
  worker.
- The Phase 1 ordered `[{ slug, kicker }]` profile, so required pages, order, and
  kicker labels can be checked without inferring them from the authored output.
- The site title and the consumer's landing vocabulary (guide kicker,
  cards-section heading, and count-chip unit), so landing structure is checked
  against its actual contract rather than guessed.

## Canonical page-anchor grammar

A source-PDF page reference in prose has exactly one of these forms:

- single page: `[p31]{.p}`;
- page range: `[p31–p33]{.p}` (en dash, one `.p` span around the whole range).

It must not appear in an ATX heading (`#` through `######`). If a heading is its
only occurrence, the minimal fix is to move it to the first following paragraph;
if the paragraph already has the same reference, delete only the heading copy.
Sentence punctuation follows the anchor (`… [p14]{.p}。`), keeping the reference
inside the sentence it supports.

Do not reinterpret lookalikes that are not prose source references: fenced or
inline code, image alt text, and table-header placeholders such as `| [pNN] |`.
Read Markdown structure and context; do not report matches from a blind regex pass.

## What to check

Read the complete source set before reporting anything.

1. **Page-anchor vocabulary.** Find every prose source reference that is bare,
   split, malformed, or uses a non-canonical range form. Check both single anchors
   and ranges; matching only `\[p\d+\]` is insufficient.
2. **Heading placement and punctuation.** Find anchors in headings and anchors
   stranded after sentence punctuation. State whether the heading anchor must move
   or can be deleted because the following body already preserves it.
3. **Required page structure.** Each report page has one kicker, one H1, one lede,
   and one keypoints box, in that opening order; its kicker matches the profile.
   The landing has the landing structure defined by the caller and no report-page
   anchor hidden in a heading or card title.
4. **Cross-page drift.** Compare the pages side by side for the same semantic
   element expressed with different markup or placed in different structural
   locations. Report only site-wide vocabulary or structure differences—not prose
   taste, chapter-specific content, or the legitimate absence of an optional
   component.
5. **Profile coverage.** Every profile slug has one report source, no extra report
   source masquerades as a profile page, and page kickers agree with the fixed
   profile.

## What not to do

- Do not edit semantic sources or generated HTML. The orchestrator applies targeted
  fixes and reruns the sweep.
- Do not flatten meaningful page-specific structure merely to make files textually
  identical.
- Do not flag an optional callout, figure, pullquote, table, code block, or player
  merely because another page does not contain one.
- Do not accept a passing build as evidence that required markup was used.

## Reply

Return only a findings list. If clean, say:

`sweep clean — N sources checked; page-anchor grammar, heading placement, required structure, and profile coverage are consistent`

Otherwise return one item per finding, ordered by impact, with:

- `type`: `bare-anchor` / `range-anchor` / `heading-anchor` /
  `anchor-punctuation` / `required-structure` / `cross-page-drift` /
  `profile-coverage`;
- `locus`: source path and heading or line precise enough for a targeted edit;
- `observed`: the conflicting or invalid form;
- `canonical`: the convention it must follow;
- `minimal fix`: move, replace, add, or delete only the smallest necessary span.
