---
name: explainer-audio-dialogue
description: "Write a NotebookLM-style two-speaker dialogue script from Markdown. Use when the user wants an audio guide, audio overview, or podcast-style dialogue but no A:/B: script exists yet. Use explainer-audio-narrate to synthesize an existing script."
user-invocable: true
---

# Audio Dialogue Script

Rewrite a Markdown document into a **two-speaker dialogue script** (台本) — the NotebookLM "audio overview" shape — as the first of two steps. This skill produces only the *script*; [[explainer-audio-narrate]] turns that script into an audio file. Keeping the two apart lets the script be reviewed/edited before synthesis, and lets the audio backend change without touching how the dialogue is written.

The two speakers are **not two hosts sharing a lecture**. They differ in *understanding*: one has not got it yet, the other explains. That asymmetry is the whole reason the script is a dialogue rather than a narration — see *Why two speakers at all* below, which governs everything else here.

## When this applies

The input is **any Markdown**; nothing is hard-wired to a specific file. In particular, any pdf-explainer artifact works:

- `reports/overview.md` (whole-document overview) → a **broad guide** touring every top-level section.
- a **deep-dive** `reports/<section>.md` report → a **focused, deeper guide** on that one part.
- `structured/outline.md`, or any other Markdown, also works.

Pick whichever source matches the guide the user wants. If they want a guide over a document that has not been digested yet, run [[pdf-explainer-summarize]] first (or just point this skill at any existing Markdown).

When invoked as a source-workflow phase, first apply
[[explainer-content-workflow-base]], read the selected profile, and require exact
paths and digests for the run request, selected Content brief, Run Manifest,
planned dialogue entry, profile structure/evidence, and source report. Validate
them before applying the guide-design procedure. Use the entry's destination,
source divisions, and explanatory-obligation references as planning context.
Return a structured missing/incompatible-input result rather than recovering
choices from prior conversation or selecting the latest planning Artifact.

Continue to treat the named report as the immediate content source, and consult
the canonical structure, other reports, or narrow source loci when the script
needs book-wide context or fidelity checks. Planning Artifacts supplement those
sources; they never replace them. Set-level fan-out and human interaction belong
to the workflow coordinator, not to this single-script authoring skill.

For an unrelated standalone Markdown input, the Markdown file and explicitly
supplied output choices are the complete Artifact input. Continue with the
normal single-document procedure without inventing workflow Artifacts.

Before planning any script, read `audio-guide-design.md`. It owns the content
selection, explanatory depth, multi-guide calibration, and size diagnostics that
make the result an audio guide rather than a spoken report. This file owns the
two-speaker dialogue mechanics applied after that selection.

## Output location

Write the script under a `dialogue/` directory, kept separate from the synthesized audio (which [[explainer-audio-narrate]] puts in a sibling `audio/` directory):

- If the source is inside a pdf-explainer work dir (`<dir>/<name>/`), write to `<WORK_DIR>/dialogue/<slug>.txt`.
- Otherwise write `dialogue/<slug>.txt` next to the source Markdown.

`<slug>` names the source: `overview` for `reports/overview.md`, the section slug for a deep-dive report (e.g. `chapter-2`), otherwise the source basename. Create the `dialogue/` directory if missing. The dialogue script is the editable text artifact; keeping it apart from generated `audio/` (which is disposable and re-synthesizable) makes it easy to review and edit before narration. In a planned workflow, write only the exact Manifest path: `create` must fail if it exists, while `replace` authorizes replacing that path only. In standalone use, do not silently overwrite an existing script; confirm whether to replace it, keep it, or use a different slug.

## Dialogue script format

Plain text. One turn per speaker, prefixed with `A:` or `B:`. This is exactly what [[explainer-audio-narrate]] consumes.

```
# style: natural
# Lines starting with '#' are comments and are ignored.
A: この行で話者Aの発話が始まります。
B: この行で話者Bに切り替わります。
   接頭辞のない行は、
   直前の話者の発話としてそのまま続きます。
```

- **First line: `# style: <preset>`** — the style preset this script is written in (see *Style presets* below). It is a `#` comment, so [[explainer-audio-narrate]] ignores it as spoken text but reads it to pick the matching voices automatically. Always emit it.
- `A:` / `B:` (lowercase and full-width `：` also accepted) starts a turn.
- Lines without a prefix continue the current turn.
- `#` lines and blank lines are ignored.

## Spoken orientation

