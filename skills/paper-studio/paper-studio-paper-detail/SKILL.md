---
name: paper-studio-paper-detail
description: Internal Phase 2 procedure for the paper-studio-summarize skill — write ONE perspective-specific detail report (background / method / experiments / discussion / related-work) for an academic paper already digested in Phase 1, reading either the OCR Markdown or a resolved PDF page span. Applied once per in-scope perspective, in parallel, by the summarize orchestrator (dispatched to a paper-studio-paper-detail subagent under Claude Code, or applied inline otherwise). NOT a user-facing skill and NOT triggered directly by user requests.
user-invocable: false
---

# Paper perspective-detail report

Write ONE perspective-specific detail report for an academic paper that the `paper-studio-summarize` orchestrator has already read once (Phase 1) and mapped into sections. You re-read only the parts relevant to your ONE assigned perspective and write a standalone detail report for it.

## When this applies

The `paper-studio-summarize` skill applies this procedure once per in-scope perspective (background / method / experiments / discussion / related-work), in parallel — one isolated run each. It is not for direct user requests and is not invoked proactively.

## Inputs provided by the caller

The caller provides the following. If any is missing, report what is missing and stop.

- **Perspective**: one of `background` / `method` / `experiments` / `discussion` / `related-work`
- **Source** (exactly one of):
  - OCR path: absolute path to `<WORK_DIR>/ocr/paper.md` (full text with `[pNN]` anchors; extracted figure images live next to it in `ocr/figures/`)
  - Visual path: absolute path to the PDF **and** the page span to read (PDF page numbers, START–END)
- **Section map**: the paper's section structure with `[pNN]` spans, so the relevant parts can be located
- **Assigned figures/tables**: the list of `ocr/figures/fig-NN.<ext>` / `ocr/figures/table-NN.<ext>` files whose page falls in this perspective's span. You MUST reference and explain **every one** of these in your report (see Work) — they are yours to cover so none is left unexplained across the report set.
- **Output path**: absolute path, `<WORK_DIR>/reports/<perspective>.md`
- **Report language** (defaults to the conversation language)
- **The spine**: absolute path to `<WORK_DIR>/spine.md` — the Phase 1 confirmed-facts artifact, handed to every perspective. It holds the paper's thesis + direction, its future-direction / practical-solution conclusion, the running-example map (if any), the headline numbers with their scope, and other figure-verified facts. **Take these facts from the spine; do not independently re-derive them from the OCR prose.** This is what keeps your report consistent with the overview and the sibling reports, which are written in isolation and never reconciled afterward — a fact you re-derive instead of reading from the spine is how two reports end up contradicting each other.
  - The overall conclusion you state must agree with the spine's thesis — same claim, same direction. Deepen and support it; do not weaken, harden, or reverse it. (If the paper genuinely does not support the spine's thesis, say so explicitly in your reply rather than quietly stating the opposite.)
  - For the running-example map, use the spine's row as the authoritative attribution. **Safety net:** if one of *your assigned* figures is open in front of you and plainly contradicts a spine row, the **figure wins** — follow the figure and flag the discrepancy in your reply (do not silently rewrite the wording to match, or the reports re-diverge). The spine is a single shared source, so a wrong row would otherwise propagate to every report unchecked — the Finalize sweep re-verifies it, but flag what you saw.
- For `related-work` only:
  - Absolute path to the bundled `dblp_lookup.sh` script
  - The `[pNN]` span of the References section

## Constraints (strict)

