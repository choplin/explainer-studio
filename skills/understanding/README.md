# understanding

Skills that help humans understand AI-generated changes — reducing reviewer
cognitive load as AI produces more code than humans can read line-by-line.

Inspired by [Understanding is the new bottleneck](https://www.geoffreylitt.com/2026/07/02/understanding-is-the-new-bottleneck.html) (Geoffrey Litt, 2026).

## Skills

| Skill | Description |
|-------|-------------|
| `explain-diff` | Generate a reviewer-facing HTML explanation of a git diff: background, mental model, diagrams, guided walkthrough with risk annotations, review points |
| `html-docs` | Shared design system (`base.css`) + progressive-enhancement kit (`base.js`) + authoring principles for self-contained HTML explanation documents. Delegated to by name (e.g. by `explain-diff`); not invoked directly |

## When Skills Activate

- **explain-diff**: "explain this diff", "diffの解説を作って", "generate an explanation page for these changes"

## Related

- `git-helpers-explain-pr` wraps `explain-diff` for PRs: gathers PR context,
  publishes the page (gh-pages or a `pr-docs` branch), and links it from a PR
  comment.
