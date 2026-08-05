---
name: pdf-explainer-generate-site
description: "Build a static reading site from existing pdf-explainer reports, including audio guides when present. Use when reports already exist and the user wants a local site. Use explainer-reading-site-deploy to publish it."
user-invocable: true
---

# Generate Site — pdf-explainer reports as an authored website

Turn a **pdf-explainer** work dir (`<dir>/<name>/`, at least one report under
`reports/`) into a reading-guide website under `<WORK_DIR>/site/`: a landing page
with chapter cards and one authored page per report, the matching audio guide
playable in-page.

The whole build pipeline — scaffold, parallel semantic-Markdown authoring, the single
generator build, the semantic landing page, the nav manifest, the gotchas, and the
success criteria — is the **shared reading-site pipeline** owned by
[[explainer-reading-site-generate-base]]. **Delegate the build to that skill.** This skill
adds only what is pdf-specific: the canonical source-structure path, page-ordering
profile, and landing vocabulary below. Do not re-derive the pipeline here; follow
the base skill for every phase.

## When this applies

The input is a pdf-explainer work dir with reports under `reports/` and the
canonical source structure at `structured/toc.md`. `audio/` is optional (pages
without audio get no player). If reports or `structured/toc.md` do not exist yet,
run [[pdf-explainer-summarize]] first; for audio on the pages, run [[explainer-audio-dialogue]] →
[[explainer-audio-narrate]] first. This skill only *builds* the site; publishing it is
[[explainer-reading-site-deploy]]'s job.

## pdf-explainer inputs

### Canonical source structure

Pass the absolute path to `<WORK_DIR>/structured/toc.md` to the shared pipeline.
It is required: report headings are editorial artifacts and cannot establish which
parts, chapters, or sections the PDF itself contains.

### Ordered page list — `[{ slug, kicker }]`

Resolve `reports/*.md` into the base skill's ordered list this way:

- **`overview`** first, kicker `全体レポート` (the landing hero CTA / home).
- then every **`chapter-N`** in **natural order** (`chapter-2` before `chapter-10`),
  each with kicker **`第N章`** (N from the slug).
- any report matching neither is **appended last** in natural sort, with a kicker
  derived from a readable title-case of its slug. Do not drop it.

This satisfies the base contract (overview first; every existing report once;
deterministic order; non-empty kicker). Chapters are **not** color-coded — which
chapter you are in is answered by the nav, the title, and the index.

### Landing document-type vocabulary

- **guide kicker** (hero eyebrow): `読書ガイド`
- **cards-section heading**: `チャプター`
- **count-chip unit**: `章` (hero chip reads `全N章`)

Site title = the book title.

## Build

Hand the profile and canonical source-structure path above to [[explainer-reading-site-generate-base]] and run its pipeline
(Phase 1 scaffold → Phase 2 author reports + landing → Phase 3 build + nav manifest →
hand off to [[explainer-reading-site-deploy]]). The base skill's Success criteria are the
acceptance for this skill.
