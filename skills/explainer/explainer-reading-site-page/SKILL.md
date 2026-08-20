---
name: explainer-reading-site-page
description: "Internal per-report authoring procedure invoked by explainer-reading-site-generate-base. Restructures one report as semantic Markdown for deterministic generation by explainer-html-docs."
user-invocable: false
---

# Site page authoring

You turn one report Markdown file into one **semantic Markdown file** (Markdown + fenced divs) that is *designed for the web*: restructured for scanning on a phone, not a mechanical rendering of the source. The [[explainer-html-docs]] generator turns your semantic Markdown into the final HTML page — you never write HTML, `<head>`, presentation-only classes outside the vocabulary below, or asset links, and you never rewrite figure paths or escape characters. Those are the generator's job and it cannot get them wrong. **Your whole job is meaning and structure**: preserve the source's own topology, then add a clearly attributed editorial reading path where it improves comprehension.

`Restructure` in this skill means **source-faithful editorial restructuring**. It
does not mean silently replacing the source's parts, chapters, sections, or
hierarchy. Source structure and site-authored structure are separate semantic
layers throughout authoring, generation, and navigation.

## When this applies

The shared reading-site generator applies this procedure once per report file, in
parallel. It is not for direct user requests and is not invoked proactively.

## Inputs provided by the caller

The caller provides the following. If any is missing, report what is missing and stop.

- Absolute path to the source report Markdown
- Absolute path to the canonical source-structure artifact. For PDF explainers
  this is `<WORK_DIR>/structured/toc.md`; for paper explainers it is
  `<WORK_DIR>/source-structure.md`; for EPUB explainers it is
  `<WORK_DIR>/structured/toc.md` plus the caller-supplied
  `<WORK_DIR>/epub/locators.json`. Read it before authoring and treat it as the
  authority for which parts/chapters/sections exist, their hierarchy, their
  source-form titles, and their page anchors.
- Absolute output path for the source (`<WORK_DIR>/src/<slug>.md`)
- Site title, and this page's kicker label (e.g. 第2章 / 全体レポート)
- Whether PDF `<WORK_DIR>/ocr/figures/` or EPUB `<WORK_DIR>/epub/media/` exists
  (the caller copies the applicable source media into the site)
- Audio file name under `site/audio/` if a matching guide exists (else "none")
- The canonical site-wide authoring conventions from the caller, including the
  source-locator grammar and the exact site-wide editorial-structure label and note.
  Treat them as requirements, not suggestions; copy the two attribution strings
  verbatim rather than translating them page by page. If the conventions conflict
  with this skill, report the conflict and stop rather than choosing a page-local
  convention.

## The source you write

Write a Markdown file with this frontmatter, then the body in the semantic-Markdown vocabulary below. The frontmatter is boilerplate — keep it **verbatim except** `title` and the two localized structure-attribution strings; it wires the page chrome and the asset order (the generator owns `<head>`, theme-boot, and asset links from it):

```yaml
---
title: <PAGE_TITLE> — <SITE_TITLE>
site-name: "← <SITE_TITLE>"        # header link back to the index
editorial-structure-label: "<exact EDITORIAL_STRUCTURE_LABEL from caller>"
editorial-structure-note: "<exact EDITORIAL_STRUCTURE_NOTE from caller>"
context-css:
  - reading-site.css                 # shared reading-site content styling
  - reading-nav.css                # reading-nav widget chrome (explainer-html-docs component)
context-js:
  - nav-manifest.js                # page-nav data — must load before the script that reads it
  - reading-nav.js                 # reading-nav widgets (explainer-html-docs component)
---
```

Body vocabulary — reach only for these; the generator rejects anything else (an invented class or raw HTML cannot pass, an unknown callout variant is a hard build error):

