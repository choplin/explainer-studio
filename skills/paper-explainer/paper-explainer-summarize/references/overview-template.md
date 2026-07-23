## overview.md template

Fill every placeholder; body language follows the conversation. Drop pointer lines for out-of-scope reports.

```markdown
# <論文タイトル>

> **TL;DR**: <3 行以内。何を・どうやって・どれくらい効いたか。形容詞ではなく事実で。
>  複数の結果があるなら、論文自身がそれらの間に下す総合判断（優劣・非対称・トレードオフ）を1文で必ず含める — 個別数値の羅列で終わらせない。>

`タグ: <新手法 | 分析 | ベンチマーク/データセット | システム | サーベイ から該当するもの>`

| 項目 | 内容 |
| --- | --- |
| タイトル | <original title> |
| 著者 | <authors> |
| 会議/ジャーナル | <venue, or 不明 (preprint)> |
| 年 | <year> |
| DOI / URL | <as printed in the paper only> |

BibTeX: [`../paper.bib`](../paper.bib)

<!-- The paper's single most explanatory figure, from ocr/figures/ (named by paper number). -->
![key figure](../ocr/figures/fig-01.ext)
*Figure N ([pNN]): <one-line caption>*

## 1. 何を提案している?
<Include a one-sentence "X は Y する Z である" definition of the core, then briefly expand.>

## 2. 先行研究と比べて新規な部分は?
<"<a specific prior method named in the paper> では〜だったが、本研究は〜" contrast.
 Do not use an anonymous comparison target like "既存手法" / "従来研究".>

→ 詳細（背景・問題設定・提案の意義）: [background.md](background.md)

## 3. 技術・手法のキモは?
<Two paragraphs: (1) the intuition for *why it works*, no equations; (2) one technical paragraph.>

→ 詳細: [method.md](method.md)

## 4. 有効性の検証はどのように行った?
<Numbers required: up to three key results as "<baseline> 比 +N% on <benchmark>".
 Adjective-only claims ("大幅に改善") are not acceptable.
 Each number states its scope — the method/definition/setting it holds under, its population
 (all cases or a named subset), and whether it is a bound/mean/median/quantile — so a conditional
 or subset result is not read as a universal one. When juxtaposing per-unit averages, label any
 "among the K …" subset average and do not list it beside a whole-set average as if the denominator
 were the same.>

→ 詳細: [experiments.md](experiments.md)

## 5. 議論はある?
<Author-stated limitations and reader-inferred critique, kept clearly separate.
 著者のヘッジ（can/may/suggests・設計論証か実測か）を保存し、留保付き主張を確定事実として書かない。>

→ 詳細: [discussion.md](discussion.md)

## 6. 次に読むべき論文は?
- <title> — <筆頭著者> et al., <venue>, <year>. <URL または (dblp未確認)> — <relation to this paper>

→ 詳細: [related-work.md](related-work.md)

## 前提知識
<Up to five concepts needed to read this paper, one line each; "特になし" if none.>

## 原文の読み方
<Recommended reading path for a time-pressed reader, ≤3 lines.
 e.g. "Fig. 2 → §3.2 → Table 1 で骨子が掴める".>

## Section map
- [p01–p02] 1 Introduction
- ...
- [p09–p10] References
```
