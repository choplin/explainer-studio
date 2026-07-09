---
name: paper-studio-consistency-sweep
description: Internal Finalize-phase procedure for the paper-studio-summarize skill — the one pass that reads the WHOLE report set at once and checks it for (1) cross-report contradictions and (2) faithfulness to the source paper's logical structure, returning a findings list only (it never edits the reports). Applied once at Finalize by the summarize orchestrator (dispatched to a paper-studio-consistency-sweep subagent under Claude Code, or applied inline otherwise). NOT a user-facing skill and NOT triggered directly by user requests.
version: 0.1.0
user-invocable: false
---

# Paper report-set consistency & faithfulness sweep

The `paper-studio-summarize` pipeline writes the overview (Phase 1) and each perspective detail report (Phase 2) in **isolated contexts** that are never reconciled against each other — deliberately, for context hygiene. The structural cost of that isolation is that **no agent ever sees the whole report set at once**, so two failure classes slip through every per-report self-check:

1. **Cross-report contradictions** — two reports state the same fact differently (a conclusion's direction, a running-example attribution, a headline number's scope, a figure-derived trend). Each report is internally fine; they disagree only when read side by side.
2. **Source-faithfulness / logical-structure drift** — the reports agree with *each other* but have collectively flattened, reversed, or over-hardened the paper's own argument. Mutual consistency cannot catch this: they can all be wrong the same way (the single-source trap).

This procedure is that missing whole-set pass. You read every in-scope report **plus the Phase 1 `spine.md` (the confirmed-facts artifact) plus the source paper**, and return a **findings list only**. You do **not** edit any report — the orchestrator applies targeted fixes from your findings. Your value is entirely in what you catch and how precisely you locate it; be a skeptic, not a rubber stamp.

## When this applies

The `paper-studio-summarize` skill applies this procedure once, at Finalize, after all in-scope reports exist. Under Claude Code it is dispatched to a `paper-studio-consistency-sweep` subagent (so the whole report set is read in an isolated context and only the findings return to the orchestrator, preserving its hygiene); otherwise it is applied inline. It is not for direct user requests and is not invoked proactively.

## Inputs provided by the caller

If any is missing, report what is missing and stop.

