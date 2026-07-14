---
name: pdf-studio-audio-dialogue
description: This skill should be used when the user wants a NotebookLM-style audio guide / audio overview / two-host podcast of a document — the FIRST step, writing the two-speaker dialogue script (台本). Triggers on "音声ガイドを作って", "この本の音声概要が欲しい", "ポッドキャスト風の対話にして", "NotebookLMみたいな音声を作りたい", "make an audio guide / audio overview", "turn this report into a two-host dialogue script". Works on any Markdown, especially pdf-studio reports. Should NOT trigger for the audio synthesis step itself (use pdf-studio-audio-narrate), or for producing the source report (use pdf-studio-summarize / pdf-studio-deep-dive).
user-invocable: true
---

# Audio Dialogue Script

Rewrite a Markdown document into a **two-speaker dialogue script** (台本) — the NotebookLM "audio overview" shape — as the first of two steps. This skill produces only the *script*; [[pdf-studio-audio-narrate]] turns that script into an audio file. Keeping the two apart lets the script be reviewed/edited before synthesis, and lets the audio backend change without touching how the dialogue is written.

The two speakers are **not two hosts sharing a lecture**. They differ in *understanding*: one has not got it yet, the other explains. That asymmetry is the whole reason the script is a dialogue rather than a narration — see *Why two speakers at all* below, which governs everything else here.

## When this applies

The input is **any Markdown**; nothing is hard-wired to a specific file. In particular, any pdf-studio artifact works:

- `reports/overview.md` (whole-document overview) → a **broad guide** touring every top-level section.
- a **deep-dive** `reports/<section>.md` report → a **focused, deeper guide** on that one part.
- `structured/outline.md`, or any other Markdown, also works.

Pick whichever source matches the guide the user wants. If they want a guide over a document that has not been digested yet, run [[pdf-studio-summarize]] first (or just point this skill at any existing Markdown).

## Output location

Write the script under a `dialogue/` directory, kept separate from the synthesized audio (which [[pdf-studio-audio-narrate]] puts in a sibling `audio/` directory):

- If the source is inside a pdf-studio work dir (`<dir>/<name>/`), write to `<WORK_DIR>/dialogue/<slug>.txt`.
- Otherwise write `dialogue/<slug>.txt` next to the source Markdown.

`<slug>` names the source: `overview` for `reports/overview.md`, the section slug for a deep-dive report (e.g. `chapter-2`), otherwise the source basename. Create the `dialogue/` directory if missing. The dialogue script is the editable text artifact; keeping it apart from generated `audio/` (which is disposable and re-synthesizable) makes it easy to review and edit before narration. Because the script is meant to be hand-edited, **don't silently overwrite one**: if `dialogue/<slug>.txt` already exists, confirm before replacing it — overwrite, keep it, or write under a different slug.

## Dialogue script format

Plain text. One turn per speaker, prefixed with `A:` or `B:`. This is exactly what [[pdf-studio-audio-narrate]] consumes.

```
# style: zundamon
# Lines starting with '#' are comments and are ignored.
A: これって要するに、全部まとめて読ませればいいって話でしょう？
B: それだと崩れるのだ。後半を読む頃には、前半を忘れているのだ。
A: 接頭辞のない行は、
   直前の話者の発話としてそのまま続きます。
```

(The exchange above also shows the shape to aim for — A is *wrong* and B has to break the wrong idea. See *Why two speakers at all* below.)

- **First line: `# style: <preset>`** — the style preset this script is written in (see *Style presets* below). It is a `#` comment, so [[pdf-studio-audio-narrate]] ignores it as spoken text but reads it to pick the matching voices automatically. Always emit it.
- `A:` / `B:` (lowercase and full-width `：` also accepted) starts a turn.
- Lines without a prefix continue the current turn.
- `#` lines and blank lines are ignored.

## Style presets (口調 & voices)

A **style preset** bundles a 口調 (how the two speakers talk) with the VOICEVOX voices [[pdf-studio-audio-narrate]] uses to read them. Pick one up front — from the user's request, else default to `zundamon` — write the whole script in that 口調, and record it as the `# style:` marker.

| Preset | Speaker A (learner) | Speaker B (explainer) |
|--------|----------------------|-----------------------|
| `zundamon` *(default)* | 四国めたん調: フレンドリーな女の子口調。「〜わね」「〜かしら」「〜なの？」、一人称は「わたし」。 | ずんだもん調: 語尾を「〜のだ／〜なのだ」、疑問は「〜なのだ？」、一人称は「ボク」。素直で元気。 |
| `natural` | 普通のフレンドリー敬体（ですます）。 | 普通の解説者の敬体（ですます）。 |
| `formal` | 硬めの敬体・端正。 | 硬めの敬体・落ち着いた専門家。 |

