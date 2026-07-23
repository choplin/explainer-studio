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
