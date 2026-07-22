# explainer-studio

Independent skill collection for turning source material into readable,
trustworthy explanations and reading guides.

## Skill groups

- [`explainer`](skills/explainer/) — shared explanation, audio, reading-site,
  HTML-document, and diff-explanation skills.
- [`pdf-explainer`](skills/pdf-explainer/README.md) — staged PDF extraction,
  synthesis, audio guides, and reading-guide sites.
- [`paper-explainer`](skills/paper-explainer/README.md) — academic-paper digestion
  with source-faithfulness checks and perspective reports.

The six Claude subagent wrappers used by the PDF and paper pipelines live in
[`opts/claude/agents`](opts/claude/agents).
