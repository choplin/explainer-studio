# References — dialogue-script generation research

Evidence base for the "How to write the dialogue" guidance in [SKILL.md](./SKILL.md). Gathered
with a multi-source deep-research pass (fan-out web search → source extraction → 3-vote
adversarial verification) on 2026-07-03.

**Verification:** each claim was checked by 3 skeptical voters; `3-0` / `2-1` = confirmed,
`1-2` / `0-3` = refuted. Of 25 verified claims, **23 confirmed / 2 refuted**. (The workflow's
automated synthesis step failed and returned a placeholder, so this file was synthesized by hand
from the verified claim set — the underlying verification is intact.)

Source quality tags: **primary** = official docs / actual source code; **secondary** = derived
docs (e.g. deepwiki); **blog/forum** = practitioner write-ups.

---

## Verified findings

### 1. Two-host role structure (asymmetric)

- The two hosts have **complementary, non-interchangeable roles**. Podcastfy splits them as
  `roles_person1 = "main summarizer"` / `roles_person2 = "questioner/clarifier"`. `3-0`
  — [github.com/souzatharsis/podcastfy](https://github.com/souzatharsis/podcastfy) (primary)
- open-notebooklm frames it as a producer turning text into a two-speaker script where **the
  host "Jane" always initiates and interviews the guest** (the author/expert):
  > "You are a world-class podcast producer... the host (Jane)... always initiates the
  > conversation and interviews the guest... the author or an expert on the topic"
  `3-0` — [gabrielchua/open-notebooklm/prompts.py](https://github.com/gabrielchua/open-notebooklm/blob/main/prompts.py) (primary)
- The Together AI tutorial mirrors this: "Develop a natural, conversational flow between the host
  (Jane) and the guest speaker." `3-0`
  — [docs.together.ai](https://docs.together.ai/docs/open-notebooklm-pdf-to-podcast) (primary)

### 2. Dialogue arc / structure

- Podcastfy's default `dialogue_structure` is a three-part **Introduction → Main Content Summary
  → Conclusion** (an overridable config key). `3-0`
  — [podcastfy](https://github.com/souzatharsis/podcastfy) (primary)
- open-notebooklm's `SYSTEM_PROMPT` drives a fixed step sequence: **Analysis → Brainstorming →
  Dialogue Crafting → Key-Insight Summarization (woven into the closing) → Authenticity →
  Pacing**. `2-0`
  — [deepwiki: open-notebooklm system prompts](https://deepwiki.com/gabrielchua/open-notebooklm/7.2-system-prompts) (secondary)
- NotebookLM's Audio Overview follows a **recurring multi-turn loop**: one host sets up an idea,
  the other asks the obvious question, the first answers, the second reframes to move forward.
  `2-1` — [roballandale teardown](https://roballandale.com/briefs/notebooklm-audio-overviews-workflow-teardown/) (blog)
- Podcastfy mandates a **greeting-based intro and a Person1 goodbye outro**:
  > "ALWAYS START THE CONVERSATION GREETING THE AUDIENCE: Welcome to {podcast_name} -
  > {podcast_tagline}" ... "END THE CONVERSATION GREETING THE AUDIENCE WITH PERSON1 ALSO SAYING
  > A GOOD BYE MESSAGE"
  `3-0` — [podcastfy](https://github.com/souzatharsis/podcastfy) (primary)

### 3. Naturalization techniques

- NotebookLM's hosts perform three behaviors: **summarize the material, make connections between
  topics, and banter back and forth**:
  > "They summarize your material, make connections between topics, and banter back and forth."
  `2-1` — [blog.google](https://blog.google/technology/ai/notebooklm-audio-overviews/) (primary)
- Naturalness is **explicitly prompted**, not emergent — fillers + interruptions, flagged as
  important for authenticity:
  > "occasional verbal fillers (e.g., 'Uhh', 'Hmmm', 'um,' 'well,' 'you know')' ... 'natural
  > interruptions and back-and-forth between host and guest - this is very important to make the
  > conversation feel authentic"
  `3-0` — [together.ai](https://docs.together.ai/docs/open-notebooklm-pdf-to-podcast) (primary),
  corroborated by [open-notebooklm/prompts.py](https://github.com/gabrielchua/open-notebooklm/blob/main/prompts.py) (primary)
- A **deliberate disfluency stage** is applied late to keep the script from sounding like "two
  robots talking to each other." `2-1`
  — [simonwillison.net](https://simonwillison.net/2024/Sep/29/notebooklm-audio-overview/) (secondary)
- Podcastfy exposes reusable engagement knobs: `engagement_techniques = ["rhetorical questions",
  "anecdotes", "analogies", "humor"]`, `conversation_style = ["engaging", "fast-paced",
  "enthusiastic"]`, `creativity = 1`. `3-0`
  — [podcastfy](https://github.com/souzatharsis/podcastfy) (primary)

> ⚠️ TTS caveat: the sources above target neural TTS (Gemini/ElevenLabs) that renders "um/えーと"
> convincingly. VOICEVOX (used by [[pdf-studio-audio-narrate]]) reads inserted fillers less naturally, so keep
> fillers/disfluencies light — see SKILL.md.

### 4. Generation method (two-stage / multi-stage)

- **Scratchpad-before-script**: brainstorm framing in a `<scratchpad>` before writing dialogue.
  > "In the <scratchpad>, creatively brainstorm ways to present the key points engagingly."
  `3-0` — [open-notebooklm/prompts.py](https://github.com/gabrielchua/open-notebooklm/blob/main/prompts.py) (primary)
  > "the scratchpad field allows the LLM ... to generate an unstructured overview of the script
  > prior to generating a structured line by line enactment."
  `2-1` — [together.ai](https://docs.together.ai/docs/open-notebooklm-pdf-to-podcast) (primary)
- NotebookLM's own pipeline is **multi-stage** (outline → detailed script → critique/revise), not
  a single pass. `3-0`
  — [simonwillison.net](https://simonwillison.net/2024/Sep/29/notebooklm-audio-overview/) (secondary)

### 5. Length & pacing

- The generated script enforces a **hard per-line length cap** (open-notebooklm caps each dialogue
  line at roughly ~100 characters), keeping turns short. `3-0`
  — [open-notebooklm](https://github.com/gabrielchua/open-notebooklm/blob/main/prompts.py) /
  [together.ai](https://docs.together.ai/docs/open-notebooklm-pdf-to-podcast) (primary)
- Practitioner rule of thumb (supporting, not adversarially verified): **~30 seconds max of one
  voice** before switching, and **questions used as transitions** between hosts.
  — [lowerstreet.co](https://lowerstreet.co/how-to/write-podcast-script) (blog)

### 6. Output format

- Two-speaker scripts use **explicit per-line speaker labels**. Podcastfy uses `<Person1>` /
  `<Person2>` XML tags; open-notebooklm constrains speaker to a `Literal["Host (Jane)", "Guest"]`
  Pydantic field. `3-0`
  — [podcastfy](https://github.com/souzatharsis/podcastfy),
  [together.ai](https://docs.together.ai/docs/open-notebooklm-pdf-to-podcast) (primary)
- Gemini multi-speaker TTS expects the **same labeled-transcript convention** — "provide the model
  with each speaker's name and corresponding transcript" — and supports per-speaker style/tone/pace
  via natural-language prompts. `3-0`
  — [ai.google.dev/gemini-api/docs/speech-generation](https://ai.google.dev/gemini-api/docs/speech-generation) (primary)
  → This validates this plugin's `A:` / `B:` line format as backend-agnostic.

### 7. Japanese / TTS localization

- No claim on Japanese-specific dialogue conventions (敬体/常体, 呼称, フィラー表記) reached the
  verification bar — the localization angle mostly surfaced generic Japanese TTS-reading advice.
  The SKILL.md Japanese guidance (敬体 register, gloss tricky readings, drop page anchors) is a
  reasonable default, **not** a research-backed finding.
  — background: [speechcentral.net (日本語読み上げ)](https://speechcentral.net/ja/2025/04/18/) (blog)

---

## Refuted (deliberately NOT applied)

- ❌ "**Banter** framed as a *core naturalization technique*." `1-2` — over-formalizes a looser
  reality; only one secondary blog's inference backed it.
  (Note: banter as *one of three host functions* — summarize / connect / banter — is separately
  **confirmed** `2-1`; SKILL.md's "light back-and-forth as one of three core moves" reflects that.)
  — [blog.google](https://blog.google/technology/ai/notebooklm-audio-overviews/)
- ❌ "NotebookLM defines a **listener persona** and opens with a clear stage-setting overview."
  `0-3` — not supported by the cited source.
  — [simonwillison.net](https://simonwillison.net/2024/Sep/29/notebooklm-audio-overview/)

---

## Sources

| Source | Quality | Angle |
| --- | --- | --- |
| [blog.google — NotebookLM Audio Overviews](https://blog.google/technology/ai/notebooklm-audio-overviews/) | primary | NotebookLM analysis |
| [gabrielchua/open-notebooklm — prompts.py](https://github.com/gabrielchua/open-notebooklm/blob/main/prompts.py) | primary | OSS prompt |
| [deepwiki — open-notebooklm system prompts](https://deepwiki.com/gabrielchua/open-notebooklm/7.2-system-prompts) | secondary | OSS prompt |
| [souzatharsis/podcastfy](https://github.com/souzatharsis/podcastfy) | primary | OSS prompt |
| [Together AI — open-notebooklm PDF-to-podcast](https://docs.together.ai/docs/open-notebooklm-pdf-to-podcast) | primary | OSS prompt |
| [ai.google.dev — Gemini TTS](https://ai.google.dev/gemini-api/docs/speech-generation) | primary | TTS output format |
| [simonwillison.net — NotebookLM audio overview](https://simonwillison.net/2024/Sep/29/notebooklm-audio-overview/) | secondary | pipeline teardown |
| [roballandale — workflow teardown](https://roballandale.com/briefs/notebooklm-audio-overviews-workflow-teardown/) | blog | dialogue loop |
| [nicolehennig — reverse-engineering the system prompt](https://nicolehennig.com/notebooklm-reverse-engineering-the-system-prompt-for-audio-overviews/) | blog | NotebookLM analysis |
| [zarazhang — the magic of two (dual-host)](https://zarazhang.substack.com/p/the-magic-of-two-why-dual-host-podcasts) | blog | two-host craft |
| [pacific-content — co-hosts / double acts](https://pacific-content.com/double-acts-dynamic-duos-co-hosts/) | blog | two-host craft |
| [lowerstreet — write a podcast script](https://lowerstreet.co/how-to/write-podcast-script) | blog | pacing/craft |
| [castos — podcast script](https://castos.com/podcast-script/) | blog | craft |
| [thepodcasthost — intro/outro tips](https://www.thepodcasthost.com/presenting-your-podcast/podcast-intro-and-outro-tips/) | blog | intro/outro |
| [murf.ai — NotebookLM audio customization](https://murf.ai/blog/notebook-lm-audio-customization) | blog | customization |
| [speechcentral — 日本語読み上げ](https://speechcentral.net/ja/2025/04/18/) | blog | JA TTS reading |

*Method: 5 search angles, 18 sources fetched, 87 claims extracted, top 25 adversarially verified
(23 confirmed / 2 refuted).*
