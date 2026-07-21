---
name: pdf-studio-generate-site
description: This skill should be used when the user wants pdf-studio reports turned into a real website — authored web pages (not converted Markdown) browsable from a smartphone, built as a static site under a work dir's site/ from its reports/, with the audio/ guides playable in-page. Triggers on "レポートをWebサイトにして", "HTMLにして", "サイトを作って", "スマホで読めるようにして", "generate a site from the reports", "make a website from the reports". Should NOT trigger for deploying/hosting the built site (use pdf-studio-deploy-site), for producing the reports (use pdf-studio-summarize / pdf-studio-deep-dive), or for the audio guide (use pdf-studio-audio-dialogue / pdf-studio-audio-narrate).
user-invocable: true
---

# Generate Site — pdf-studio reports as an authored website

Turn a **pdf-studio** work dir (`<dir>/<name>/`, at least one report under
`reports/`) into a reading-guide website under `<WORK_DIR>/site/`: a landing page
with chapter cards and one authored page per report, the matching audio guide
playable in-page.

The whole build pipeline — scaffold, parallel semantic-Markdown authoring, the single
generator build, the semantic landing page, the nav manifest, the gotchas, and the
success criteria — is the **shared reading-site pipeline** owned by
[[understanding-reading-site-base]]. **Delegate the build to that skill.** This skill
adds only what is pdf-specific: the page-ordering profile and the landing vocabulary
below. Do not re-derive the pipeline here; follow the base skill for every phase.

## When this applies

The input is a pdf-studio work dir with reports under `reports/`. `audio/` is optional
(pages without audio get no player). If no report exists yet, run [[pdf-studio-summarize]]
first; for audio on the pages, run [[pdf-studio-audio-dialogue]] →
[[pdf-studio-audio-narrate]] first. This skill only *builds* the site; publishing it is
[[pdf-studio-deploy-site]]'s job.

## pdf-studio profile (the only pdf-specific part)

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

Hand the profile above to [[understanding-reading-site-base]] and run its pipeline
(Phase 1 scaffold → Phase 2 author reports + landing → Phase 3 build + nav manifest →
hand off to [[pdf-studio-deploy-site]]). The base skill's Success criteria are the
acceptance for this skill.