- The **roles** (A=学習者 / B=解説者) are the same across presets; only the 口調 and voices change. The 口調 is cosmetic — the roles below are what make the script work.
- Keep the 口調 **consistent for the whole script** and apply it to both speakers. For `zundamon`, B ends most turns with 「〜のだ」系 and A uses the light「〜わね／かしら」register; don't let either drift back into plain 敬体.
- Character 口調 still follows the TTS-ready rules below (short turns, no markup, readable numbers/acronyms). Flavour is in sentence endings and word choice, not in heavy dialect.
- If the user names a preset or characters (e.g.「フォーマルで」「ずんだもんで解説して」), use it; if a matching preset does not exist, either map it to the closest one or add a new preset in both this skill and [[pdf-studio-audio-narrate]] (the voice mapping lives there).

## Why two speakers at all — the one rule

**A dialogue is only worth writing if the second speaker changes what the listener understands.**

Two speakers cost something: the flow is less direct and the runtime is longer than a single narrator saying the same thing. The only thing that buys that back is an **asymmetry of understanding**. Speaker A does *not* yet get it; speaker B does. Because A is in the room, the explanation is dragged down to where A stands — and that is where the listener stands too. Nothing else about having two voices helps.

This is not a stylistic preference; it is the failure mode this skill exists to avoid. The genre names it outright: writing two speakers badly produces a script that is 「ただ説明文を2人に分けただけ」 — one person's lecture, chopped up and dealt out to two mouths. And the effect is known to be fragile: in vicarious-learning studies, deep questions raised the audience's own reasoning **only when they occurred in a dialogue**, and the effect vanished when the same questions were folded into a monologue. A narrator who says 「〜と思うかもしれませんが、違います」 merely *mentions* a misconception. When A actually says it and is corrected, the misconception is voiced, briefly believed, and destroyed — an event a single narrator physically cannot stage.

So: **if the two-speaker version does not teach better than one voice would, one voice is the correct answer** — it flows better and it is shorter. Every exchange must earn its place by that test.

### The deletion test (apply it to your own draft)

Delete every one of A's turns and read B's turns back to back. **If the result still works as a solo explanation with nothing lost, the dialogue was pointless** — rewrite it. In a script that works, deleting A destroys something: a misconception that never gets voiced and therefore never gets destroyed, a paraphrase that never gets corrected, a claim that never gets challenged into producing evidence.

## A's turns are *moves*, not reactions

A is not a host, not an MC, and not an audience member making appreciative noises. A is **the listener who has not understood yet**, and A's job is to *act on* the explanation. A turn that merely reacts (「なるほど」「そうなのね」「すごいわ」) exposes nothing about A's state of understanding, so it gives B nothing to correct and moves nobody forward. **A script can contain zero 相槌 and be excellent. A listener who is never wrong about anything can be deleted.**

Give A these moves (each one is a thing a solo narrator cannot do). Examples in `zundamon` 口調; adapt to the preset:

| Move | What A does | Example |
|---|---|---|
| **誤解の提示** | States the plausible-but-wrong understanding the audience is already forming, and gets it broken | A:「つまり、全部まとめてAIに読ませればいいってことでしょう？」→ B:「それだと崩れるのだ」 |
| **言い換えの検算** | Restates B's point in A's own words, slightly off, and is corrected | A:「要するに□□ってこと？」→ B:「近いのだ。でも正確には△△なのだ」 |
| **根拠の要求** | Doubts the claim, forcing B to produce evidence, numbers, or a mechanism | A:「それ、本当にそんなに効くのかしら」→ B:「数字を見るのだ」 |
| **具体の要求** | Refuses an abstraction until it is grounded | A:「抽象的すぎるわ。例えばどういう場面なの？」 |
| **要約の発注** | Declares saturation and commissions the summary | A:「ここまでを一度まとめてくれる？」→ B:「大事なのは三つなのだ」 |

The **誤解の提示** is the load-bearing one. It is what makes the audience's half-formed wrong idea get built and demolished *on the recording*, instead of being left intact in their head. If a script has none, it almost certainly fails the deletion test.

B's turns have a duty too: **B must actually respond to what A said.** If B would have said the same sentence regardless of A's turn, then the speaker change was just a line break. B's answer should visibly change shape because of A — correcting the wrong word, dropping to a concrete example, conceding a point before qualifying it.

## Beat structure — one point, several turns

Do not spend one exchange per topic; that is what produces the Q&A metronome. Work each real point as a **beat of roughly 4 turns**: 問いかけ → 解説 → (誤解 or 言い換え) → 訂正. Related shapes from the genre: 質問 → 答え → リアクション → 補足 → 驚き → 結論.

