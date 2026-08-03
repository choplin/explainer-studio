# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Documented local tools, optional runtimes, network services, and remote assets
  required by each Explainer Studio capability.
- Renamed the git-diff explanation skill from `explainer-diff` to
  `diff-explainer`, matching the subject-first naming of `paper-explainer` and
  `pdf-explainer`. Invoke it as `/explainer-studio:diff-explainer`.
- The diff explainer now gathers the context behind a change as a defined step:
  for a pull request it reads the description and the issues and pull requests it
  references, for a commit range it reads the commit messages, and in every case
  it also draws on the conversation and on the repository's own README,
  changelog, decision records, and conventions. Explanations list the sources
  they were built from.

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

[Unreleased]: https://github.com/choplin/explainer-studio/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/choplin/explainer-studio/releases/tag/v0.1.0
