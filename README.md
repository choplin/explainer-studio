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

## Validate skills

Install the pinned fork of the Agent Skill validator. This revision provides
the path-scoped nesting and token-accounting controls used by the repository:

```bash
nix profile add github:choplin/skill-validator/be8d7501a54468f4ec1fa697c1ea3846fbb0fac6
skill-validator --version  # must be v1.5.6
```

On systems without Nix, build the same pinned revision with Go:

```bash
git clone https://github.com/choplin/skill-validator.git
git -C skill-validator checkout be8d7501a54468f4ec1fa697c1ea3846fbb0fac6
(cd skill-validator && go install ./cmd/skill-validator)
```

Then run the same repository check used by CI:

```bash
./scripts/check-skills.sh
```

The check validates every `skills/**/SKILL.md` package and verifies a deliberately
broken YAML-frontmatter fixture. Validator errors and advisory warnings both
fail the command.

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
