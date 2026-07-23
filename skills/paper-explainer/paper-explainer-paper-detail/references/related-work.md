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
