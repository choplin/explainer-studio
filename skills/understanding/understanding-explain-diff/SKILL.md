---
name: understanding-explain-diff
description: This skill should be used when the user wants an HTML explanation document generated from a git diff — a reviewer-facing guide that layers background, mental model, diagrams, a guided walkthrough in understanding order with risk annotations, and review points. Triggers on "explain this diff", "diffの解説を作って", "この変更の解説HTMLを生成して", "generate an explanation page for these changes". Should NOT trigger for publishing an explanation for a PR (use git-helpers-explain-pr, which delegates here), writing a Markdown PR description (git-helpers-pr-description), or reviewing code for defects (code-review skills).
allowed-tools: Bash, Read, Write, Glob
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
- When the diff and its commit messages still leave a chunk genuinely ambiguous in
  a way that would change the explanation — e.g. you cannot tell whether a change is
  a behavior change or a pure refactor, which flips its risk level — **ask the user
  rather than guessing, when the session is interactive**. When running headless or
  delegated by a caller (e.g. `git-helpers-explain-pr`) there is no one to ask: fall
  back to inferring and marking it inferred (see Background & Why). Reserve the
  question for gaps that affect correctness; route minor uncertainty to the
  `.inferred-note` path, not to the user.

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

### 3. Author the IR and generate

Write a semantic **IR** (Markdown + fenced-div directives) and run this skill's
build script; the generator ([[understanding-html-docs-generate]]) binds each
meaning to markup, inlines the design system, and emits the single self-contained
file. The author writes only meaning — never HTML, never a pasted `base.css` or
component, so the shared design system cannot drift. An invalid risk/tested value
is a **hard build error**, and diff content is HTML-escaped by the filter.

**Frontmatter** — the page chrome:

```yaml
---
title: <heading> — diff 解説
lang: ja
meta: "PR #123 · feature/foo → main · 12 files, +340 −85"   # the header meta line
has-diffs: true        # emit the diff2html engine + renderer (omit if no diffs)
has-diagrams: true     # emit the mermaid engine (omit if no diagrams)
reviewed-label: 確認済み
risk-labels: { high: 要精査, medium: 流し読み, low: 確認不要 }  # risk-badge text
context-css: explain-diff.css
toc-heading: 目次       # optional; omit to drop the TOC
footer: "…"            # optional footer note (generator/truncation note)
---
```

**Body directives** — the explain-diff vocabulary. The base
[[understanding-html-docs-generate]] vocabulary (callouts, keypoints, plain
tables — auto-wrapped in `.tablewrap`) is available too; these add the axes this
skill owns:

| To express | Author |
|---|---|
| The **review plan** (attention budget) | `::: {.review-plan heading="レビュー計画"}` wrapping `::: {.budget}` with one `::: {.budget-item risk=high}` **…** `:::` per tier present. The live progress line is injected for you. |
| A **walkthrough chunk** | `::: {.chunk risk=high id=slug pattern="…" files="a.ts, b.ts" tested=no verify="…" title="…"}` … `:::`. The header (checkbox, risk badge, pattern tag, files, verify-status) is generated from the attributes; the div body is the prose + optional behavior table + diff. `pattern` is optional; `risk` must be high\|medium\|low and `tested` must be yes\|no (else the build fails). |
| A **machine-verified claim** | `[claim]{.verified}` inline (see Machine-verified facts). |
| An **inferred / low-confidence note** | `::: {.inferred-note}` … `:::` |
| A **before/after shift** | `::: {.ba-pair}` wrapping `::: {.ba-before}` `**Before**` … `:::` and `::: {.ba-after}` `**After**` … `:::` |
| A **diagram** | a ` ```mermaid ` fenced block (tag changed nodes with the `added`/`removed`/`changed` `classDef`s per `components/diagram/include.md`) |
| A **diff excerpt** (inside a chunk) | a ` ```{.diff-source} ` fenced block holding the **raw** unified diff — the filter HTML-escapes it and emits the `<pre>` + empty renderer pair |
| A **review point** | `::: {.review-point}` `**Title**` … `:::` |

Chunk **order = source order = understanding order**: write the `.chunk` blocks in
the order the reviewer should read them (there is no separate order attribute).
Each `.chunk` needs a stable, unique `id` (the read-progress state key).

**Generate** — run from this skill's directory (`examples/sample.md` is a worked
IR example):

```bash
scripts/build.sh <ir.md> <out-dir>          # one self-contained file (default)
scripts/build.sh <ir.md> <out-dir> --copy   # multi-file (external assets/) instead
```