- Do NOT install any software (brew / pip / uv / apt / npm, etc.).
- OCR source: read `ocr/paper.md` with the Read tool; read figure image files from `ocr/figures/` visually when a figure matters to the report. Do NOT re-read the PDF.
- Visual source: read the PDF ONLY via the Read tool's `pages` (max 20 pages per request; split if wider). Do NOT convert or extract the PDF with external tools (pdftoppm / pdftotext / pypdf, etc.).
- Bash is permitted for exactly ONE thing: running the provided `dblp_lookup.sh` script (related-work perspective only). No other commands — no installs, no PDF converters, no ad-hoc curl to other services.
- If the dblp script fails (network blocked, sandbox denial, HTTP error), do NOT switch to another lookup method or answer from memory — mark the affected entries "dblp未確認" and mention the failure in your reply.
- **NEVER write a bibliographic URL, DOI, venue, or year from model memory.** Every such fact must come from the paper itself (its References section) or from `dblp_lookup.sh` output. This rule exists because hallucinated citations look plausible and are worse than an honest "unverified".
- If Read errors (e.g. `pdftoppm failed:`), do not work around it — report the error verbatim and stop.
- Write the report body in the given report language; keep equations in LaTeX (`$...$` / `$$...$$`).
- Attach `[pNN]` (PDF page) anchors at key claims, definitions, tables, and figures.
- Reference extracted figures with a relative path from `reports/`: `../ocr/figures/<file>` (OCR source only). Do not copy or re-encode image files.
- **Explain every assigned figure/table.** For each `ocr/figures/*` file in your Assigned figures/tables list, embed it (`![...](../ocr/figures/<file>)`) at the point in the report where it belongs and explain what it shows and why it matters — never embed an image with no accompanying explanation, and never silently omit an assigned one. If an assigned figure has no natural home in your perspective's narrative, add a short "図表" subsection at the end of the report and cover it there with its `[pNN]`. If you believe a figure is genuinely irrelevant, still list it in that subsection with a one-line note rather than dropping it (the orchestrator guarantees no figure goes unexplained).
- **Consult what you were given before writing "不明" / "unknown" / "記載なし" / "N/A" — and don't over-claim the reverse.** For a figure/table, `ocr/figures.md` is the provided legend (label, page, caption) and the image is readable from `ocr/figures/`. For any other fact — a code/data repository URL, a dataset size, a definition — the answer may sit in the body, a **footnote**, or the References of `ocr/paper.md`; search there before declaring it absent. Conversely, only claim a fact is "stated in the text / 本文に明記" when the paper says it in those words at the `[pNN]` you cite — a value you computed, inferred, or read off a figure is not "stated". *Why:* "unknown"/"not stated" for a fact the paper actually gives (often in a footnote) is a false gap, and a fabricated "the paper states X" is its mirror image — both misrepresent what the paper actually supports. If you supply a condition the paper leaves implicit (e.g. which definition a headline number was measured under), mark it as *your* inference ("§X の文脈からの推定") rather than asserting it flatly, and keep that strength constant — do not state the same condition as established in one place and hedged in another.
- **For "which element maps to which label/concept" in a figure, worked example, or caption, trust the original image over the OCR prose.** Multi-column PDFs OCR with scrambled word order and broken cross-references, so a sentence like "a B is retrieved by its id originating from a previously fetched A" can swap which object is looked up by which key. When the correspondence carries meaning — which entity a label sits on, which key selects which record, which arrow points where — open the `ocr/figures/` image and read it off the figure; the figure's own labels/arrows/callouts win over the prose word order. *Why:* trusting scrambled prose silently reverses the actors in a relation ("A looks up B" vs "B looks up A"), yet the resulting sentence still reads naturally, so nothing local flags the error.

## Faithful restatement — self-check before writing Output

Summarizing is lossy, and a few specific loss modes silently corrupt the paper's meaning while the prose still reads fluently. Run each check below against your draft before you write the file. These are verifiable checks, not a vague call to "be accurate", and they apply to every perspective.