Every guide must identify itself in its first 2–4 spoken turns. The listener
must be able to determine, without seeing the filename or player UI:

- the book or document being discussed;
- whether this is an overview or a focused guide;
- the topic covered in this recording;
- what they should understand by the end.

Comments and metadata do not satisfy this requirement because they are not
spoken. Resolve the source title from an explicit document title, a title
provided by the caller, or a source heading, in that order. Do not invent a
title. If the source has no formal title, speak an accurate description that
identifies it.

For an overview, use this shape while adapting the wording to the source:

```text
A: 今回は『アジャイルデータモデリング』という本の全体像を見ていくのね。
B: そうなのだ。この本は、利用者との会話から分析用のデータモデルを作る方法を扱っているのだ。
A: 聞き終える頃には、テーブル設計より前に何を決めるべきか説明できるようになるのね。
B: そのために、まず従来の要件収集がなぜうまくいかないのかから考えるのだ。
```

For a focused guide, use this shape while adapting the wording to the source:

```text
A: 今回は『アジャイルデータモデリング』の中から、業務システムと分析システムの違いを掘り下げるのね。
B: そうなのだ。聞き終える頃には、同じデータでも目的によってモデルを分ける理由が分かるのだ。
A: では、正規化された業務データベースをそのまま分析に使えないのはなぜ？
B: そこから考えていくのだ。
```

Do not copy either example mechanically. Preserve the four required pieces of
information, but write an opening that belongs to the actual source and topic.

## Style presets (口調 & voices)

A **style preset** bundles a 口調 (how the two speakers talk) with the VOICEVOX voices [[explainer-audio-narrate]] uses to read them. Pick one up front — from the user's request, else default to `zundamon` — write the whole script in that 口調, and record it as the `# style:` marker.

| Preset | Speaker A (learner) | Speaker B (explainer) |
|--------|----------------------|-----------------------|
| `zundamon` *(default)* | 四国めたん調: フレンドリーな女の子口調。「〜わね」「〜かしら」「〜なの？」、一人称は「わたし」。 | ずんだもん調: 語尾を「〜のだ／〜なのだ」、疑問は「〜なのだ？」、一人称は「ボク」。素直で元気。 |
| `natural` | 普通のフレンドリー敬体（ですます）。 | 普通の解説者の敬体（ですます）。 |
| `formal` | 硬めの敬体・端正。 | 硬めの敬体・落ち着いた専門家。 |

- The **roles** (A=学習者 / B=解説者) are the same across presets; only the 口調 and voices change. The 口調 is cosmetic — the roles below are what make the script work.
- Keep the 口調 **consistent for the whole script** and apply it to both speakers. For `zundamon`, B ends most turns with 「〜のだ」系 and A uses the light「〜わね／かしら」register; don't let either drift back into plain 敬体.
- Character 口調 still follows the TTS-ready rules below (short turns, no markup, readable numbers/acronyms). Flavour is in sentence endings and word choice, not in heavy dialect.
- If the user names a preset or characters (e.g.「フォーマルで」「ずんだもんで解説して」), use it; if a matching preset does not exist, either map it to the closest one or add a new preset in both this skill and [[explainer-audio-narrate]] (the voice mapping lives there).

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

**Select, plan the friction, then script.** Do not write the script cold.

1. Apply `audio-guide-design.md` and record the source title, guide kind, spoken
   topic, listener destination, opening orientation, central hook, explanatory
   spine, selected evidence, and conversational acts in a private scratchpad.
2. For each act, plan **what a smart listener would plausibly get wrong** — the
   too-simple version, wrong analogy, or apparently skippable step. This is the
   fuel for A's 誤解の提示.
3. Mark where an abstraction needs one concrete example and a claim needs its
   representative evidence. Write the spoken orientation first, then the hook
   or central misconception, and close with the planned takeaway.

Only the final `A:`/`B:` script is written to the file; the scratchpad is scaffolding.

## The rest of the craft

