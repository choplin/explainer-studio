# Consumer profile contract

Read this reference before resolving pages or adding a reading-site consumer.

## Ordered page list

The consumer resolves `reports/*.md` into `[{ slug, kicker }]`. This base does not
care whether the consumer uses a fixed table or natural sorting, but the result must:

- put `overview` first;
- include every existing report exactly once;
- include no missing report;
- remain deterministic across runs;
- give every page a non-empty kicker.

This list is fixed during scaffold and reused verbatim for landing cards and
`nav-manifest.js`. Reports are never color-coded by position: navigation, headings,
and kickers communicate location; color remains reserved for meaning.

## Current consumer profiles

### Book explainer

1. `overview` with kicker `全体レポート`.
2. `chapter-N` in natural numeric order, so `chapter-2` precedes `chapter-10`, with
   kicker `第N章`.
3. Any unmatched report last in natural order with a kicker derived from the
   title-cased slug.

Use this ordering for both PDF and EPUB books. PDF source references are `.p`
anchors. EPUB source references are `.source-locator` spans validated against
`epub/locators.json`, and original EPUB media is copied from `epub/media/` to
`site/media/`.

### Paper explainer

Include existing reports from this fixed table in order:

| Slug | Kicker |
|---|---|
| `overview` | `全体レポート` |
| `background` | `背景` |
| `method` | `手法` |
| `experiments` | `実験` |
| `discussion` | `議論` |
| `related-work` | `関連研究` |

Append reports absent from the table in natural order with a kicker derived from the
title-cased slug.

## Landing document-type vocabulary

Each consumer supplies:

- **guide kicker**: hero eyebrow, such as `読書ガイド` or `論文ガイド`;
- **cards-section heading**: such as `チャプター` or `レポート`;
- **count-chip unit**: such as `章` or `レポート`.

All other landing strings stay document-type neutral. In particular, the filter
placeholder is `絞り込む…`, not a chapter- or paper-specific phrase.

## Canonical source-structure artifact

Each consumer supplies one durable artifact containing only source-authored
headings, with their hierarchy, source-form titles, and source-page anchors:

- Book explainer: `<WORK_DIR>/structured/toc.md`; EPUB additionally supplies
  `<WORK_DIR>/epub/locators.json` as the canonical locator map;
- Paper explainer: `<WORK_DIR>/source-structure.md`.

The artifact is a required input, not an optional cross-check. Page workers use it
to classify headings as source-derived or editorial, and the fan-in sweep uses the
same file as its attribution oracle. A report heading is not evidence that the
source had that heading; reports may themselves be editorial artifacts.

## Adding a consumer

Keep the consumer shell thin:

1. Define how it resolves its deterministic page list.
2. Define its canonical source-structure artifact.
3. Define the three landing nouns.
4. Define the locator kind and any original-media directory.
5. Delegate scaffold, authoring, build, manifest, verification, and handoff to this
   base.

Do not copy this pipeline or shared asset rules into the consumer.
