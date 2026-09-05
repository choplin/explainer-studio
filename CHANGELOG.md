# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added a source-neutral full-book pipeline and a native EPUB adapter that
  preserves reading order, source structure, XHTML semantics, original media,
  and stable source locators without converting EPUB input to PDF.
- Added explicit detection for reflowable, fixed-layout, image-only, and
  DRM-protected EPUB input, with unsupported formats routed to a clear stop.
- Added one shared content-production workflow for book and paper explainers,
  covering source-specific reports, content modeling, planning, optional audio
  and reading-site production, consistency checks, and final handoff.
- Added an artifact-only phase contract so every workflow phase can run in a
  fresh AI session without relying on earlier conversation history.
- Added durable workflow artifacts with distinct roles: a source-first Content
  brief, a per-execution run request, an immutable Manifest of resolved inputs
  and outputs, and optional immutable human checkpoint decisions.

### Changed

- **Breaking:** Renamed the workflow entry points from
  `book-explainer-full-guide`, `pdf-explainer-full-guide`, and
  `paper-explainer-full-guide` to `book-explainer` and `paper-explainer`.
- **Breaking:** Book and paper entry points are now coordinators rather than
  monolithic generation procedures. They reconcile existing artifacts, resolve
  the dependency closure for the requested outputs, and delegate each phase to
  its owning skill.
- Workflow runs now start from a new source, an existing work directory, or an
  explicitly selected Manifest. Existing artifacts may be reused while only
  missing or intentionally replaced reports, audio, or site outputs are built.
- Human gates are now optional and checkpoint-specific. Without selected human
  gates, coordinators continue through all phases required for the requested
  local outputs.
- Book reading-site generation now shares one PDF/EPUB entry point while
  preserving typed EPUB locators, original EPUB media, and PDF page anchors.
- PDF and EPUB chapter reports now share one cross-chapter consistency sweep.
- Shared content modeling and planning treat each source's authored structure
  as authoritative and use the Content brief only as a cross-media aid.

### Removed

- Removed the `book-explainer-full-guide`, `pdf-explainer-full-guide`, and
  `paper-explainer-full-guide` commands. Use `book-explainer` for PDF and EPUB
  books, and `paper-explainer` for academic papers.

### Fixed

- Audio dialogue generation now builds around an explanatory spine and
  representative evidence, calibrates multi-chapter runs with one pilot, and
  uses duration and source compression as diagnostics for spoken-report drift.

## [0.3.0] - 2026-08-20

### Added

- Added `codebase-explainer` for evidence-backed snapshot explanations of a
  repository, subsystem, module, feature, or cross-cutting concern.

### Changed

- Reading-site editorial headings now use a compact `編注` marker and a visually subdued provenance note.

## [0.2.0] - 2026-08-06

### Added

- Added per-page and whole-build `narrow`, `standard`, and `wide` HTML layouts, with `standard` as the wider default and horizontal scrolling for oversized tables.
- Added a pre-build whole-source consistency sweep for reading-site markup, navigation, source structure, and cross-page conventions.

### Changed

- Documented the local tools, optional runtimes, network services, and remote assets required by each Explainer Studio capability.
- Renamed `explainer-diff` to `diff-explainer`; invoke it as `/explainer-studio:diff-explainer`.
- The diff explainer now gathers change context from pull requests, referenced work, commits, conversations, and repository documentation, and lists the sources used.

### Fixed

- Filterable report and chapter indexes now use a readable single-column layout instead of the compact multi-column card layout.
- Reading sites now use canonical `.p` prose references, exclude page anchors from headings, and share one convention set across parallel page authors.
- Reading sites now distinguish editorial structure from source topology, attribute editorial headings, and verify source headings against the canonical structure artifact.

## [0.1.0] - 2026-07-27

### Added

- Installable Claude Code plugin containing 20 Agent Skills, combining
  ready-to-run explanation pipelines with a reusable semantic Markdown and
  deterministic HTML foundation.
- Shared HTML system for producing structured, navigable explanations with
  responsive navigation, search and filtering, light and dark themes, and
  reusable diagram, highlighted-code, rendered-diff, comment, and reading-site
  components.
- End-to-end git-diff workflow that produces reviewer-facing HTML organized by
  behavior, mental model, risk, verification status, and review point.
- End-to-end long-PDF workflow that produces an overview, chapter reports,
  source page anchors, extracted figures, optional audio guides, and a
  deployable reading site.
- End-to-end academic-paper workflow that uses local OCR and the PDF text layer
  to produce an overview plus background, method, experiments, discussion, and
  related-work reports with cross-report consistency checks.
- Two-speaker dialogue authoring and local VOICEVOX narration skills for turning
  written explanations into audio.
- Automated structural validation for every bundled Agent Skill package.

[Unreleased]: https://github.com/choplin/explainer-studio/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/choplin/explainer-studio/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/choplin/explainer-studio/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/choplin/explainer-studio/releases/tag/v0.1.0