- [ ] **Quantifiers and scope preserved.** Every restated claim keeps the paper's own qualifier — "for X% of applications", "among the N that have it", "at least", "up to", "on average". No subset or conditional claim was generalized into an all-cases claim (e.g. "up to 42% for 90% of apps" is not "at most 42%"). *Why:* dropping the quantifier turns a bounded, conditional finding into a false universal.
- [ ] **Author modality preserved.** Hedges the authors use — "can", "may", "suggests", "we believe" — are kept, and no hedged or design-level claim (a proposal, or an argued-but-unmeasured mechanism) is restated as an established, measured result; where the paper argues rather than measures, the report says so. *Why:* asserting a hedged claim as fact fabricates a level of evidence the paper does not provide.
- [ ] **Every number carries its scope.** Each figure states the method / definition / setting it holds under, its population (all cases or a named subset), and whether it is a bound / mean / median / quantile. *Why:* a scopeless number reads as a universal fact and drops the condition that is often the result's whole point.
- [ ] **Comparisons and relations checked against the source — including their direction.** Every restated comparison or relation (in prose, a table cell, or a bullet) was re-read against the sentence it condenses, for direction and for axis confusion: an ordering keeps the way it points ("A > B" is not "B > A"; "the second assumption holds more strongly than the first" must map first/second to the source's own enumeration order), and two orthogonal axes are not collapsed into one word ("frequent / dominant" is not "cheap / easy to handle"; "accurate" is not "simple to implement"). *Why:* a reversed comparison or a collapsed axis still reads fluently yet states the opposite of the paper — the most damaging error, because nothing local flags it; and simply deciding to state the relation (per the overview's thesis rule) does not make its direction right.
- [ ] **Figure-estimated numbers marked.** Any number read off a plot or graph rather than stated in the text or a table is labeled as an eyeballed reading ("Fig. X からの目測") and not given the precision of a text-stated value. *Why:* estimation error in a number written as if exact becomes a factual discrepancy.
- [ ] **Self-authored figures and "intuition" paraphrases match the prose they stand in for — edge by edge.** For any diagram you draw (e.g. a `mermaid` flow), walk each edge/step and find the sentence in your own report that states that order; if your prose says "X is done after Y", the diagram must not draw X→Y. Do not fuse two different ordering principles into one node or chain — a *capability list* (what a tool can automate) is not a *procedure timeline* (what is done first), and a step that presupposes another (an annotation that needs an assignment already made) must come after it, not before. An "intuition" about a trend points the same way the paper's figure does. *Why:* a diagram or a memorable "intuition" is what the reader retains, so when it contradicts the (correct) prose beside it the reader keeps the wrong picture; and collapsing a capability list into a timeline reliably inverts a dependency that the prose states correctly — the contradiction stays invisible unless you check the diagram against your own prose one edge at a time.
- [ ] **Every check above was applied to the non-narrative loci too — table cells, lists, trailing sections, diagram labels — not only the flowing prose.** Re-read each claim-bearing surface of your draft with the checks above, not just the paragraphs: a claims/evidence table (every cell), bullet or numbered lists, a §5-style 計算量・実装上の注意 or a 再現性 section, callouts, and the node/edge labels of any `mermaid` you drew. Specifically: (a) after writing a claims table, check each cell's quantifier and modality against your own body prose and the spine — do not let a cell say "完全 / all / always / 全て" where the body and spine say "多く / 大半 / the majority", nor assert as measured in a cell what the body hedges as a design argument; (b) if you state a design rationale in the 計算量・実装上の注意 section (e.g. "this fallback is 軽量", "this path is cheap"), carry the same unmeasured-hedge the discussion applies — do not present a mechanism-derived expectation there as a measured fact. *Why:* the faithful-restatement discipline is naturally applied to the narrative you write first and skipped on the table cells, implementation notes, and diagram labels added around it, so the drift concentrates exactly there — and those loci do the most damage, since a claims table is read standalone by skimmers and the implementation/complexity section is where an engineer takes a hardened claim as settled design guidance.
- [ ] **Any structural declaration you write matches the reality beneath it.** If you introduce a list or section with a meta-declaration of its own order, count, or classification — "以下、X が高い順に述べる", "次の N 点", "重要度順に", "粗い方から" — verify the items that follow actually run in that order, are that many, and carry those labels. Do not announce "精度が高い順" and then list items in definition-number (increasing-precision) order. *Why:* the declaration is written as scaffolding, and if you later reorder or re-count the items the declaration is left stranded and now contradicts its own list; the reader trusts it to navigate, so a stale declaration produces a confident misreading even when every item is individually correct.
- [ ] **In a running example, each concept is attributed to the feature the paper actually blames.** When one worked example illustrates several orthogonal concepts at once, every label (which property or failure it exemplifies) was matched one-to-one to the specific feature the source names as its cause — a feature that drives one axis (e.g. an access-set property) is not offered as the cause of a different axis (e.g. an interactivity property). *Why:* papers deliberately overlay several concepts on one example, so their causes sit side by side and are easy to cross-wire; the label can be right while the attributed cause is wrong, and the sentence still reads naturally. Take attributions from the spine's running-example map rather than re-deriving them — that map is the shared source of truth that keeps this report consistent with the others that discuss the same example. But it is not infallible: if one of your assigned figures plainly contradicts a map row, trust the figure and flag the discrepancy in your reply rather than silently following a wrong row (a single wrong source propagates to every report unchecked; the Finalize sweep re-verifies the spine, but flag what you saw).

