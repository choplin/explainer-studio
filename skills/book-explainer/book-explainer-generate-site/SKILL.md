---
name: book-explainer-generate-site
description: "Internal site-production phase that builds a local PDF or EPUB book reading site from an exact run request, Content brief, Run Manifest, canonical structure, and report set."
user-invocable: false
---

# Generate a book reading site

Apply [[explainer-content-workflow-base]], read its Artifact contract, and
require the `book` profile. Own only site authoring and local build; do not
perform workflow discovery, user consultation, Content modeling, or Planning.

Require exact paths and digests for the run request, selected Content brief,
Run Manifest, canonical source structure, and every planned source report. The
Manifest entry must select this site output with `create` or `replace`. Return a
structured missing/incompatible-input result otherwise. Never infer the latest
planning Artifact.

The planning Artifacts provide the shared interpretive model and resolved run
plan, but are not exclusive inputs. Reread reports or the narrow source locus
whenever fidelity requires it. Detect the source adapter from durable
work-directory artifacts:

- EPUB when `epub/locators.json` exists;
- PDF otherwise, when reports use canonical `.p` source anchors.

If the artifacts conflict or do not identify either format, stop and ask for the
source format. Never infer EPUB from prose alone.

Delegate the complete build to [[explainer-reading-site-generate-base]]. This
skill owns the shared book profile and supplies only the adapter-specific inputs
below. Publishing remains a separate [[explainer-reading-site-deploy]] action.

## Shared book profile

Pass `<WORK_DIR>/structured/toc.md` as the canonical source structure. Order
reports as follows:

1. `overview` first, kicker `全体レポート`;
2. `chapter-N` in natural numeric order, kicker `第N章`;
3. unmatched reports last in natural order, with a readable title-cased kicker.

Use landing vocabulary `読書ガイド`, `チャプター`, and `章`. Use the supplied
title when present; otherwise resolve it from the adapter metadata or overview.

Keep the source-authored order and divisions as the site's navigation backbone.
Use the selected content brief to explain the book-wide mental model, chapter
roles, and cross-chapter relationships in the landing page and appropriate
report pages. Use the manifest mappings to confirm the selected scope. Never
reorder, merge, suppress, or rename source divisions merely because the brief
groups its explanatory items differently.

## Adapter inputs

For PDF, pass locator kind `pdf-page` and make `ocr/figures/` available when it
exists. No locator map or deterministic locator command applies.

For EPUB, pass:

- locator kind `epub`;
- `<WORK_DIR>/epub/locators.json` as the validation map;
- `<WORK_DIR>/epub/media/` as optional original media, copied recursively to
  `site/media/`;
- the title in `epub/metadata.json` when the user did not supply one.

After semantic `src/*.md` authoring and the shared consistency sweep are clean,
but before HTML generation, run:

```bash
python3 <SKILL_DIR>/scripts/validate_locators.py \
  <WORK_DIR>/epub/locators.json <WORK_DIR>/src/*.md
```

Unknown or missing EPUB locators and EPUB prose using PDF `.p` anchors block the
build. Finish by reporting `<WORK_DIR>/site/` and offering deployment separately.
Run all normal AI checks and return the exact output inventory and digest to the
coordinator. Human interaction belongs to the coordinator. When
`human_gates.site: true`, mark the checked site as the checkpoint subject; a
later phase may accept it only with the matching checkpoint-decision Artifact.
Never treat that decision as permission to deploy.
