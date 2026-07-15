---
name: understanding-explain-diff
description: This skill should be used when the user wants an HTML explanation document generated from a git diff — a reviewer-facing guide that layers background, mental model, diagrams, a guided walkthrough in understanding order with risk annotations, and review points. Triggers on "explain this diff", "diffの解説を作って", "この変更の解説HTMLを生成して", "generate an explanation page for these changes". Should NOT trigger for publishing an explanation for a PR (use git-helpers-explain-pr, which delegates here), writing a Markdown PR description (git-helpers-pr-description), or reviewing code for defects (code-review skills).
allowed-tools: Bash(git *), Read, Write, Glob
user-invocable: true
---

# Explain Diff

Generate a single self-contained HTML document that explains a git diff to a human
reviewer. The goal is to minimize reviewer cognitive load in a world where AI
generates far more code than humans can read line-by-line: build understanding in
layers (why → mental model → diagrams → guided code walkthrough → review points)
so the reviewer spends attention only where human judgment is actually needed.

This skill is pure generation: diff in, HTML file out. No git branch operations,
no publishing, no PR interaction — callers (e.g. `git-helpers-explain-pr`) own those.

## Inputs

Resolve each input in this order; ask only if genuinely ambiguous.

| Input | Resolution |
|-------|-----------|
| Diff | Caller/user-specified range or pathspec → else staged changes if any → else `<merge-base with default branch>...HEAD` |
| Context material | Optional free-form text from the caller: purpose statement, issue/PR body, commit messages, design notes. More context → better "Background & Why" |
| Output path | Caller-specified → else `.agents/explain-diff/{yyyy-mm-dd}-{branch-or-range-slug}/index.html` |
| Language | Caller-specified → else the dominant language of the context material → else the conversation language |

## Process

### 1. Collect the material

- `git diff --stat <range>` for the shape, `git diff <range>` for the content.
- `git log --format='%h %s%n%b' <range>` when the range spans commits — commit
  messages are context even when no other material is provided.
- Read surrounding source files when the diff alone is not enough to explain a
  chunk correctly (e.g. a modified function whose callers matter).

### 2. Plan the walkthrough

Partition the entire diff into chunks and order them by **understanding order** —
the order in which a reviewer builds a correct mental model — never by file path
order. Typical narrative: core abstraction/contract change first, then call-site
adaptations, then tests, then mechanical fallout.

Classify every chunk's risk:

- **high** — behavior or contract changes, data migrations, concurrency, error
  handling, security-sensitive paths, non-obvious conditionals. These get full
  prose explanation and an expanded diff.
- **low** — mechanical, repetitive changes where reading one instance proves the
  pattern: renames, import updates, generated files, format churn, boilerplate
  test scaffolding. Group them aggressively (one chunk may cover 30 files),
  show one representative excerpt, and collapse the rest.
- **medium** — everything else.

Risk classification is the core value of the document: it is what tells the
reviewer where NOT to spend attention. State the reason for the level in each
chunk ("mechanical rename, verified identical pattern ×12" / "changes retry
semantics — off-by-one here corrupts the queue").

For each chunk also determine, up front:

- **Test coverage** — does the diff itself add/modify a test that exercises this
  chunk? If yes, name the test file; if no, the chunk is *untested* and that is
  where the reviewer's judgment is most needed. "high risk + untested" is the
  single most important thing to surface.
- **Change pattern** — whether the chunk instantiates a recognizable, nameable
  pattern (a Strangler migration, a rename's fan-out, adding a guard clause, a
  library API bump). Naming it compresses understanding; leave unnamed if none
  fits — do not invent labels.

Then compute the **review plan**: aggregate the chunks into an attention budget
— how many chunks need close reading vs. skimming vs. no review (mechanical),
with a rough time estimate. This is the first thing the reviewer sees.

### 3. Generate the HTML

Copy `assets/template.html` (resolve relative to this skill's installed
directory) and replace the placeholders. The document is assembled from the
`understanding-html-docs` design system plus this skill's own content layer, and
stays a single self-contained file by **inlining** each design-system piece from
its source rather than linking it. Paste these in verbatim — never hand-tune them
per document (edit the source or the component instead, so the shared system does
not drift):

- `<style id="html-docs-base">` ← the full contents of `assets/base.css` from the
  `understanding-html-docs` skill (typography, color model, base components).
- The **`diff` opt-in component** (`understanding-html-docs/assets/components/diff/`):
  paste `diff.css` into `<style id="diff-component">` and `diff.js` into the diff
  render `<script>`, and keep the two diff2html CDN tags in `<head>`. Follow
  `components/diff/include.md` for the markup contract and the escaping /
  valid-unified-diff rules. Omit all of this if the document has no diffs.
- The **`diagram` opt-in component** (`understanding-html-docs/assets/components/diagram/`):
  paste `diagram.css` into `<style id="diagram-component">` and `diagram.js` into
  the mermaid init `<script type="module">`. Follow `components/diagram/include.md`
  for the markup contract and the palette hook. Omit if the document has no diagrams.
- The `<style id="explain-diff">` block is the **only** styling authored here —
  this skill's risk/change semantic axes and chunk/review-plan components. Keep it.
- Do **not** inline `base.js`: the walkthrough puts multiple `article.chunk`
  elements directly under `main`, which the base kit's `main article` assumption
  would mis-target. The base CSS's `color-scheme: light dark` already gives
  automatic light/dark; this skill's own read-progress script (kept in the
  template) plus the diff/diagram components own the interactivity.

