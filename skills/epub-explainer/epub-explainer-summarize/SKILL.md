---
name: epub-explainer-summarize
description: "Digest a DRM-free reflowable EPUB into a source-locator-anchored Markdown overview without rasterizing its text, structure, tables, footnotes, or media."
user-invocable: true
---

# EPUB report pipeline

Convert one EPUB through `inspect → extract → structure → report`. The adapter
reads the OPF spine, EPUB 3 navigation or NCX, XHTML, and original media. It does
not convert the book to PDF or screenshots.

## Before starting

Read `references/source-locator-contract.md` and `references/output-contract.md`
completely. Require an absolute EPUB path and choose `<WORK_DIR>` from the EPUB
basename. If adapter outputs already exist, confirm before regeneration and pass
`--force` only after confirmation. Confirm the report language; default to the
conversation language.

## Phase 0 — preflight and native extraction

Run:

```bash
python3 <SKILL_DIR>/scripts/epub_extract.py <EPUB_ABS_PATH> <WORK_DIR> [--force]
```

The script uses only Python's standard library. It rejects unsafe ZIP paths,
DTD/entity declarations, excessive expansion, and malformed package documents.
It writes `epub/preflight.json` even for a well-formed but unsupported book.

- `reflowable`, exit 0: continue.
- `fixed-layout` or `image-only`, exit 2: stop and explain that a visual-reading
  route is required; do not silently rasterize.
- `drm-protected`, exit 2: stop. DRM removal or circumvention is out of scope.
- exit 1: report the malformed/unsafe input error and stop.

## Phase 1 — isolated source reading

Group adjacent `linear: true` `epub/spine/item-*.json` files at source chapter
boundaries from `structured/toc.md`, with roughly 20,000–40,000 source characters
per group. Include any `linear: false` auxiliary document reached by a noteref or
semantic link from that group, without inserting it into primary reading order.
Apply [[epub-explainer-epub-extract]] once per group, in parallel when isolated
agents are available. Each worker writes `extract/chunk-<start>-<end>.md` and
returns only its path and boundary status. Do not read full spine JSON bodies into
the orchestrator context.

## Phase 2 — structure

Apply [[epub-explainer-epub-stitch]] once to all chunk files, the adapter-created
`structured/toc.md`, and `epub/locators.json`. It replaces
`structured/outline.md` with a compressed outline whose structure and locators
match the canonical spine. Keep the adapter version only as an extraction audit
until this step succeeds.

## Phase 3 — overview

Read only `structured/toc.md`, the compressed `structured/outline.md`, and media
inventory from `epub/source.json`. Write `reports/overview.md` in the requested
language:

- cover every top-level source division once;
- keep the overview at chapter altitude rather than enumerating every section;
- attach each source-derived claim to the closest canonical EPUB locator using
  the contract's `.source-locator` form;
- distinguish source-authored headings from editorial report headings;
- preserve original media references as `../epub/media/<manifest-path>` when a
  figure materially improves understanding;
- never invent page numbers or flatten a table/footnote merely to shorten it.

## Finalize

Verify that every top-level linear `toc.md` entry appears in the overview, every
locator exists in `epub/locators.json` or names an actual spine resource, every referenced
media file exists, and no prose `[pNN]` was invented. Report the work directory and
the four primary artifacts: preflight, toc, outline, and overview.