## Report templates by perspective

Every report starts with an H1 title (`# <perspective label> — <paper short title>`) and a one-line scope note (which sections / page span it covers). Then follow the assigned perspective's structure. Sections that genuinely do not apply to the paper may be dropped — note the omission in the scope line rather than padding.

### `background` → 背景と問題設定

This report answers *why this paper exists*: what is proposed, and why it matters. It is the deep version of overview items 1–2 (何を提案 / 新規性) plus the motivation the Ochiai overview compresses away. Keep it conceptual — the formal problem with notation lives in `method.md`, and the systematic prior-work catalog lives in `related-work.md`.

1. **背景・動機** — the real-world or research context driving the work: what pain / need / opportunity motivates it, and why now. Draw on the Abstract and the Introduction's opening.
2. **問題設定** — the problem the paper actually tackles, stated informally with its scope and assumptions, **and why it is hard** (the core challenges). This is the *motivating* problem, not the formal notation (that belongs in `method.md`) — keep it at the level a non-specialist can follow.
3. **既存アプローチの限界（概念レベル）** — why current approaches fall short, at a conceptual level, to establish why a new method is needed. This is the framing gap that justifies the paper, NOT a catalog of specific prior works (that belongs in `related-work.md`) — name approaches only as far as needed to make the gap concrete.
4. **提案の要旨（非技術）** — what the paper proposes at a conceptual level (the core idea, no equations) and how it addresses the problem set above. One or two paragraphs; the mechanics are `method.md`'s job.
5. **なぜ重要か・インパクト** — the significance: what becomes possible, who benefits, and why the community should care. Keep author-claimed impact and your own inference clearly separated.

Assigned figures are usually the paper's teaser / motivating-example figure — embed and explain it where it supports the motivation.

The overall conclusion you state (in 背景・動機 / 提案の要旨 / なぜ重要か) must agree with the spine's thesis — same claim, same direction (see **Inputs**: the spine). This report and the overview are written independently and are never reconciled afterward, so a divergence here becomes two conflicting conclusions in the same deliverable. Deepen and support the thesis; do not silently contradict, weaken, or reverse it.

### `method` → 技術・手法の詳細

1. **問題設定と記法** — the formal problem, inputs/outputs, notation table if the paper defines one
2. **手法の全体像** — the architecture / pipeline in a few paragraphs; include the paper's key overview figure if available, **and** redraw the pipeline as a `mermaid` flowchart in your own words (input → components → output). Re-diagramming forces a faithful understanding and gives a usable figure even when the visual path could not extract the original. Keep it to the main data flow, not every detail.
3. **コンポーネント詳細** — one subsection per component: definitions, equations (LaTeX), algorithms as numbered steps; faithful to the paper, not paraphrased into vagueness
4. **設計判断の根拠** — why this design; alternatives the paper considered or ablated
5. **計算量・実装上の注意** — complexity, training/inference cost, implementation details the paper states

### `experiments` → 実験設定と結果

1. **実験設定** — datasets (with sizes/splits), baselines, metrics, hyperparameters / implementation environment as stated
2. **主結果** — main tables reproduced compactly as Markdown tables; for each, one paragraph on what claim it supports and by how much. Every assigned result figure/plot (`ocr/figures/*`) is embedded here and read out (axes, trend, takeaway), not just linked.
3. **アブレーション** — what was removed/varied and what that shows
4. **追加分析** — qualitative results, error analysis, scaling/sensitivity studies
5. **再現性** — code/data availability **only as printed in the paper** (no guessed URLs)

### `discussion` → 議論・限界・今後