The template's commented `<article class="chunk">` / `.review-point` blocks show
the exact component markup to repeat. For diff and diagram markup, follow the two
components' `include.md` — e.g. each diff excerpt is a valid unified diff,
HTML-escaped, in `<pre class="diff-source" hidden>` immediately followed by an
empty `<div class="diff-render"></div>`, which the diff component renders at load
time (GitHub-style view, syntax highlighting, unified ↔ side-by-side toggle).

### Color language

Color carries meaning, so keep it consistent — one hue, one meaning, everywhere.
On top of the base design system's palette, the `explain-diff` context layer
defines exactly two page-level axes (risk maps to the base's `--bad`/`--warn`/
`--tip` hues, change to `--muted`/`--accent`, so they inherit light/dark). Apply
them, and do not invent other colors:

- **Risk** (how much attention): red / amber / green. Carried by `data-risk` on
  risk badges, chunk borders, and the review-plan budget lines (`ul.budget`
  `li[data-risk]`). Amber is also reused for "trust this less" — the
  `.inferred-note` and the `data-tested="no"` status.
- **Change** (before vs. after): grey (before) → accent (after). Carried by the
  `.ba-before`/`.ba-after` cards and the `col-before`/`col-after` table columns.
  Never encode before/after in a risk hue, or the two axes blur.

The mermaid `classDef`s assign the diagram component's base-owned palette hook
(see `components/diagram/include.md`) to change role — added=green, removed=red,
changed=amber — so diagrams speak the same risk language. The diff viewer's own
red/green (removed/added) stays inside the collapsed diff and is not a third
page-level system. When these two axes cannot express something, prefer prose
over inventing a new color.

Section-by-section rules:

