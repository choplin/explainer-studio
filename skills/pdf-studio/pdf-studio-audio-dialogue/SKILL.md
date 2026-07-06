---
name: pdf-studio-audio-dialogue
description: This skill should be used when the user wants a NotebookLM-style audio guide / audio overview / two-host podcast of a document — specifically the FIRST step: writing the two-speaker dialogue script (台本). Triggers on "音声ガイドを作って", "この本の音声概要が欲しい", "ポッドキャスト風の対話にして", "NotebookLMみたいな音声を作りたい", "make an audio guide / audio overview", "turn this report into a two-host dialogue script". Works on any Markdown, especially pdf-studio output: reports/overview.md (whole-document overview → a broad guide) or a deep-dive reports/<section>.md report (one section → a focused, deeper guide). It writes a dialogue script file in the A:/B: line format that the pdf-studio-audio-narrate skill then turns into audio. Should NOT trigger for the audio synthesis step itself (use pdf-studio-audio-narrate), or for producing the source report (use pdf-studio-summarize / pdf-studio-deep-dive).
version: 0.1.0
user-invocable: true
---

# Audio Dialogue Script

Rewrite a Markdown document into a **two-host, podcast-style dialogue script** (台本) — the NotebookLM "audio overview" shape — as the first of two steps. This skill produces only the *script*; [[pdf-studio-audio-narrate]] turns that script into an audio file. Keeping the two apart lets the script be reviewed/edited before synthesis, and lets the audio backend change without touching how the dialogue is written.

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

`<slug>` names the source: `overview` for `reports/overview.md`, the section slug for a deep-dive report (e.g. `chapter-2`), otherwise the source basename. Create the `dialogue/` directory if missing. The dialogue script is the editable text artifact; keeping it apart from generated `audio/` (which is disposable and re-synthesizable) makes it easy to review and edit before narration.

## Dialogue script format

Plain text. One turn per speaker, prefixed with `A:` or `B:`. This is exactly what [[pdf-studio-audio-narrate]] consumes.

```
# style: zundamon
# Lines starting with '#' are comments and are ignored.
A: 今日はこのドキュメントの内容を、二人で紹介していくわね。
B: よろしくおねがいするのだ。まずは全体像から見ていくのだ。
A: 接頭辞のない行は、
   直前の話者の発話としてそのまま続きます。
```

- **First line: `# style: <preset>`** — the style preset this script is written in (see *Style presets* below). It is a `#` comment, so [[pdf-studio-audio-narrate]] ignores it as spoken text but reads it to pick the matching voices automatically. Always emit it.
- `A:` / `B:` (lowercase and full-width `：` also accepted) starts a turn.
- Lines without a prefix continue the current turn.
- `#` lines and blank lines are ignored.

## Style presets (口調 & voices)

A **style preset** bundles a 口調 (how the two speakers talk) with the VOICEVOX voices [[pdf-studio-audio-narrate]] uses to read them. Pick one up front — from the user's request, else default to `zundamon` — write the whole script in that 口調, and record it as the `# style:` marker.

| Preset | Speaker A (navigator) | Speaker B (explainer) |
|--------|----------------------|-----------------------|
| `zundamon` *(default)* | 四国めたん調: フレンドリーな女の子口調。「〜わね」「〜かしら」「〜なの？」、一人称は「わたし」。 | ずんだもん調: 語尾を「〜のだ／〜なのだ」、疑問は「〜なのだ？」、一人称は「ボク」。素直で元気。 |
| `natural` | 普通のフレンドリー敬体（ですます）。落ち着いた進行役。 | 普通の解説者の敬体（ですます）。 |
| `formal` | 硬めの敬体・アナウンサー的で端正。 | 硬めの敬体・落ち着いた専門家。 |

- The **roles** (A=進行役 / B=解説役) are the same across presets; only the 口調 and voices change.
- Keep the 口調 **consistent for the whole script** and apply it to both speakers. For `zundamon`, B ends most turns with 「〜のだ」系 and A uses the light「〜わね／かしら」register; don't let either drift back into plain 敬体.
- Character 口調 still follows the TTS-ready rules below (short turns, no markup, readable numbers/acronyms). Flavour is in sentence endings and word choice, not in heavy dialect.
- If the user names a preset or characters (e.g.「フォーマルで」「ずんだもんで解説して」), use it; if a matching preset does not exist, either map it to the closest one or add a new preset in both this skill and [[pdf-studio-audio-narrate]] (the voice mapping lives there).