| To express | Write in the semantic Markdown |
|---|---|
| The kicker label (第N章 / 全体レポート) | `::: {.kicker}` … `:::` (the label passed by the caller) |
| The page title | `# <PAGE_TITLE>` |
| Opening 2–3 sentences (what this covers, why it matters) | `::: {.lede}` … `:::` |
| The takeaways box (3–5 bullets) | `::: {.keypoints}` with `### この章のポイント` + a `- ` list `:::` |
| A source-authored section / subsection | `## … {.source-structure}` / `### … {.source-structure}` |
| A site-authored reading section / subsection | `## … {.editorial-structure}` / `### … {.editorial-structure}` |
| General note / aside | `::: {.callout}` … `:::` (bare = note) |
| Advice / caution / hazard / key insight | `::: {.callout variant=tip\|warn\|danger\|key}` … `:::` |
| A colored lead-in inside a callout | `[結論:]{.label}` at the paragraph start |
| One striking sentence (≤1 per page) | `::: {.pullquote}` … `:::` |
| An inline highlighted term | `[term]{.mark}` |
| A source-PDF page anchor | `[p31]{.p}` / `[p31–p33]{.p}` |
| An EPUB source locator | `[Chapter 3 › Section]{.source-locator data-locator="OEBPS/Text/ch03.xhtml#section"}` |
| A harvested figure | `![説明](../ocr/figures/fig-p031-1.jpg)` — **carry the source path as-is**; the generator rewrites `../ocr/figures/` → `figures/` so nothing points outside the site |
| Original EPUB media | `![説明](../epub/media/OEBPS/Images/figure.svg)` — keep the source path; the generator rewrites it to `media/…` |
| An in-page audio player (only if the caller gave an audio file) | `::: {.player src=audio/<file>}` `:::` |
| Tabular data | a plain Markdown table — wrapped in `.tablewrap` automatically |
| A code sample | a ` ```{.nohighlight} ` fenced block |
| Prose, lists, blockquotes, links | plain Markdown |

The reading-site filter expands the first `.editorial-structure` heading into two
visible attribution surfaces: a disclosure immediately before it and a real-text
marker on every editorial heading. Because the marker is real heading text, the
generated sidebar retains the attribution too. Never write those disclosures or
markers by hand. The two caller-supplied frontmatter strings supply their wording.

## Constraints (meaning and structural provenance)

Everything mechanical is the generator's guarantee — you do **not** write HTML, `<head>`, presentation-only classes outside the semantic vocabulary above, asset/script tags, prev/next nav, figure-path rewrites, `<`/`>`/`&` escaping, or `.tablewrap`. What remains yours:

- **Content fidelity**: every claim in the page must come from the source report.
  Rephrase and reorganize for comprehension; do not invent content.
- **Source-structure fidelity**: `.source-structure` means the heading is a real
  division in the canonical source-structure artifact. Preserve its relative
  hierarchy (offset below the page H1 as needed) and source-form title (or a
  faithful display translation), and keep its canonical page anchor with the
  first following claim. Do not add, rename, promote, demote, or regroup source
  divisions.
- **Editorial-structure attribution**: a heading composed or renamed by the site
  uses `.editorial-structure`. It may organize a reading path around source
  material, but must not use source-native labels such as Part, Chapter, Section,
  or a source-like numbering scheme. Those labels assert source topology.
- Every flowing-body `##` / `###` heading must be classified as exactly one of
  `.source-structure` or `.editorial-structure`. Component-internal headings
  such as the title inside `.keypoints`, and landing-page headings, are exempt.
- An editorial heading may subdivide the explanation inside a source division,
  but it never owns or reparents a source division. When an editorial theme
  groups several real chapters or sections, name those source units in a list,
  table, or cards beneath the editorial heading; do not demote their source
  headings into that editorial hierarchy.
- **Every source reference uses the caller's locator kind.** PDF writes a single
  page as `[p31]{.p}` and a range as `[p31–p33]{.p}`. EPUB writes a display label
  as `.source-locator` with its mapped canonical `data-locator`. A bare or
  cross-kind reference is invalid. Do not drop locators: they are the link back
  to the source.
- **Never put a source locator in a heading.** It pollutes both the generated
  heading id and the navigation/TOC label. If the heading is the only place that
  carries the reference, move the locator into the first following paragraph; if
  that paragraph already carries the same reference, remove it from the heading.
- **Put sentence punctuation after the locator**, for example
  `…である [p14]{.p}。`, not `…である。 [p14]{.p}`. This keeps the reference
  attached to the claim it supports.
- Treat a bracketed token as a page anchor only when it is a source reference in
  prose. Do not rewrite fenced or inline code, image alt text, or a table-header
  placeholder such as `| [pNN] |` merely because it resembles one.
- **Write in the language of the source report.**
- **Carry only the media the source report actually embeds** — do not go hunting
  in PDF `figures/` or EPUB `media/` for extras. If the applicable source-media
  directory does not exist, do not invent figures. Never use bare media: place it
  where the prose discusses it, retain the explanation, and write meaningful alt
  text.
