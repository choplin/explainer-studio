---
name: explainer-reading-site-consistency-sweep
description: "Internal fan-in worker invoked by explainer-reading-site-generate-base after every semantic source is authored and before the site is built. Reads the complete src set plus canonical source structure and returns findings about source attribution, page-anchor markup, and cross-page drift; it does not edit files."
user-invocable: false
---

# Reading-site source consistency sweep

Parallel page authors work in isolated contexts. Each page can be internally
coherent and build successfully while presenting a site-authored hierarchy as if
it came from the source, or while the finished site mixes markup vocabularies and
structural conventions. This procedure is the source-integrity pass at the fan-in
boundary: read every semantic source together, compare source-derived headings
against the canonical source structure, compare the set against one authoring
contract, and return findings only.

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
- Absolute path to the consumer's canonical source-structure artifact. This is
  `<WORK_DIR>/structured/toc.md` for PDF explainers and
  `<WORK_DIR>/source-structure.md` for paper explainers.
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

1. **Structural source attribution.** For every report page, classify each
   flowing-body H2/H3 from its explicit semantic class:
   - `.source-structure` must map to a real entry in the canonical source
     structure, with the same hierarchy, source-form title or faithful display
     translation, and canonical anchor in the first following claim;
   - `.editorial-structure` is site-authored and may restructure the reading
     path, but must not use source-native Part/Chapter/Section labels or a
     source-like numbering scheme;
   - editorial headings must not reparent or demote real source divisions. A
     thematic grouping may reference source units as list/table/card content,
     while the source heading tree retains its relative hierarchy;
   - a body heading with both classes or neither class is invalid. Headings
     inside semantic components such as `.keypoints`, and landing headings, are
     exempt.
   A page with editorial headings must carry non-empty localized
   `editorial-structure-label` and `editorial-structure-note` frontmatter, and
   both values must exactly match the canonical strings passed to every worker.
   This is a per-page source-attribution check, not cross-page drift; meaningful
   page-specific structure is allowed only when its editorial provenance is explicit.
2. **Page-anchor vocabulary.** Find every prose source reference that is bare,
   split, malformed, or uses a non-canonical range form. Check both single anchors
   and ranges; matching only `\[p\d+\]` is insufficient.
3. **Heading placement and punctuation.** Find anchors in headings and anchors
   stranded after sentence punctuation. State whether the heading anchor must move
   or can be deleted because the following body already preserves it.
4. **Required page structure.** Each report page has one kicker, one H1, one lede,
   and one keypoints box, in that opening order; its kicker matches the profile.
   The landing has the landing structure defined by the caller and no report-page
   anchor hidden in a heading or card title.
5. **Cross-page drift.** Compare the pages side by side for the same semantic
   element expressed with different markup or placed in different structural
   locations. Report only site-wide vocabulary or structure differences—not prose
   taste, chapter-specific content, or the legitimate absence of an optional
   component.
6. **Profile coverage.** Every profile slug has one report source, no extra report
   source masquerades as a profile page, and page kickers agree with the fixed
   profile.

## What not to do

- Do not edit semantic sources or generated HTML. The orchestrator applies targeted
  fixes and reruns the sweep.
- Do not flatten meaningful page-specific editorial structure merely to make files
  textually identical. Do require that it be typed and visibly attributed.
- Do not flag an optional callout, figure, pullquote, table, code block, or player
  merely because another page does not contain one.
- Do not accept a passing build as evidence that required markup was used.

## Reply

Return only a findings list. If clean, say:

`sweep clean — N sources checked; source attribution, page-anchor grammar, heading placement, required structure, and profile coverage are consistent`

Otherwise return one item per finding, ordered by impact, with:

- `type`: `source-attribution` / `bare-anchor` / `range-anchor` / `heading-anchor` /
  `anchor-punctuation` / `required-structure` / `cross-page-drift` /
  `profile-coverage`;
- `locus`: source path and heading or line precise enough for a targeted edit;
- `observed`: the conflicting or invalid form;
- `canonical`: the convention it must follow;
- `minimal fix`: move, replace, add, or delete only the smallest necessary span.
