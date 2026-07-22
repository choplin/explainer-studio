# explainer-studio

Independent skill collection for turning source material into readable,
trustworthy explanations and reading guides.

## Skill groups

- [`understanding`](skills/understanding/README.md) — reviewer-facing change
  explanations and a shared HTML document design system.
- [`pdf-explainer`](skills/pdf-explainer/README.md) — staged PDF extraction,
  synthesis, audio guides, and reading-guide sites.
- [`paper-explainer`](skills/paper-explainer/README.md) — academic-paper digestion
  with source-faithfulness checks and perspective reports.

The six Claude subagent wrappers used by the PDF and paper pipelines live in
[`opts/claude/agents`](opts/claude/agents).