- **Do not author prev/next links.** Page-to-page navigation is rendered at runtime by `reading-nav.js` (the explainer-html-docs reading-nav component) from the site's `nav-manifest.js` (loaded via the `context-js` frontmatter) — one source for the page order. Hand-authored neighbor links are exactly the drift a single source removes.

## How to restructure (this is the point of this skill)

Do not mechanically translate the report's syntax. Author a source-faithful
editorial projection of the material:

1. Read the canonical source structure, then the whole report. Identify the
   source divisions relevant to this page and its 3–6 load-bearing ideas.
2. Write a `lede` (2–3 sentences: what this covers, why it matters) and a `keypoints` box (3–5 bullets) — these are NEW text you compose, not copied sentences.
3. Choose the lightest structure that improves reading:
   - Preserve a source division as `.source-structure` when the reader benefits
     from following the document's own topology. Do not rename it into a message.
   - Add `.editorial-structure` when a thematic reading path or explanatory
     subdivision materially improves comprehension. State its message clearly,
     but do not make it resemble a source-native division.
   - To group source chapters thematically, use an editorial heading followed by
     a list/table of the real chapter names. The heading declares that the group
     is the site's reading aid without rewriting the source heading tree.
   - A page may use either layer or both. Different headings or a different
     heading order are not evidence of successful restructuring by themselves.
4. Rebuild paragraphs for scanning: 2–4 sentences, lists where the report
   rambles, and tables kept as tables. Reordering is allowed only within the
   declared editorial layer; it must not imply that the source used that order.
5. Promote buried material with SEMANTIC color. **Color is not volume.** "This matters, so give it a loud color" is always the wrong move — it is the single most common way these pages go wrong. A variant is chosen by *what the content does to the reader*, never by how much you want it noticed. Pick by meaning: a note/aside → `::: {.callout}`; a practical tip → `::: {.callout variant=tip}`; a caveat or pitfall → `variant=warn`; a hard prohibition or serious risk → `variant=danger`; a load-bearing insight worth boxing → `variant=key`.

   Two mistakes to avoid by name — both are real, both were the majority of what a review of these pages had to fix:

   - ✗ **A term definition in `variant=tip`.** A definition is not advice. The reader is not being told to *do* anything. Use a plain `::: {.callout}`, or just `[term]{.mark}` in the prose — most definitions do not need a box at all.
   - ✗ **A chapter's central claim in `variant=warn` / `variant=danger`.** A claim is not a hazard. That is `variant=key`. The moment `danger` is used to mean "the most important thing here", it stops being distinguishable from a real hazard, and the color is dead for the whole site.

   Before choosing `warn` or `danger`, ask: **"if the reader skips this, what breaks?"** If nothing breaks — they merely understand less — it is not `warn` and not `danger`. Use them sparingly overall (a page that is all callouts flattens the signal). One genuinely striking claim → `::: {.pullquote}` (at most one per page; skip if nothing earns it). Highlight a few key terms inline with `[term]{.mark}` — a handful per page, not every noun.
6. Cut redundancy that only made sense in a linear report ("as mentioned above", section numbering artifacts, coverage notes). The runtime page nav (prev/next from `nav-manifest.js`) and the index carry the navigation now.

The quality test is whether the page exposes the source faithfully and improves
the reading path—not whether its heading sequence differs from the report.

## Output

Write the finished source to the given output path (`<WORK_DIR>/src/<slug>.md`) —
unconditionally, without prompting about an existing file. The consumer already
confirmed clearing/overwriting before dispatching. Do not run the generator
yourself; the orchestrator builds every source into HTML in one pass afterward.

Before replying, re-read the finished source and inspect its Markdown context.
Verify that every prose source reference uses the caller-selected locator kind:
PDF ranges use `.p`; EPUB references use `.source-locator`, carry a mapped
`data-locator`, and never invent `.p`. No locator belongs in a heading, and sentence
punctuation follows it. Verify separately that code, image alt text, and table-header
placeholders were not rewritten. Compare every `.source-structure`
heading with the canonical structure artifact; verify that every other body heading
is `.editorial-structure`, uses no source-like structural label, and has the two
localized attribution fields in frontmatter. Fix the page before returning if any
check fails.

## Reply

Return ONLY, in this order (never the source body):
- the output path
- the page title (the `# …` heading text)
- a 2–3 line card summary for the landing page (plain text, composed for a reader deciding whether to open the chapter)
