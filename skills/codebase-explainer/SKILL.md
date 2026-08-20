---
name: codebase-explainer
description: "Generate an evidence-backed HTML explanation of how a codebase works at a specific snapshot, from architecture and module boundaries down to execution paths and representative code. Use when someone needs to understand a repository, subsystem, module, feature, or cross-cutting concern as it exists now; to become able to maintain AI-authored code; or to trace how a behavior is implemented. This explains current code rather than a git diff, and surfaces incidental concerns without becoming an exhaustive code review."
---

# Codebase Explainer

Generate a snapshot explanation that lets a reader answer a concrete question about
the current implementation. Build understanding in layers: orientation, mental
model, boundaries, execution paths, code evidence, and maintenance implications.

This skill is generation only. Read code, repository history, local documentation,
and purpose-relevant external sources, then write only under the output directory.
Do not change the explained repository, switch branches, publish the result, or
claim to have performed an exhaustive review.

## Inputs

Resolve inputs from the request and conversation before asking questions:

| Input | Default |
|---|---|
| Purpose | The concrete question the reader wants answered |
| Scope | Paths and symbols needed to answer that question, not the whole repository |
| Depth | Enough detail to achieve the stated purpose |
| Snapshot | Current worktree, including in-scope uncommitted files |
| Output | `.agents/codebase-explainer/{yyyy-mm-dd}-{scope-slug}/` |
| Language | Conversation language, otherwise repository documentation language |

Proceed without confirmation when purpose, scope, and depth are clear. Present a
short investigation plan and ask once when materially different interpretations
exist, the requested scope is unusually broad, or a multi-page site is likely.
State the proposed purpose, paths or systems to trace, exclusions, depth, and output
shape. Do not ask merely because the user omitted paths; discovering relevant paths
is part of the work.

## Required dependencies

Resolve `[[explainer-html-docs]]` as the shared `explainer-html-docs` skill. Stop
with a clear message if it is unavailable. Before authoring, read both:

- this skill's [`references/authoring.md`](references/authoring.md);
- `explainer-html-docs/references/authoring-contract.md`.

The bundled `scripts/build.sh` delegates all mechanical HTML generation to that
skill. Do not hand-author the page shell or fork its base assets.

## Workflow

### 1. Fix the question and snapshot

Write a one-sentence success condition: what the reader should understand or be
able to do after reading. Use it to decide what deserves investigation.

Record the repository root, requested ref, resolved commit, branch when applicable,
and worktree state. If the worktree is dirty, distinguish the base commit from the
uncommitted snapshot. Do not checkout another ref; inspect it with read-only Git
commands or a temporary extracted copy when necessary.

### 2. Build a purpose-led map

Start broad and shallow:

- inventory manifests, entry points, module boundaries, generated-code markers,
  repository instructions, READMEs, ADRs, and relevant tests;
- identify the smallest set of components that can answer the question;
- name likely entry points, state/data owners, side-effect boundaries, and exits;
- load an installed language-reference skill for the dominant implementation
  language when one is available.

Do not read every file by default. A whole-codebase request still needs a purpose-led
map, not a file-by-file catalog.

### 3. Trace the implementation

Follow representative paths in understanding order rather than directory order:

1. the external or user-visible entry;
2. orchestration and policy decisions;
3. core abstractions and state transitions;
4. persistence, network, process, or other side effects;
5. failure handling and observable outputs;
6. tests that demonstrate or constrain the behavior.

Read definitions and important call sites together. Search for construction,
registration, configuration, and tests before assigning responsibility to a type or
function. For cross-cutting concerns, trace at least one end-to-end path and then
show where the pattern varies.

Follow external documentation, services, and related repositories when they can
materially change the answer. Keep the search bounded by the success condition;
stop following references when another hop would not change the mental model.
Record every external source used and any material source that was inaccessible.

### 4. Separate evidence from interpretation

Use these epistemic categories consistently:

- **Observed implementation** — directly supported by the snapshot's code or
  configuration.
- **Documented intent** — explicitly stated in an ADR, design document, comment,
  issue, or other attributable source.
- **Inference** — a plausible explanation not explicitly established by evidence.
- **Concern** — a maintenance, correctness, safety, or operability risk encountered
  while tracing the requested behavior.

Never turn an inference into documented intent. When an apparent concern is
intentional, cite the evidence for that intent and still explain any residual
trade-off. Report only concerns encountered in the purpose-led investigation;
state that this was not an exhaustive review.

### 5. Choose one page or a site

Default to one self-contained `index.html`. Use a multi-page site only when the
answer contains several independently useful mental models or execution paths that
each need their own orientation and walkthrough. Repository size and file count are
not reasons by themselves.

For one page, author `<OUTPUT>/src/index.md` and build into `<OUTPUT>/index.html`.
For a site, author `<OUTPUT>/src/index.md`, one source per independent topic, and
`<OUTPUT>/src/nav-manifest.js`; build into `<OUTPUT>/site/`. Keep sources because
they record what was synthesized; never edit generated HTML.

The site builder requires its destination to be absent or empty and installs the
site only after every page builds. If a previous site exists, ask before clearing
it or choose a new output directory; do not merge a rebuild into stale output.

### 6. Author for understanding

Lead with the answer and mental model, then descend into evidence. Include exact,
short code excerpts only when they explain a decision, contract, state transition,
or non-obvious mechanism. Pair every excerpt with its snapshot-relative
`path:line` coordinate and explain why it matters. Prefer a stable remote permalink
at the resolved commit when one is available; otherwise keep paths portable and
relative to the repository root.

Use diagrams for relationships or flows that are materially harder to understand in
prose. Do not diagram the directory tree merely to decorate the page. Adapt the
section set to the purpose, but always disclose snapshot identity, investigated and
excluded scope, evidence sources, inferences, and incidental concerns.

Follow `references/authoring.md` for frontmatter, page/site structure, and the build
command.

### 7. Verify and hand off

Before reporting completion:

1. Re-check every important claim against its cited code or source.
2. Confirm excerpts match the recorded snapshot and coordinates.
3. Confirm documented intent and inference are visibly distinct.
4. Confirm concerns do not imply review completeness.
5. Build successfully through `scripts/build.sh`.
6. Check that the expected HTML files exist, links and navigation targets resolve,
   local assets are present in site mode, and no source page was omitted.
7. Report the artifact path, snapshot, output shape, and material investigation
   limits.

Do not publish automatically. Offer publishing separately only after the user has
reviewed the local artifact.