Two speakers **stay on one point and work it**, rather than each announcing the next bullet in turn. If a topic is disposed of in a single A-asks/B-answers pair, ask whether it needed A at all.

## How to write it (two stages)

**Plan the friction, then script.** Do not write the script cold. First jot a private scratchpad. Crucially, the scratchpad is **not just an outline of points** — an outline of points is exactly what produces a solo lecture split in two. For each load-bearing point also plan **where a listener trips**:

1. The source's 3–6 load-bearing points, in order.
2. For each point: **what a smart listener would plausibly get wrong about it** — the too-simple version, the wrong analogy, the step that seems skippable. This is the fuel for A's 誤解の提示; without it, A has nothing to be wrong about.
3. Where an abstraction needs a concrete example, and where a claim needs evidence.
4. A one-line hook and the closing takeaway.

Only the final `A:`/`B:` script is written to the file; the scratchpad is scaffolding.

## The rest of the craft

- **Short turns, switch often.** Keep any single turn short — a few sentences, roughly **~100 characters per line as a cap**. Long monologues from B are the classic failure. (Note this is necessary, not sufficient: chopping a lecture into 100-char pieces and alternating them still fails the deletion test.)
- **Natural, but calibrated for TTS.** A little spoken texture helps, but go easy on fillers: VOICEVOX reads inserted 「えーと」「あの…」 awkwardly. Prefer naturally flowing phrasing over sprinkled filler words.
- **Faithful to the source.** Cover the source's real points; do not invent facts. A's misconceptions are *staged*, and B must correct them from the source — never invent a wrong fact that goes uncorrected.
- **Depth follows the source.** An overview (`reports/overview.md`) → a broad tour of every top-level section. A deep-dive report → go deep on that one part, keeping the specifics (definitions, figures, mechanisms).
- **Spoken Japanese, TTS-ready.** No headings, bullets, markup, code blocks, or URLs read aloud. **Drop `[pNN]` page anchors.** Keep the register consistent with the chosen style preset. Gloss tricky readings, English acronyms, and ambiguous numbers so the TTS says them right.
- **Arc.** Open with a one-line hook; build from simpler to more complex; close with a short wrap-up and a final takeaway.

## Length is an outcome, not a target

**Do not write to a runtime.** The script is as long as the source's points and the listener's stumbling blocks require, and no longer. Padding to hit a number is how a script fills up with empty 相槌 and hollow exchanges — the exact defect this skill is built to prevent. **If the material only supports a tight 4 minutes, produce 4 minutes.** A short script that earns every exchange beats a 10-minute one that does not.

If the user *asks* for a length ("5分で", "15分くらい"), treat it as a **budget for how much of the source to cover** — cover fewer points more properly, or more points — not as a quota of turns to fill. Say so if the source cannot honestly fill the requested time.

For estimating only (not for targeting): at the default VOICEVOX rate Japanese audio runs **~340 characters/minute**, so ~3,200 spoken characters ≈ 10 minutes. Use this to *report* the expected duration, and to sanity-check that a requested length is achievable — never to inflate a script up to it.

## Hand off to synthesis

After writing the script, tell the user the script path and that [[pdf-studio-audio-narrate]] can turn it into audio (or offer to run it). Do not synthesize audio here.

## Success criteria

- [ ] **Passes the deletion test**: with all of A's turns removed, B's turns alone do NOT stand as a complete solo explanation — something load-bearing is lost. (If they do stand alone, the script is a lecture split in two: rewrite, don't ship.)
- [ ] A voices at least one **誤解の提示** or **言い換えの検算** that B corrects. A is wrong, or at least imprecise, somewhere.
- [ ] No turn by A consists solely of a reaction or a content-free prompt (「なるほど」「すごいわね」「次は？」).
- [ ] B's answers are visibly shaped by A's turns — B is responding, not reciting the next paragraph.
- [ ] A dialogue script file exists in the `A:`/`B:` format under `dialogue/`, parseable by [[pdf-studio-audio-narrate]] (at least one `A:` and one `B:` turn).
- [ ] Content is faithful to the source; A's misconceptions are staged and always corrected, never left standing as fact.
- [ ] No markup, `[pNN]` anchors, or page-only artifacts remain in the spoken text.

## References

- `references.md` — the evidence base: why a second speaker earns its keep (vicarious-learning research), the Japanese explainer-dialogue genre's own move catalog (ゆっくり解説 / ずんだもん×めたん), and the NotebookLM/podcast sources for pacing and format. *Read when refining the dialogue-writing patterns.*