- **Review plan** (`.review-plan`, top of the document): the attention budget
  from step 2 — one bullet per risk tier present, each carrying `data-risk` so
  it takes the tier color ("精読が必要: N チャンク…", "確認不要: 機械的変更 M
  ファイル…"). This is what lets the reviewer plan before reading *and* teaches
  the risk color language; keep it to the aggregate, not a per-chunk list.
- **Background & Why**: purpose, linked issues, prerequisite knowledge. With no
  context material, infer from the diff and commit messages and put that
  admission in the `.inferred-note` (amber) so the reader trusts it less; delete
  the note when real context was given.
- **Mental model**: how the system behaves before vs. after, in prose, before any
  code appears. Use the `.ba-before`/`.ba-after` cards for the one system-level
  before→after shift (grey = old, accent = new); omit them if the change has no
  clean before/after framing.
- **Diagrams**: only where a diagram beats prose (state machines, data flow,
  component boundaries). Omit the section entirely rather than restate prose as
  boxes. Keep mermaid simple; quote node labels containing spaces or punctuation.
  Tag changed nodes with the `classDef`s (`added`/`removed`/`changed`) so the
  diagram speaks the same color language as the page.
- **Guided walkthrough**: the chunks from step 2. Diffs are collapsed by
  default for every risk level — the prose explanation must stand on its own,
  with the code one click away. Excerpt diffs to what supports the
  explanation (~200 lines max per chunk — beyond that the excerpt stops serving
  the explanation and starts mirroring the PR diff itself; see Gotchas); note
  truncation in the chunk and in the footer. Per chunk:
    - Give each `article.chunk` a stable `data-chunk-id` slug (used for the
      reviewer's read-progress state — must be unique and not reorder-sensitive).
    - Emit the `.verify-status` line: `data-tested="yes"` naming the covering
      test, or `data-tested="no"` for untested. Always present.
    - Add a `.pattern-tag` only when a change pattern was named in step 2;
      otherwise delete the span.
    - Mark claims that were confirmed by running a command with
      `<span class="verified">…</span>` (see Machine-verified facts below);
      leave inferences unmarked so the reviewer can tell them apart.
    - When the chunk changes runtime behavior, include the before/after table;
      a concrete input→old→new row lowers cognitive load far more than prose.
      Delete the table for non-behavioral chunks.
- **Review points**: design decisions with rejected alternatives, untested areas,
  and concrete questions for the reviewer — items needing human judgment, not a
  restatement of the walkthrough.

## Machine-verified facts

An AI-written explanation carries its own reviewer cost: "can I trust this
summary?" Lower it by separating what was *checked* from what was *inferred*.
Only wrap a claim in `<span class="verified">` after actually confirming it with
a command in this session — e.g. `rg` to prove "all 12 call sites updated", or
running the test suite to prove "tests pass". Never mark a claim verified on the
strength of the diff alone or a plausible guess; an unverified inference stays
unmarked. Over-marking destroys the signal, so when in doubt, leave it unmarked.

## Gotchas

- **Diff and diagram rules live in their components.** HTML-escaping diff/code
  content and keeping every excerpt a parseable unified diff are covered by
  `understanding-html-docs/assets/components/diff/include.md`; the mermaid markup
  and palette hook by `components/diagram/include.md`. Follow them — they are the
  source of truth, not restated here. (Inline code in the prose still needs the
  same `&`/`<`/`>` escaping to avoid swallowing the document.)
- **Do not inline the full raw diff for large changes.** The document is an
  explanation, not a mirror of the diff — the PR itself remains the source of
  truth for exact content. Cap per-chunk excerpts and say what was omitted.
- **The substrate is offline; the diff/diagram engines are not.** base.css is
  inlined (not a CDN dependency), so typography/color/layout work offline; only
  the diff2html and mermaid rendering needs the network (vendor them per each
  component's include.md for full offline).
- **Inline the design-system pieces verbatim.** Paste `base.css` and each opt-in
  component's `.css`/`.js` into their `<style>`/`<script>` slots unchanged — do
  not hand-tune them per document (edit the base skill or the component instead).
  A drifted copy diverges from the shared design system across future regenerations.

## Success criteria

Verify before reporting completion; fix and re-check on any No:

- [ ] Every file in `git diff --stat` is covered by exactly one walkthrough chunk
      (low-risk group chunks count as coverage).
- [ ] Every chunk has a risk level *and* a stated reason for it.
- [ ] The review-plan aggregate matches the actual chunks (tier counts add up).
- [ ] Every chunk has a `data-chunk-id` and a `.verify-status` line
      (`data-tested` = yes with a named test, or no).
- [ ] Every `<span class="verified">` claim was actually confirmed by a command
      run this session — no verified marks on unchecked inferences.
- [ ] Chunk order follows the narrative of understanding, not file path order.
- [ ] Background section exists; if no context material was given, it is
      explicitly marked as inferred.
- [ ] No unescaped `<` from code/diff content outside intended tags (spot-check
      the generated file for known generic types or `->` arrows in the diff).
- [ ] Every `pre.diff-source` starts with a `diff --git` (or `---`/`+++`) file
      header and each is immediately followed by an empty `div.diff-render`.
- [ ] `<style id="html-docs-base">` holds the full, unmodified contents of
      `understanding-html-docs/assets/base.css`, and — when diffs/diagrams are
      present — `<style id="diff-component">` / `<style id="diagram-component">`
      and the diff-render / mermaid-init `<script>` slots hold the unmodified
      component files (not the placeholder comments).
- [ ] The file is a single self-contained HTML file (base.css and any used
      component assets inlined; only the diff2html and mermaid engines are
      external), and opens standalone in a browser.
- [ ] The finished file was reviewed with [[understanding-html-docs-review]] and its
      findings fixed. A design-system violation here never breaks the page — a
      callout whose variant contradicts its own text renders as a perfectly good box
      in the wrong color — so it has to be read back against the contract. Pass this
      skill's **Color language** section (only that section, not this whole SKILL) as
      the *consumer context contract* so the review also judges the risk / change /
      verify axes — not just the base layer, which is all the reviewer sees on its
      own. Under Claude Code, dispatch the `understanding-html-docs-reviewer`
      subagent: the review has to happen in a fresh context, because you cannot read a
      page you just wrote as if you had not written it.
