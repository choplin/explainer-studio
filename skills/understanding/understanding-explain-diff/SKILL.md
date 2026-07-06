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
directory) and replace the placeholders. Keep the `<head>` — CDN links
(Pico.css, diff2html, mermaid), styles, and mermaid init — and the diff2html
render script at the bottom of `<body>` unchanged. The template's commented
`<article class="chunk">` / `.review-point` blocks show the exact component
markup to repeat.

Diff excerpts are not hand-styled: place each one as a **valid unified diff**
(keeping the `diff --git` / `---` / `+++` file headers and intact `@@` hunks),
HTML-escaped, inside `<pre class="diff-source" hidden>`, immediately followed by
an empty `<div class="diff-render"></div>`. The template's script renders every
such pair with diff2html (GitHub-style view, syntax highlighting, unified ↔
side-by-side toggle) at load time.

### Color language

Color carries meaning, so keep it consistent — one hue, one meaning, everywhere.
The template defines exactly two page-level axes; apply them, and do not invent
other colors:

- **Risk** (how much attention): red / amber / green. Carried by `data-risk` on
  risk badges, chunk borders, and the review-plan budget lines (`ul.budget`
  `li[data-risk]`). Amber is also reused for "trust this less" — the
  `.inferred-note` and the `data-tested="no"` status.
- **Change** (before vs. after): grey (before) → accent (after). Carried by the
  `.ba-before`/`.ba-after` cards and the `col-before`/`col-after` table columns.
  Never encode before/after in a risk hue, or the two axes blur.

The mermaid `classDef`s (`added`/`removed`/`changed`) reuse the risk palette by
change role. The diff viewer's own red/green (removed/added) stays inside the
collapsed diff and is not a third page-level system. When these two axes cannot
express something, prefer prose over inventing a new color.

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

- **HTML-escape all diff and code content** (`&` → `&amp;`, `<` → `&lt;`,
  `>` → `&gt;`) inside `pre.diff-source` and inline code. Raw generics
  (`List<Foo>`) or arrows in code silently swallow the rest of the document
  when unescaped. The browser un-escapes `textContent` before diff2html parses
  it, so escaping never corrupts the rendered diff.
- **Keep every excerpt a parseable unified diff.** diff2html renders nothing
  (or a broken view) on malformed input. When shortening an excerpt, drop
  *whole hunks* — never delete lines inside a hunk, which invalidates the `@@`
  line counts. Always retain the file headers so file names appear in the view.
- **Do not inline the full raw diff for large changes.** The document is an
  explanation, not a mirror of the diff — the PR itself remains the source of
  truth for exact content. Cap per-chunk excerpts and say what was omitted.
- The document assumes an online viewer: Pico.css and mermaid load from CDN.
  There is no offline fallback by design.

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
- [ ] The file opens standalone in a browser with no local dependencies
      (CDN-only externals).