Runtime is **pandoc**, resolved by the generator's preflight (PATH → bundled
`nix develop` → fail). The default (inline) output is a single file with
`base.css`, `explain-diff.css`, and the diff/diagram/comments components folded
in; only the diff2html and mermaid **engines** load from a CDN. Review the result
against the **Color language** section below (an inline self-check, not the full
`understanding-html-docs-review` pass).

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
  truncation in the chunk and in the footer. Per `.chunk`:
    - Give each a stable, unique `id=` slug (the read-progress state key — must
      not be reorder-sensitive).
    - Set `tested=yes` with a `verify="tested by …"` naming the covering test, or
      `tested=no` for untested. Always present (an invalid value fails the build).
    - Set `pattern="…"` only when a change pattern was named in step 2; omit the
      attribute otherwise.
    - Mark claims confirmed by running a command with `[…]{.verified}` (see
      Machine-verified facts below); leave inferences unmarked so the reviewer can
      tell them apart.
    - When the chunk changes runtime behavior, include a plain Markdown behavior
      table (a concrete input→old→new row lowers cognitive load more than prose);
      omit it for non-behavioral chunks.
- **Review points**: design decisions with rejected alternatives, untested areas,
  and concrete questions for the reviewer — items needing human judgment, not a
  restatement of the walkthrough.

## Machine-verified facts

An AI-written explanation carries its own reviewer cost: "can I trust this
summary?" Lower it by separating what was *checked* from what was *inferred*.
Only wrap a claim in `[…]{.verified}` after actually confirming it with
a command in this session — e.g. `rg` to prove "all 12 call sites updated", or
running the test suite to prove "tests pass". Never mark a claim verified on the
strength of the diff alone or a plausible guess; an unverified inference stays
unmarked. Over-marking destroys the signal, so when in doubt, leave it unmarked.

## Gotchas

- **Escaping and wrapping are the filter's job.** Put the **raw** unified diff in
  a ` ```{.diff-source} ` block — the filter HTML-escapes it and emits the
  `<pre class="diff-source" hidden>` + empty `<div class="diff-render">` pair the
  diff component renders (GitHub-style, unified ↔ side-by-side). Inline code in
  prose uses normal Markdown backticks (pandoc escapes it). The one content rule
  that is yours: keep each excerpt a **parseable unified diff** (a
  `diff --git` / `---` / `+++` header + intact `@@` hunks) — see
  `components/diff/include.md`; the mermaid palette hook is in
  `components/diagram/include.md`.
- **Do not inline the full raw diff for large changes.** The document is an
  explanation, not a mirror of the diff — the PR itself remains the source of
  truth for exact content. Cap per-chunk excerpts and say what was omitted.
- **The substrate is offline; the diff/diagram engines are not.** base.css is
  inlined (not a CDN dependency), so typography/color/layout work offline; only
  the diff2html and mermaid rendering needs the network (vendor them per each
  component's include.md for full offline).
- **The generator owns the design-system inlining — don't touch it.** `base.css`
  and the components are folded in by the build (inline mode), unchanged. Never
  edit generated CSS/JS by hand; to change presentation, edit `assets/explain-diff.css`
  (this skill's context layer, its only styling), the base skill, or the component.
  `assets/template-explain-diff.html` and `filters/explain-diff.lua` are the
  skill's own template/vocabulary — the meaning→markup binding lives there, not in
  the IR.

## Success criteria

Verify before reporting completion; fix and re-check on any No:

- [ ] Every file in `git diff --stat` is covered by exactly one walkthrough chunk
      (low-risk group chunks count as coverage).
- [ ] Every chunk has a risk level *and* a stated reason for it.
- [ ] The review-plan aggregate matches the actual chunks (tier counts add up).
- [ ] Every `.chunk` has an `id`, a `risk`, and a `tested` (yes with a `verify`
      naming the test, or no).
- [ ] Every `[…]{.verified}` claim was actually confirmed by a command run this
      session — no verified marks on unchecked inferences.
- [ ] Chunk order follows the narrative of understanding, not file path order.
- [ ] Background section exists; if no context material was given, it is
      explicitly marked as inferred.
- [ ] Each `.diff-source` block holds a parseable unified diff (a `diff --git`,
      `---`, or `+++` header + intact `@@` hunks).
- [ ] The build ran without error (an invalid `risk`/`tested` value, an unknown
      callout variant, or a `.chunk` missing its required attributes fails it).
- [ ] The build produced a single self-contained HTML file (default inline mode —
      `base.css`, `explain-diff.css`, and the used components folded in; only the
      diff2html and mermaid engines external) that opens standalone in a browser.
- [ ] The risk / change / verify color axes were self-checked against the **Color
      language** section: every risk badge/border/budget line, every `.ba-before`/
      `.ba-after`, and every verify status carries
      the hue its own text implies. A design-system violation never breaks the page — a
      callout whose variant contradicts its text renders as a perfectly good box in the
      wrong color — and on this ephemeral document that mis-coloring is the one failure
      that matters, so read the semantic axes back against the contract. This is an
      inline self-check, not a separate design-system review pass (the full
      `understanding-html-docs-review` subagent is disproportionate for a throwaway
      review artifact).
