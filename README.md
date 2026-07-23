# explainer-studio

Independent skill collection and Claude Code plugin for turning source material
into readable, trustworthy explanations and reading guides.

## Install in Claude Code

Add this repository as a marketplace, then install the plugin:

```text
/plugin marketplace add choplin/explainer-studio
/plugin install explainer-studio@explainer-studio
```

Run `/reload-plugins` after installing or updating it. For local development,
load the checkout directly with `claude --plugin-dir .`.

## Skill groups

- [`explainer`](skills/explainer/) — shared explanation, audio, reading-site,
  HTML-document, and diff-explanation skills.
- [`pdf-explainer`](skills/pdf-explainer/README.md) — staged PDF extraction,
  synthesis, audio guides, and reading-guide sites.
- [`paper-explainer`](skills/paper-explainer/README.md) — academic-paper digestion
  with source-faithfulness checks and perspective reports.

The six Claude Code subagent wrappers used by the PDF and paper pipelines live
in [`agents`](agents). The reusable procedures remain in [`skills`](skills), so
other agent environments can apply the same skills inline.
