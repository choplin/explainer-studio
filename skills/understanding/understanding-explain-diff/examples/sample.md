---
title: リトライ処理の導入 — diff 解説
lang: ja
meta: "PR #123 · feature/retry → main · 4 files, +120 −30"
has-diffs: true
has-diagrams: true
reviewed-label: 確認済み
risk-labels:
  high: 要精査
  medium: 流し読み
  low: 確認不要
context-css: explain-diff.css
toc-heading: 目次
footer: "understanding-explain-diff で生成 · 対象 4 ファイル"
---

::: {.review-plan heading="レビュー計画"}
::: {.budget}
::: {.budget-item risk=high}
**精読が必要**: 1 チャンク（推定 ~10 分）
:::
::: {.budget-item risk=low}
**確認不要**: 機械的リネーム 2 ファイル（パターン検証済み）
:::
:::
:::

## 背景

この変更はネットワーク呼び出しにリトライを足す。

::: {.inferred-note}
この節はコンテキスト資料がないため diff とコミットメッセージからの推測です。
:::

## メンタルモデル

一発呼び出しから、指数バックオフ付きの再試行へ。

::: {.ba-pair}
::: {.ba-before}
**Before** タイムアウトすると即座に例外を送出していた。
:::
::: {.ba-after}
**After** 3 回まで指数バックオフで再試行してから諦める。
:::
:::

## 図

```mermaid
flowchart LR
  A["call"] --> B["retry?"]:::added
  B --> C["backoff"]:::added
  classDef added stroke:#3ca370,stroke-width:2px;
```

## ガイド付きウォークスルー

::: {.chunk risk=high id=retry-core pattern="guard clause 追加" files="src/net/client.ts, src/net/retry.ts" tested=no verify="テストなし — 挙動は要精査"}
再試行の中核。[呼び出し元 5 箇所すべて更新済み（rg で確認）]{.verified}。

| 状況 | 旧の挙動 | 新の挙動 |
|---|---|---|
| タイムアウト3回 | 例外を送出 | 指数バックオフで再試行 |

```{.diff-source}
diff --git a/src/net/client.ts b/src/net/client.ts
--- a/src/net/client.ts
+++ b/src/net/client.ts
@@ -10,6 +10,8 @@ function call()
 const res = fetch(url)
-return res
+return withRetry(() => fetch(url), 3)
```
:::

::: {.chunk risk=low id=rename-fanout files="src/a.ts, src/b.ts" tested=yes verify="tested by src/net/retry.test.ts"}
呼び出し名のリネーム波及のみ。挙動変化なし。
:::

## レビューポイント

::: {.review-point}
**バックオフ上限**: 再試行回数 3 は妥当か。負荷とレイテンシのトレードオフを確認してほしい。
:::
