# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/choplin/explainer-studio/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/choplin/explainer-studio/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/choplin/explainer-studio/releases/tag/v0.1.0
