---
name: paper-explainer-generate-site
description: "Build a static reading site from existing paper-explainer reports, including overview audio when present. Use when reports already exist and the user wants a local site. Use explainer-reading-site-deploy to publish it."
user-invocable: true
---

# Generate Site — paper-explainer reports as an authored website

Turn a **paper-explainer** work dir (`<dir>/<slug>/`, at least one report under
`reports/` — typically `overview.md` plus the perspective reports) into a
reading-guide website under `<WORK_DIR>/site/`: a landing page with report cards and
one authored page per report, the overview's audio guide playable in-page.

The whole build pipeline — scaffold, parallel semantic-Markdown authoring, the single
generator build, the semantic landing page, the nav manifest, the gotchas, and the
success criteria — is the **shared reading-site pipeline** owned by
[[explainer-reading-site-generate-base]]. **Delegate the build to that skill.** This skill
adds only what is paper-specific: the canonical source-structure path,
page-ordering profile, and landing vocabulary below. Do not re-derive the pipeline
here; follow the base skill for every phase.

## When this applies

The input is a paper-explainer work dir with reports under `reports/` and the
canonical paper section structure at `source-structure.md`. `audio/` is optional
(pages without audio get no player). If reports or `source-structure.md` do not
exist yet, run [[paper-explainer-summarize]] first; for the overview audio on the page, run
[[explainer-audio-dialogue]] (pointed at `reports/overview.md`) →
[[explainer-audio-narrate]] first. This skill only *builds* the site; publishing it
is [[explainer-reading-site-deploy]]'s job.

## paper-explainer inputs

### Source locator kind

Pass `pdf-page` to the shared page-authoring and fan-in sweep contracts. Paper
prose continues to use `[pNN]{.p}` / `[pNN–pMM]{.p}`; no EPUB locator map applies.

### Canonical source structure

Pass the absolute path to `<WORK_DIR>/source-structure.md` to the shared pipeline.
It records the paper's source-authored headings separately from `spine.md`, which
remains the authority for confirmed facts. Perspective-report headings are
editorial artifacts and are never a substitute for this source structure.

### Ordered page list — `[{ slug, kicker }]`

A paper's reports are not chapters; they are **fixed perspectives**. Resolve
`reports/*.md` into the base skill's ordered list with this canonical table, keeping
only the reports that exist and preserving this order:

| report slug (`reports/<slug>.md`) | kicker |
|-----------------------------------|--------|
| `overview`      | 全体レポート |
| `background`    | 背景 |
| `method`        | 手法 |
| `experiments`   | 実験 |
| `discussion`    | 議論 |
| `related-work`  | 関連研究 |

- `overview` is always first and is the landing hero CTA / home. Do not renumber when
  a subset is present — keep the canonical order for whichever exist.
- Any report whose slug is **not** in the table (a hand-added report) is **appended last** in natural sort, with a
  kicker derived from a readable title-case of its slug. Do not drop it.

This satisfies the base contract (overview first; every existing report once;
deterministic order; non-empty kicker). Reports are **not** color-coded — which report
you are on is answered by the nav, the title, and the index.

### Landing document-type vocabulary

- **guide kicker** (hero eyebrow): `論文ガイド`
- **cards-section heading**: `レポート`
- **count-chip unit**: `レポート` (hero chip reads `全Nレポート`)

Site title = the paper title (from `reports/overview.md`'s `<h1>`).

## Build

Hand the profile and canonical source-structure path above to [[explainer-reading-site-generate-base]] and run its pipeline
(Phase 1 scaffold → Phase 2 author reports + landing → Phase 3 build + nav manifest →
hand off to [[explainer-reading-site-deploy]]). The base skill's Success criteria are the
acceptance for this skill.