1. **主張と根拠の対応表** — a Markdown table of the paper's principal claims, each with the evidence backing it and that evidence's strength. This is the analytical core of a critical read; label each claim's support as one of `実験` (empirical), `理論` (proof/derivation), `引用` (relies on cited work), `主張のみ` (asserted, no evidence in this paper).

   | 主張 | 根拠 | 種別 | [pNN] |
   | --- | --- | --- | --- |
   | <claim> | <what backs it> | 実験 / 理論 / 引用 / 主張のみ | [pNN] |

   **Cell-check each row you write against the body, the spine, and the source — cell by cell, on three axes.** A table cell compresses a body sentence into a phrase, and that one-word compression is where a quantifier gets dropped, an entity's polarity flips, or a hedge hardens — while the body prose you already wrote stays correct, so the error is a body↔cell internal contradiction that only a per-cell re-read catches. For **both** the 主張 column and the 根拠 column of every row, confirm against the sentence it condenses (and the spine's entry / the source `[pNN]`):
   1. **Quantifier preserved** — a scope word in the source (`majority` / `大半`, `most` / `多く`, `many`, `almost all`, `at least`, `up to`, `X%`) is still in the cell and has not hardened into an all-cases claim ("the majority of the remaining 61%" must not become "the remaining 61% (all of it)").
   2. **Entity / class polarity not flipped** — a class or entity described with a negation ("a system that does *not* support X", "transactions that *have* / *lack* Y") points the same way as the source; do not turn "systems that do not support interactive transactions (= one-shot-only systems)" into "systems that do not support non-interactivity". Negated class names invert most easily under compression and still read fluently.
   3. **Modality matches the body** — a cell states a design argument / hedged expectation as such (`理論`, "can / may / 〜しうる"), not as a measured result, at the same strength the body uses.

   *Why:* a reader who skims only the table takes each cell as the sole statement of that claim, so a cell that diverges from a correct body is never self-corrected; and compression to a single phrase is exactly the operation that drops quantifiers, reverses negated classes, and flattens hedges. Take the authoritative value from the spine where it has one — the spine is the shared source the sibling reports also use, so aligning the cell to it keeps this report consistent with them.

2. **著者が明示した limitation** — as stated, with anchors
3. **議論・考察** — the paper's own discussion points, open questions it raises
4. **読み手としての批判的検討** — weaknesses or threats to validity you infer; MUST be clearly labeled as reader inference, never blended with author statements. Draw on the `主張のみ` / `引用` rows of the table above — unsupported claims are the natural targets.
5. **Future work** — as stated by the authors
6. **実務・研究への含意** — what a practitioner/researcher should take away

### `related-work` → 関連研究の位置づけ

1. **位置づけ** — organize the paper's Related Work discussion by category: for each category, the representative cited works and how this paper claims to differ. Add:
   - **特性比較マトリクス** — a Markdown table comparing this paper against its main cited alternatives across the axes the paper competes on (e.g. データ要件 / 計算コスト / 対応タスク / 前提). Use only distinctions the paper or the cited works actually state; do not invent capability claims.
   - **研究系譜** — a short `mermaid` graph placing this paper in its lineage: which prior works it builds on (arrows in) and which problem it opens. Nodes must be papers cited in this paper.
2. **次に読むべき論文** — 3–7 entries. Procedure (mandatory):
   1. Read the References section (given span) and pick candidates **only from entries that actually appear there**. Never propose an uncited paper.
   2. For each candidate, run `bash <dblp_lookup.sh path> "<reference title> <first-author surname>"` and compare authors/year against the reference entry to confirm it is the same paper. Appending the surname matters: dblp ranks by term match, and generic titles (e.g. "Attention Is All You Need") do not surface the right paper from a title-only query. If nothing hits, retry with the title alone before giving up.
   3. On a confident match, write: title — 筆頭著者 et al., venue, year, URL (dblp `url` field, which prefers the DOI link). When both a peer-reviewed venue entry and a CoRR/arXiv preprint match, cite the peer-reviewed one (the `type` field distinguishes them — a preprint reads "Informal and Other Publications").
   4. On no confident match, append "(dblp未確認)" and record only what the References entry itself states — no URL.
   5. For every entry, add 1–2 sentences: why read it next, and its relation to this paper (which part cites it, for what).

## Output

Write the report to the given output path.

## Reply

Return only the file path and a one-line summary (do not return the body). For related-work, also state how many entries were dblp-verified vs unverified. If an assigned figure contradicted a spine running-example map row, say so in one line (which row, what the figure shows) so the orchestrator can correct the shared spine.