## How to write the dialogue

**First brainstorm, then script (two stages).** Do not write the script cold. First jot a short private scratchpad — the source's 3–6 load-bearing points, a one-line angle/hook, and the order to walk them — then write the dialogue from that outline. This "scratchpad before script" step is what NotebookLM-style generators rely on to get past a flat recitation. The scratchpad is scaffolding; only the final `A:`/`B:` script is written to the file.

Then write turns following these patterns (distilled from NotebookLM teardowns, `podcastfy`, and `open-notebooklm`):

- **Asymmetric roles, not two clones.** Speaker **A** is the anchor/navigator: opens, asks the obvious question, handles transitions, and periodically recaps. Speaker **B** is the explainer/expert: carries the substance. A drives, B delivers. Keep the two voices distinct — interchangeable hosts are the flat-podcast failure mode.
- **Short turns, switch often.** Keep any single turn short — a few sentences, and roughly **~100 characters per line as a hard cap** (open-notebooklm enforces exactly this; a common spoken-podcast rule of thumb is ~30 seconds max per voice). Use **questions as the transitions** that move to the next topic. Long monologues are the main thing to avoid.
- **Not a Q&A metronome.** Break strict A-asks / B-answers: let B occasionally ask back, A add a point, or one host briefly react ("なるほど", "たしかに") before continuing. The three core moves are: summarize a point, connect it to another, and light back-and-forth.
- **Natural, but calibrated for TTS.** A little spoken texture (a short "なるほど" / "そうですね", a rhetorical question, an analogy) makes it feel human — but go easy on fillers/disfluencies: TTS reads inserted "えーと" / "あの…" awkwardly. Prefer naturally flowing phrasing over sprinkled filler words.
- **Faithful to the source, in source order.** Cover the source's real points; do not invent. It is a spoken *guide* to the material, not a new essay.
- **Depth follows the source.** An overview (`reports/overview.md`) → a broad tour that touches every top-level section lightly. A deep-dive report → go deep on that one part, keeping the specifics the source goes into (definitions, figures, mechanisms). Let the source's granularity set the guide's granularity.
- **Spoken Japanese, TTS-ready.** No headings, bullets, markup, code blocks, or URLs read aloud. **Drop `[pNN]` page anchors** and anything that only makes sense on the page. Keep the register consistent with the chosen **style preset** (see above — `natural`/`formal` use 敬体, `zundamon` uses the character 口調). Gloss or spell out tricky readings, English acronyms, and ambiguous numbers so the TTS says them right.
- **Arc.** Open with a one-line hook (what this is, why it matters); build from simpler to more complex; optionally a brief aside/"breather" midway; close with a short wrap-up and a final takeaway.
- **Length — default ~10 minutes; honor a requested length.** At the default VOICEVOX rate, Japanese audio runs **~340 characters/minute** (measured). Because turns are short (~100-char cap), hitting the target takes **many turns, not long ones — short turns ≠ a short program.** Budget the whole script to the target length:

  | Target | Spoken chars (labels excluded) | ~Turns total |
  | --- | --- | --- |
  | ~5 min | ~1,600 | ~25 (≈12/side) |
  | **~10 min (default)** | **~3,200** | **~50 (≈25/side)** |
  | ~15 min | ~4,800 | ~75 (≈37/side) |

  If the user names a length ("5分で", "15分くらい") or a size (short / standard / deep), scale to it; otherwise default to **~10 minutes (~50 turns)**. These assume the default narration rate — a lower `SPEED` in [[pdf-studio-audio-narrate]] stretches the duration proportionally. Still let the source cap it: don't pad thin material to reach a number — if the source can't fill the target, say so and produce what it genuinely supports.

## Hand off to synthesis

After writing the script, tell the user the script path and that [[pdf-studio-audio-narrate]] can turn it into audio (or offer to run it). Do not synthesize audio here.

## Success criteria

- [ ] A dialogue script file exists in the `A:`/`B:` format under `dialogue/`, parseable by [[pdf-studio-audio-narrate]] (at least one `A:` and one `B:` turn).
- [ ] Content is faithful to the source and covers it in order; depth matches the source type (overview → broad, deep-dive → deep).
- [ ] No markup, `[pNN]` anchors, or page-only artifacts remain in the spoken text.

## References

- `references.md` — the NotebookLM/podcast dialogue-technique sources these patterns distill (teardowns, `podcastfy`, `open-notebooklm`), with the VOICEVOX filler caveat. *Read when refining the dialogue-writing patterns.*