- **Report paths**: absolute paths to every in-scope report under `<WORK_DIR>/reports/` (the `overview.md` and each detail report that was written).
- **Spine**: absolute path to `<WORK_DIR>/spine.md` — the Phase 1 confirmed-facts artifact (thesis + direction, future-direction / practical-solution conclusion, the running-example map, headline numbers with scope, figure-verified facts). This is the **oracle**: reports are checked against it, and it in turn is re-checked against the source (see Mandate 2). If no `spine.md` exists (the paper had no running example and a spine was not built), use the paper itself as the oracle and say so in your reply.
- **Source** (exactly one of):
  - OCR path: absolute path to `<WORK_DIR>/ocr/paper.md` (full text, `[pNN]` anchors), with the extracted figures in `ocr/figures/` and their legend in `ocr/figures.md`. This is the normal case.
  - Visual path: absolute path to the PDF (read only via the Read tool's `pages`).
- **Section map**: the paper's section structure with `[pNN]` spans, to locate the source sentence behind any restated claim.

## What to check

Read the spine first, then each report, then confirm every suspicious claim against the source. Work the two mandates below. For **every** finding, name **which side the source supports** and cite the `[pNN]` — "reports A and B disagree" without a source verdict is not an actionable finding, because the fix loop needs to know which side to move.

### Mandate 1 — Cross-report consistency (reports ↔ reports ↔ spine)

Collect every fact that appears in more than one report (or in a report and the spine) and confirm they agree — in value **and in direction/scope**:

- **Thesis / overall conclusion direction.** The paper's leading verdict (a superiority / asymmetry / trade-off) points the same way in the overview's TL;DR, in `background.md`, and in `discussion.md`, and matches `spine.md`. A reversed direction ("the second assumption holds more strongly than the first" mapped to the wrong enumeration order) is a blocker.
- **Future-direction / practical-solution conclusion.** Where the paper names a recommended direction or a "practical sweet spot", every report that mentions it agrees on *which* one, and matches the spine. (This is the class that an overview independently re-derived and got wrong.)
- **Running-example attributions.** Each example feature → concept/label attribution is identical across every report that discusses the example, and matches the spine's map. A feature that drives one axis is not blamed for a different axis in one report while correct in another.
- **Headline numbers and their scope.** A number restated in two reports carries the same value **and the same scope** (definition / population / bound-vs-mean-vs-median). A subset average in one report and a whole-set average in another for the "same" quantity is a contradiction, not a rounding difference.
- **Figure-derived facts.** A trend or direction read off a figure (e.g. a monotonic relation, an axis ordering) is stated the same way wherever it appears.

### Mandate 2 — Faithfulness to the source's logical structure (reports ↔ paper)

This is the check mutual consistency cannot do, and the one to weight most heavily: the reports can be perfectly consistent with each other and still misrepresent the paper. Verify against the **source**, not against sibling reports:

- **Spine re-verification (catches the single-source error).** The spine is the shared oracle, so a wrong spine row propagates to every report undetected. Re-check the spine's load-bearing rows against the source itself — and for any attribution read off a figure, **open the figure image and read it off the figure; the figure wins over OCR prose.** A spine row you cannot anchor to a visible figure element or an explicit source sentence is a finding.
- **Argument structure preserved.** The paper's claim → evidence → conclusion chain survives: a conclusion still rests on the evidence the paper ties it to (not on a different result), a dependency the paper states (X established before Y) is not reordered, and a multi-step argument is not compressed into a single asserted fact that drops its premise.
- **Author modality preserved.** Hedged or design-level claims ("can / may / suggests / we believe", an argued-but-unmeasured mechanism) are not restated anywhere as established, measured fact — especially in the overview, the most-read layer.
- **Scope conditions attached.** Every headline number keeps the condition it holds under; a conditional or subset finding has not been generalized into a universal one.
- **Orthogonal axes not collapsed.** Two different axes the paper keeps separate ("frequent / dominant" vs "cheap / easy to handle"; "accurate" vs "simple to implement") are not fused into one word.
- **Self-drawn diagrams match prose and source order.** For every `mermaid` (or other self-authored) diagram in a report, walk each edge and confirm its step order and causal direction match both that report's own prose and the source's explicit order (a capability list is not a timeline; an annotation that presupposes an assignment comes after it). This subsumes the old standalone diagram-order sweep.

## What NOT to do

- **Do not edit any report or the spine.** You return findings; the orchestrator applies fixes. (You have Read only — no Write.)
- **Do not manufacture agreement.** If two reports differ but the source is genuinely ambiguous or silent, report it as `needs-human` rather than picking a side — a confident wrong verdict sends the fix loop to harden the wrong claim.
- **Do not re-review prose quality, style, or completeness.** This pass is only about contradictions and source-faithfulness. A clumsy-but-correct sentence is not a finding.
- **Do not install anything or use external lookups.** Read the given files only; run no commands. (Bibliographic verification already happened in Phase 2.)

## Reply — the findings list

Return **only** a findings list (no rewritten reports, no prose essay). If nothing is wrong, say so explicitly ("sweep clean — N reports, M shared facts checked, no contradictions or faithfulness drift"). Otherwise, one entry per finding, most severe first, each with:

- **severity**: `blocker` (a contradiction or a reversed/over-hardened/scope-dropped claim that misrepresents the paper — must be fixed) or `minor` (a real but low-impact inconsistency).
- **type**: `cross-report` / `spine-source` / `argument-structure` / `modality` / `scope` / `axis-collapse` / `diagram-order` / `example-map`.
- **locus**: each report file involved and the section / line / table row where the claim sits — precise enough that the orchestrator can find and edit exactly that span without reading the whole report.
- **what each side says**: the conflicting statements verbatim-enough to compare.
- **source verdict**: which side the source supports, with the `[pNN]` anchor (and, for a figure-derived fact, which figure element you read it off) — or `needs-human` if the source is silent/ambiguous.
- **minimal fix**: the smallest edit that moves the wrong side to the source — a sentence rewrite or a table-cell change, not "regenerate the report". Give the target text and its replacement when you can, so the orchestrator's edit stays surgical.