- **Short turns, switch often.** Keep any single turn short — a few sentences, roughly **~100 characters per line as a cap**. Long monologues from B are the classic failure. (Note this is necessary, not sufficient: chopping a lecture into 100-char pieces and alternating them still fails the deletion test.)
- **Natural, but calibrated for TTS.** A little spoken texture helps, but go easy on fillers: VOICEVOX reads inserted 「えーと」「あの…」 awkwardly. Prefer naturally flowing phrasing over sprinkled filler words.
- **Faithful to the source.** Cover the source's real points; do not invent facts. A's misconceptions are *staged*, and B must correct them from the source — never invent a wrong fact that goes uncorrected.
- **Depth follows the guide design.** Keep the altitude and selected evidence established through `audio-guide-design.md`; dialogue must not pull discarded reference detail back in merely to create another exchange.
- **Spoken Japanese, TTS-ready.** No headings, bullets, markup, code blocks, or URLs read aloud. **Drop `[pNN]` page anchors.** Keep the register consistent with the chosen style preset. Gloss tricky readings, English acronyms, and ambiguous numbers so the TTS says them right.
- **Arc.** Open with a short spoken orientation, then move into the hook or central misconception. A content question is not an orientation unless it also tells the listener what source and topic they are hearing. Build from simpler to more complex; close with a short wrap-up and a final takeaway.

## Length is an outcome, not a target

**Do not write to a runtime.** The script is as long as the source's points and the listener's stumbling blocks require, and no longer. Padding to hit a number is how a script fills up with empty 相槌 and hollow exchanges — the exact defect this skill is built to prevent. **If the material only supports a tight 4 minutes, produce 4 minutes.** A short script that earns every exchange beats a 10-minute one that does not.

If the user *asks* for a length ("5分で", "15分くらい"), treat it as a **budget for how much of the source to cover** — cover fewer points more properly, or more points — not as a quota of turns to fill. Say so if the source cannot honestly fill the requested time.

For estimating only (not for targeting): at the default VOICEVOX rate Japanese audio runs **~340 characters/minute**, so ~3,200 spoken characters ≈ 10 minutes. Use this to *report* the expected duration, and to sanity-check that a requested length is achievable — never to inflate a script up to it.

Before handoff, apply `audio-guide-design.md`'s diagnostic check and report its
measurements. Revisit the content selection when warned; do not edit toward a
number at the expense of the explanatory spine.

## Standalone listening check

Read only the first four spoken turns without using the filename or surrounding
UI. Confirm that a listener can answer:

1. What source is this about?
2. Is this an overview or a focused guide?
3. What topic does this recording cover?
4. What should the listener understand by the end?

Rewrite the opening if any answer is missing or ambiguous. The opening sequence
is: identify the recording, state its listener destination, introduce the hook
or central misconception, then enter the main explanation.

## Hand off to synthesis

After writing the script, tell the user the script path and that [[explainer-audio-narrate]] can turn it into audio (or offer to run it). Do not synthesize audio here.

## Success criteria

- [ ] The first 2–4 spoken turns identify the source, guide kind, topic, and listener destination.
- [ ] The recording remains identifiable when played without its filename or surrounding UI.
- [ ] The opening orientation is spoken rather than stored only in comments.
- [ ] The hook follows the orientation instead of replacing it.
- [ ] **Passes the deletion test**: with all of A's turns removed, B's turns alone do NOT stand as a complete solo explanation — something load-bearing is lost. (If they do stand alone, the script is a lecture split in two: rewrite, don't ship.)
- [ ] A voices at least one **誤解の提示** or **言い換えの検算** that B corrects. A is wrong, or at least imprecise, somewhere.
- [ ] No turn by A consists solely of a reaction or a content-free prompt (「なるほど」「すごいわね」「次は？」).
- [ ] B's answers are visibly shaped by A's turns — B is responding, not reciting the next paragraph.
- [ ] A dialogue script file exists in the `A:`/`B:` format under `dialogue/`, parseable by [[explainer-audio-narrate]] (at least one `A:` and one `B:` turn).
- [ ] Content is faithful to the source; A's misconceptions are staged and always corrected, never left standing as fact.
- [ ] The `audio-guide-design.md` selection check passed before dialogue-specific checks were applied.
- [ ] Spoken characters, estimated duration, and source compression ratio were reported; warnings triggered a qualitative content-selection recheck rather than a forced runtime target.
- [ ] No markup, `[pNN]` anchors, or page-only artifacts remain in the spoken text.

## References

- `audio-guide-design.md` — the required guide-design procedure: listener
  destination, explanatory spine, content selection, altitude, pilot calibration,
  and diagnostic size check. *Read before writing every script.*
- `references.md` — the evidence base: why a second speaker earns its keep (vicarious-learning research), the Japanese explainer-dialogue genre's own move catalog (ゆっくり解説 / ずんだもん×めたん), and the NotebookLM/podcast sources for pacing and format. *Read when refining the dialogue-writing patterns.*
