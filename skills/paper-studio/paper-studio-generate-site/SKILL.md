---
name: paper-studio-generate-site
description: This skill should be used when the user wants paper-studio reports turned into a real website — authored web pages (not converted Markdown) browsable from a smartphone, built as a static site under a work dir's site/ from its reports/ (overview + background / method / experiments / discussion / related-work), with the overview's audio guide playable in-page. Triggers on "論文レポートをWebサイトにして", "この論文サマリをHTMLにして", "サイトを作って", "スマホで読めるようにして", "generate a site from the paper reports". Should NOT trigger for deploying/hosting the built site (use pdf-studio-deploy-site), for producing the reports (use paper-studio-summarize), or for the audio guide (use pdf-studio-audio-dialogue / pdf-studio-audio-narrate).
user-invocable: true
---

# Generate Site — paper-studio reports as an authored website

Turn a **paper-studio** work dir (`<dir>/<slug>/`, at least one report under
`reports/` — typically `overview.md` plus the perspective reports) into a
reading-guide website under `<WORK_DIR>/site/`: a landing page with report cards and
one authored page per report, the overview's audio guide playable in-page.

The whole build pipeline — scaffold, parallel semantic-Markdown authoring, the single
generator build, the semantic landing page, the nav manifest, the gotchas, and the
success criteria — is the **shared reading-site pipeline** owned by
[[understanding-reading-site-base]]. **Delegate the build to that skill.** This skill
adds only what is paper-specific: the page-ordering profile and the landing vocabulary
below. Do not re-derive the pipeline here; follow the base skill for every phase.

## When this applies

The input is a paper-studio work dir with reports under `reports/`. `audio/` is
optional (pages without audio get no player). If no report exists yet, run
[[paper-studio-summarize]] first; for the overview audio on the page, run
[[pdf-studio-audio-dialogue]] (pointed at `reports/overview.md`) →
[[pdf-studio-audio-narrate]] first. This skill only *builds* the site; publishing it
is [[pdf-studio-deploy-site]]'s job.

## paper-studio profile (the only paper-specific part)

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
- Any report whose slug is **not** in the table (a hand-added or deep-dived report,
  e.g. a `pdf-studio-deep-dive` output) is **appended last** in natural sort, with a
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

Hand the profile above to [[understanding-reading-site-base]] and run its pipeline
(Phase 1 scaffold → Phase 2 author reports + landing → Phase 3 build + nav manifest →
hand off to [[pdf-studio-deploy-site]]). The base skill's Success criteria are the
acceptance for this skill.
