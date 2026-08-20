---
name: book-explainer-generate-site
description: "Build a local reading site from existing PDF or EPUB book reports, preserving the source format's typed locators and original media. Use when a book work directory already contains reports and the user wants a browsable site."
user-invocable: true
---

# Generate a book reading site

Require `<WORK_DIR>/reports/*.md` and `<WORK_DIR>/structured/toc.md`. Detect the
source adapter from durable work-directory artifacts:

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
