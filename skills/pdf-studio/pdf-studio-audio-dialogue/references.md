# References — dialogue-script generation research

Evidence base for [SKILL.md](./SKILL.md).

Gathered in two passes:

- **2026-07-03** — a deep-research pass on NotebookLM-style *English podcast* generators
  (`podcastfy`, `open-notebooklm`, NotebookLM teardowns), fan-out search → 3-vote adversarial
  verification (23 confirmed / 2 refuted of 25 claims).
- **2026-07-14** — a second pass triggered by a concrete complaint: the generated scripts felt like
  **one person's explanation merely dealt out to two speakers**. The first pass had produced good
  guidance on *pacing and format* but had never established **why a second speaker exists at all**,
  and explicitly recorded that no Japanese-genre finding had cleared the bar. This pass targeted
  that gap: the Japanese explainer-dialogue genre (ゆっくり解説 / ずんだもん×四国めたん) and the
  learning-science question of whether dialogue teaches better than monologue.

Source quality tags: **primary** = official docs / actual source code; **practitioner** = the
genre's own craft writing; **academic** = research literature; **secondary** = derived/summarized;
**interpretation** = our synthesis, not a sourced claim.

---

## Part 1 — Why a second speaker at all (2026-07-14)

This is the part the first pass missed, and it is now the spine of SKILL.md.

### 1.1 The genre names our exact failure mode

The complaint that prompted this pass is a **known, named failure** in Japanese explainer-dialogue
craft writing. The ゆっくり解説 script guide lists, as a thing to avoid:

> 「ただ説明文を2人に分けただけになってしまいます」
> — [note: 【初心者向け】ゆっくり解説の台本はこう作る！](https://note.com/yukkuri_auto/n/n707870d2fef7) (practitioner)

The same body of craft writing names the adjacent failures: **「相槌だけになってキャラクターの個性が失われる」** and **「一人が長く話し過ぎる」**
— [note: 台本のコツは「会話のキャッチボール」！](https://note.com/yukkuri_auto/n/n520f445f3df8) (practitioner)

Co-hosting craft writing states the same thing from the other direction — the problem is not
chemistry but **undesigned roles**:

> "Most co-hosted podcasts don't fail because of bad chemistry — they fail because **no one designed
> the dynamic**. A co-hosted podcast needs **more structure, not less**." … One host shouldn't simply
> **echo** the other's viewpoints.
> — [Podcast Performance Coach #254](https://podcastperformancecoach.com/254-podcasters-ultimate-guide-co-hosting-podcast/) (practitioner)

### 1.2 The effect is real — and it does NOT survive being moved into a monologue

The strongest justification for two speakers found. In vicarious-learning research, the benefit of
**deep-level reasoning questions** appeared when the questions occurred **in a dialogue**, and did
**not** appear when the same questions were presented inside a monologue:

> "The vicarious effect of observing deep questions emerged when questioning occurred in a dialogue,
> rather than when questions were presented as advance organizers in a monologue."
> "students in the dialogue condition asked significantly more deep-level reasoning questions of the
> kind that were modeled by the virtual tutee"
> — Craig et al., [The Deep-Level-Reasoning-Question Effect](https://www.researchgate.net/publication/247502153_The_Deep-Level-Reasoning-Question_Effect_The_Role_of_Dialogue_and_Deep-Level-Reasoning_Questions_During_Vicarious_Learning) (academic, **accessed via abstract/summary — original paper body not read**)

Related: a learner-side speaker who is *wrong* is itself the engine — the tutee's errors and
questions drive the observer's learning ("conflict episodes"):

> "The incorrect statements and questions of the tutee triggered more active engagement; tutees can
> serve as a model of learning; and tutees make errors which are followed by tutor feedback"
> — [Mayes, *Still to learn from vicarious learning*](https://journals.sagepub.com/doi/pdf/10.1177/2042753015571839) (academic),
> [Oregon State: the power of vicarious learning](https://blogs.oregonstate.edu/inspire/2024/06/10/difficult-content-try-the-power-of-vicarious-learning/) (secondary)

**Why this is load-bearing for SKILL.md:** it cuts both ways. It justifies the two-speaker form, *and*
it says the justification is conditional. A narrator who says 「〜と思うかもしれませんが」 gets no such
effect. The misconception has to be **uttered by the other speaker** and then destroyed. Two voices
reading a split lecture do not clear this bar.

### 1.3 The listener-speaker is the audience's proxy

> 「質問する人が、読んでる人/見てる人の代弁者として機能すると、話してる人の話してることがわかりやすい」
> — [note: ゆっくり解説って対話篇では？](https://note.com/tfsoo5963/n/nb01c4c210125) (practitioner)

> 「『これってどういうこと？』といった疑問をキャラクターが代弁してくれるため、読者が自分ごととして読みやすくなります」
> — [kabetee: 対話形式のコンテンツ](https://www.kabetee.com/post/対話形式のコンテンツも簡単に制作可能！) (practitioner)

Role definition in the genre: **霊夢＝視聴者の代わりに疑問を出す役 / 魔理沙＝答えをわかりやすく説明する役**
— [note: yukkuri_auto](https://note.com/yukkuri_auto/n/n707870d2fef7) (practitioner)

---

## Part 2 — The move catalog (2026-07-14)

Named, templated moves from the genre's own craft writing. These are the source of SKILL.md's
"A's turns are moves, not reactions" table. All example lines are quoted from the sources.

| Genre's name | Move | Quoted example |
|---|---|---|
| **勘違いツッコミ型** | Listener voices the wrong-but-plausible understanding; it gets broken | 霊夢「つまり○○すれば全部解決ってことね！」→ 魔理沙「そんな単純な話じゃないぜ」 |
| **疑問提示型** | Listener paraphrases in their own words; gets corrected | 霊夢「へぇ、つまり□□ってこと？」→ 魔理沙「近いけど、正確には△△なんだ」 |
| **数字で驚かせる型** | Listener doubts; explainer must produce evidence | 霊夢「それって本当にすごいの？」→ 魔理沙「数字で見るとわかりやすいぜ」 |
| **まとめ誘導型** | Listener declares saturation, commissions the summary | 霊夢「ここまでの話をまとめると、どういうこと？」→ 魔理沙「ポイントは3つだぜ」 |
| (abstraction → concrete) | Listener refuses an abstraction | 質問役「これはどういうこと？」「もっと詳しく教えて」「なぜそうなるの？」→ 解説役「例えば、こういうことです」 |

— all from [note: yukkuri_auto 掛け合いのコツ](https://note.com/yukkuri_auto/n/n707870d2fef7) and
[note: 会話のキャッチボール](https://note.com/yukkuri_auto/n/n520f445f3df8) (practitioner);
role/ボケツッコミ framing corroborated by [coconala: 基礎から学ぶゆっくり解説 #15](https://coconala.com/blogs/5189435/550526) (practitioner).

**Beat structure.** The genre gives a per-topic cycle, not one exchange per topic:

> 「質問 → 答え → リアクション → 補足 → 驚き → 結論」…「それぞれのトピックについて、テンポよくこの流れを意識する」
> — [note: 会話のキャッチボール](https://note.com/yukkuri_auto/n/n520f445f3df8) (practitioner)

Also stated as 「霊夢が問いかける → 魔理沙が解説する → 霊夢が驚く → 魔理沙がツッコむ」
— [coconala #15](https://coconala.com/blogs/5189435/550526) (practitioner). SKILL.md compresses this
to a ~4-turn beat.

**Roles are functional, not fixed.** In ずんだもん×めたん, 解説系 usually casts ずんだもん as the
explainer and めたん as the question-asker, while 日常/茶番 inverts the boke/tsukkomi assignment
— [pixiv百科事典「もんめた」](https://dic.pixiv.net/a/もんめた) (secondary).
*Interpretation:* which character teaches is arbitrary; what is required is the **asymmetry** plus a
listener who can be wrong. SKILL.md keeps A=learner / B=explainer purely as a convention.

**Answers should carry a surplus.** Scriptwriting craft warns against pure Q&A: an answer should
carry emotion/irony/a hook, which becomes the next turn's handle.
NG「おいしかったよ」/ OK「おいしかったよ。カビが生えてたけどね」
— [かかねば: 脚本のセリフの書き方](https://kakaneba.com/scenario-serif/) (practitioner). The same
article warns against explanatory monologue and against packing one line with information.

---

## Part 3 — Dead-dialogue samples (what NOT to imitate)

Kept deliberately: the previous version of this skill's own `sample-dialogue.txt` was an example of
this failure (A asked questions and made noises; B carried 100% of the content; deleting A lost
nothing). It has been replaced.

Field samples of the failure, for calibration:

> ずんだもん「今日は雨がふりそうなのだ」/ 四国めたん「そうね、曇ってきたわね」
> — [note: 寸劇エンジン](https://note.com/akb428/n/nd277e2d7b2f3) (practitioner) — the reply does not
> require the prompt; nothing is at stake.

> 「会話では相槌や共感を頻繁に入れ、聞き役として支える（例：『そうね』『確かにそうね』『よかったわね』）」
> — [きりしま屋: 四国めたんカスタマイズ](https://kirishima.it/mt/2025/09/emu-one_lily_customise.html) (practitioner)
> — a **listener-as-emotional-support** design. In an explainer context this actively kills the
> dialogue: it never voices a misconception, never checks a paraphrase, never demands evidence.

AI-generated ゆっくり解説 openings where the listener's turns touch no content at all (pure
expectation-setting: 「でも、わかりやすく教えてくれるんだよね？」)
— [AIアシスタント: ゆっくり解説の台本を生成](https://blog.ai-assistant.jp/ゆっくり解説の台本を生成してもらう/) (practitioner).

**The deletion test** in SKILL.md (remove all of A's turns; if B alone still stands as a complete
solo explanation, the dialogue was pointless) is our formalization — *interpretation*, derived from
the sourced failure modes above rather than quoted from any one source.

---

## Part 4 — Pacing, format, and length (mostly from the 2026-07-03 pass)

These findings survive; they govern *how* turns are written, not *why* there are two speakers.

### Format

- Two-speaker scripts use **explicit per-line speaker labels**. Podcastfy uses `<Person1>`/`<Person2>`;
  open-notebooklm constrains speaker to a `Literal["Host (Jane)", "Guest"]` field. `3-0`
  — [podcastfy](https://github.com/souzatharsis/podcastfy),
  [together.ai](https://docs.together.ai/docs/open-notebooklm-pdf-to-podcast) (primary)
- Gemini multi-speaker TTS expects the same labeled-transcript convention. `3-0`
  — [ai.google.dev](https://ai.google.dev/gemini-api/docs/speech-generation) (primary)
  → validates this plugin's backend-agnostic `A:` / `B:` line format.

### Turn length

- open-notebooklm enforces a **~100-character cap per line**. `3-0`
  — [open-notebooklm/prompts.py](https://github.com/gabrielchua/open-notebooklm/blob/main/prompts.py) (primary)
- Japanese craft writing agrees, tighter: **1文20〜30文字が理想**
  ([note: PREP法](https://note.com/yukkuri_auto/n/n726f6da29fde)); ずんだもん script prompts use
  **1セリフ70文字以下・句点で改行** ([Zenn: なぎそら](https://zenn.dev/nagisora/articles/d351f437a85216)) (practitioner).
- ⚠️ **Necessary, not sufficient.** A lecture chopped into 100-char alternating pieces still fails
  the deletion test. The first version of this skill had the cap and still produced the complaint
  that started Part 1.

### Two-stage generation

- **Scratchpad-before-script** is what these generators rely on:
  > "In the <scratchpad>, creatively brainstorm ways to present the key points engagingly."
  `3-0` — [open-notebooklm/prompts.py](https://github.com/gabrielchua/open-notebooklm/blob/main/prompts.py) (primary)
- NotebookLM's own pipeline is **multi-stage** (outline → detailed script → critique/revise). `3-0`
  — [simonwillison.net](https://simonwillison.net/2024/Sep/29/notebooklm-audio-overview/) (secondary)
- ⚠️ **Amended 2026-07-14**: a scratchpad of *points* is not enough — that is precisely how a solo
  lecture gets planned and then split. SKILL.md now requires the scratchpad to plan **where a listener
  trips** (the misconception per point), which is the fuel for A's moves.

### Naturalness / fillers

- Naturalness is **explicitly prompted**, not emergent (fillers + interruptions). `3-0`
  — [together.ai](https://docs.together.ai/docs/open-notebooklm-pdf-to-podcast),
  [open-notebooklm](https://github.com/gabrielchua/open-notebooklm/blob/main/prompts.py) (primary)
- ⚠️ **TTS caveat:** those sources target neural TTS (Gemini/ElevenLabs) that renders "um" convincingly.
  VOICEVOX reads inserted 「えーと」「あの…」 poorly → keep fillers light. (Unchanged.)

### Length

- The 2026-07-03 pass produced a **runtime target table** (~10 min ≈ ~3,200 chars ≈ ~50 turns at the
  measured **~340 chars/min** VOICEVOX rate).
- ❌ **Retired 2026-07-14 as a target.** Writing to a runtime creates pressure to pad, and padding is
  filled with exactly the contentless 相槌 exchanges that break the dialogue. If two speakers must earn
  their keep per exchange, then a script that cannot earn 10 minutes should be shorter — a single
  narrator would be both shorter and smoother. The **~340 chars/min** figure is retained purely to
  *estimate and report* duration, never to inflate a script toward one.

### Arc / structure (retained, uncontroversial)

- Podcastfy's default `dialogue_structure`: **Introduction → Main Content Summary → Conclusion**. `3-0`
  — [podcastfy](https://github.com/souzatharsis/podcastfy) (primary)
- Japanese equivalents: 導入 → 本題 → まとめ, written **from the conclusion backwards**, 1テーマ1結論 +
  3 supporting elements — [note: 台本は「結末から」書く](https://note.com/yukkuri_auto/n/n1e9793ed3969) (practitioner)

---

## Refuted / retired

- ❌ "**Banter** as a *core naturalization technique*." `1-2` (2026-07-03) — over-formalized.
- ❌ "NotebookLM defines a **listener persona** and opens with a stage-setting overview." `0-3` (2026-07-03).
- ❌ **Runtime targets** (~10 min / ~50 turns as a goal) — retired 2026-07-14, see *Length* above.
- ❌ **"A = navigator/anchor, B = explainer; A drives, B delivers"** — retired 2026-07-14. This framing
  (from the English podcast host/guest model) is a division of **stage duties**, not of
  **understanding**, and it is what produced the split-lecture defect: a navigator's turns need not
  reveal any state of understanding, so they collapse into questions and 相槌. Replaced by
  **A = learner (can be wrong) / B = explainer**.
- ⚠️ **Unverified / not found** (flagged honestly, not applied as if sourced): a named template for
  "listener races ahead and is pushed back", for "listener raises a genuine counter-argument (as
  opposed to a mistake)", or for "explainer Socratically questions the listener". These plausibly
  occur in real videos but no craft source was found defining them. The genre's templates cast the
  listener as **the one who is mistaken**, not as an opponent — correction, not debate, is the engine.
- ⚠️ **Not obtained:** verbatim transcripts of actual ずんだもん×めたん explainer videos (YouTube/ニコニコ
  bodies were not fetchable). The move catalog therefore rests on the genre's *craft writing* and
  published templates, which state the moves explicitly, rather than on measured video corpora.

---

## Sources

| Source | Quality | Angle |
| --- | --- | --- |
| [note: ゆっくり解説の台本はこう作る（掛け合いのコツ）](https://note.com/yukkuri_auto/n/n707870d2fef7) | practitioner | **move catalog; names our failure mode** |
| [note: 台本のコツは「会話のキャッチボール」](https://note.com/yukkuri_auto/n/n520f445f3df8) | practitioner | beat cycle; 相槌-only failure |
| [note: ゆっくり解説の台本（PREP法）](https://note.com/yukkuri_auto/n/n726f6da29fde) | practitioner | line length, structure |
| [note: 台本は「結末から」書く](https://note.com/yukkuri_auto/n/n1e9793ed3969) | practitioner | structure |
| [coconala: 基礎から学ぶゆっくり解説 #15](https://coconala.com/blogs/5189435/550526) | practitioner | roles, boke/tsukkomi |
| [note: ゆっくり解説って対話篇では？](https://note.com/tfsoo5963/n/nb01c4c210125) | practitioner | listener-as-proxy |
| [かかねば: 脚本のセリフの書き方](https://kakaneba.com/scenario-serif/) | practitioner | anti-Q&A; answer surplus |
| [pixiv百科事典: もんめた](https://dic.pixiv.net/a/もんめた) | secondary | role assignment in 解説系 |
| [Craig et al.: Deep-Level-Reasoning-Question Effect](https://www.researchgate.net/publication/247502153_The_Deep-Level-Reasoning-Question_Effect_The_Role_of_Dialogue_and_Deep-Level-Reasoning_Questions_During_Vicarious_Learning) | academic (abstract only) | **dialogue > monologue** |
| [Mayes: Still to learn from vicarious learning](https://journals.sagepub.com/doi/pdf/10.1177/2042753015571839) | academic | tutee errors drive learning |
| [Podcast Performance Coach: co-hosting](https://podcastperformancecoach.com/254-podcasters-ultimate-guide-co-hosting-podcast/) | practitioner | undesigned roles; no echoing |
| [note: 寸劇エンジン](https://note.com/akb428/n/nd277e2d7b2f3) | practitioner | dead-dialogue sample |
| [きりしま屋: 四国めたんカスタマイズ](https://kirishima.it/mt/2025/09/emu-one_lily_customise.html) | practitioner | dead-dialogue sample (support-role listener) |
| [Zenn: ずんだもん台本プロンプト](https://zenn.dev/nagisora/articles/d351f437a85216) | practitioner | line-length constraint |
| [gabrielchua/open-notebooklm — prompts.py](https://github.com/gabrielchua/open-notebooklm/blob/main/prompts.py) | primary | scratchpad, 100-char cap |
| [souzatharsis/podcastfy](https://github.com/souzatharsis/podcastfy) | primary | labels, arc |
| [Together AI — open-notebooklm PDF-to-podcast](https://docs.together.ai/docs/open-notebooklm-pdf-to-podcast) | primary | prompt design |
| [ai.google.dev — Gemini TTS](https://ai.google.dev/gemini-api/docs/speech-generation) | primary | labeled-transcript format |
| [simonwillison.net — NotebookLM audio overview](https://simonwillison.net/2024/Sep/29/notebooklm-audio-overview/) | secondary | multi-stage pipeline |
| [blog.google — NotebookLM Audio Overviews](https://blog.google/technology/ai/notebooklm-audio-overviews/) | primary | host behaviors |
