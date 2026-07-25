---
name: explainer-reading-site-generate-base
description: "Internal build orchestrator invoked by pdf-explainer-generate-site and paper-explainer-generate-site. Turns reports into semantic pages, a landing page, assets, and navigation using the consumer's ordering profile and vocabulary."
user-invocable: false
---

# explainer-reading-site-generate-base — shared build pipeline

This skill owns the pipeline shared by [[pdf-explainer-generate-site]],
[[paper-explainer-generate-site]], and future consumers that turn a work directory's
`reports/` into a reading-guide site.

The consumer owns only:

- its trigger;
- an ordered `[{ slug, kicker }]` page profile;
- three landing-page nouns: guide kicker, cards-section heading, and count-chip unit.

This base owns scaffold, semantic authoring, the single generator build, landing page,
navigation manifest, verification, and deployment handoff. The output is
`<WORK_DIR>/site/`; deployment is a separate
[[explainer-reading-site-deploy]] action.

## Required reading by phase

- **Before resolving pages or adding a consumer:** read
  [`references/profile-contract.md`](references/profile-contract.md) completely.
  It defines the ordered-list invariants, current PDF/Paper profiles, and landing
  vocabulary.
- **At the start of Phase 2:** read
  [`references/authoring-and-verification.md`](references/authoring-and-verification.md)
  completely. It contains per-page delegation inputs, landing source notation,
  nav-manifest format, gotchas, and the full success checklist.

Do not read the second reference during Phase 1 inventory unless you need to inspect
the later output contract.

## Preconditions and ownership

The input is `<WORK_DIR>` with at least one `reports/*.md`. `audio/` and
`ocr/figures/` are optional. If no report exists, stop and ask the consumer's
summarize skill to run first. Audio can be produced through
[[explainer-audio-dialogue]] and [[explainer-audio-narrate]].

Both dependency skills must be installed:

- [[explainer-html-docs]] supplies `base.css`, `base.js`, the deterministic
  semantic-Markdown generator, and the `reading-nav` component.
- [[explainer-reading-site-library-base]] supplies the shared content layer
  `reading-site.css`.

If either dependency is missing, stop and report it; never guess a path or fork the
assets.

Pages are **authored, not converted**, and are written as semantic Markdown. The
[[explainer-reading-site-page]] procedure restructures each report for web reading.
The generator then owns head markup, theme boot, asset order, classes, table wrapping,
and figure-path rewriting. A 1:1 Markdown conversion or hand-written HTML is not the
deliverable.

## Pipeline

Run these phases in order. Do not build before every semantic source, including the
landing, is ready.

### Phase 1 — Scaffold

1. Inventory `reports/*.md`, audio files (`.m4a`, `.mp3`, `.wav`), and
   `ocr/figures/*`.
2. Read `references/profile-contract.md` and resolve the consumer profile into one
   deterministic ordered `[{ slug, kicker }]` list. Fix it now; it is the source of
   truth for cards and navigation.
3. If `site/` already exists, ask before clearing `site/` and `src/`. Recommend a
   clean rebuild so removed reports/audio cannot remain as publishable orphans. If
   the user declines, build over the existing tree and warn about stale files.
4. Create `src/` and `site/audio/`; copy all source audio into `site/audio/`.
   `src/` and `site/` are reproducible and disposable. Never hand-edit `site/`.
5. If `ocr/figures/` exists, copy the whole directory to `site/figures/`. Copy every
   crop because page authors run independently; the generator rewrites report paths
   from `../ocr/figures/...` to `figures/...`.

Do not copy design assets in this phase. The generator copies them in Phase 3.

### Phase 2 — Author all semantic sources

Read `references/authoring-and-verification.md` completely now.

1. Apply [[explainer-reading-site-page]] once per report, in parallel when the host
   supports isolated subagents. Each worker writes `src/<slug>.md` and returns only
   the source path, title, and a 2–3 line card summary.
2. Pass each worker only the absolute report/output paths, site title, profile kicker,
   figure-directory availability, and matching audio filename or `none`.
3. Do not have workers author head markup, classes, figure rewrites, or prev/next
   links. Runtime navigation comes from the manifest written in Phase 3.
4. Compose `src/index.md` inline from worker replies and the consumer vocabulary.
   Do not re-read report sources for cards. The landing is semantic Markdown and is
   built like every other page.

### Phase 3 — Build once, then write navigation data

Build every `src/*.md` in one pass:

```bash
explainer-html-docs/scripts/build-site.sh <WORK_DIR>/src <WORK_DIR>/site \
  --assets explainer-html-docs/assets \
  --context explainer-reading-site-library-base/assets \
  --component reading-nav
```

Resolve dependency directories as sibling skills under the installed skills root.
The command builds `src/index.md` and every report source, and copies `base.css`,
`base.js`, `reading-site.css`, `reading-nav.css`, and `reading-nav.js`.

A bad source must fail loudly. Fix the named source and rerun the build; do not bypass
unknown variants or missing player sources.

After the build, write `site/assets/nav-manifest.js` from the Phase 1 order and Phase
2 titles. It assigns `window.__HTMLDOCS_NAV`; include every report page exactly once
and omit the landing. This generated data is the only page-order source. Never author
neighbor links into individual pages.

### Phase 4 — Verify and hand off

Apply every item in the success checklist in
`references/authoring-and-verification.md`. Do not claim success from a build command
alone.

Then tell the user the site is ready under `<WORK_DIR>/site/` and offer
[[explainer-reading-site-deploy]]. If the shared library has never been deployed,
[[explainer-reading-site-initialize]] must run first. Never deploy from this skill;
the user reviews the built artifact before it goes public.

## Core invariants

- `overview` is first and is the landing hero CTA.
- Every existing report appears exactly once in a deterministic order and has a
  non-empty kicker.
- Reports are not color-coded by chapter, section, or perspective.
- `src/` contains semantic Markdown; `site/` contains generated output.
- One `explainer-html-docs` build produces the landing and all report pages.
- `nav-manifest.js` is the only page-navigation source.
- Shared assets are reused through `--assets`, `--context`, and
  `--component reading-nav`; consumers do not fork them.
- The site stays readable with JavaScript disabled and contains every local figure
  and audio file it references.
