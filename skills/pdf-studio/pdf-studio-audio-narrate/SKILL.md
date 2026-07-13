---
name: pdf-studio-audio-narrate
description: This skill should be used to synthesize an existing two-speaker dialogue script (台本, where each line is prefixed A:/B:) into a spoken audio file — the SECOND step of the audio-guide flow, after pdf-studio-audio-dialogue writes the script. Triggers on "台本を音声にして", "この対話を読み上げて / 音声化して", "音声ファイルを作って", "narrate this dialogue", "turn the script into audio", "synthesize the audio". Uses a local VOICEVOX ENGINE (offline, no API key) and encodes AAC/m4a with ffmpeg. Should NOT trigger for writing the dialogue script (use pdf-studio-audio-dialogue).
user-invocable: true
---

# Audio Narrate

Turn a two-speaker dialogue script into a single spoken audio file. This is the synthesis half of the audio-guide flow; [[pdf-studio-audio-dialogue]] writes the script this skill reads.

Synthesis uses a **local VOICEVOX ENGINE** — natural neural Japanese TTS from a plain HTTP server on `localhost` (no API key, fully offline). Each speaker gets a distinct character voice. The script uses `curl` to call the engine and Python 3 stdlib (`wave`) to stitch turns (no API keys). The stitched audio is then encoded to a compact **AAC/m4a** file with **`ffmpeg`** — cross-platform (Linux/macOS/Windows). `ffmpeg` is a required prerequisite for m4a output: the script checks for it up front and errors out if it is missing (no silent WAV fallback).

The script manages the engine for you: if one is already running it is reused, otherwise the script starts the engine, waits until it is ready, synthesizes, and stops that engine when done (it never stops an engine you were already running).

## When this applies

Use when a dialogue script in the `A:`/`B:` line format already exists — produced by [[pdf-studio-audio-dialogue]] or written by hand. If there is no script yet, run [[pdf-studio-audio-dialogue]] first.

The script format (also documented in [[pdf-studio-audio-dialogue]]):

- `A:` / `B:` (lowercase and full-width `：` accepted) starts a speaker turn.
- Lines without a prefix continue the current turn.
- `#` lines and blank lines are ignored.

## Setup — VOICEVOX ENGINE

This skill's synthesis is done by a **VOICEVOX ENGINE** — a local HTTP server. **It is an essential prerequisite: without it this skill cannot produce audio, and there is no fallback synthesizer.** It is free, offline, and needs no API key. Install it once; the bundled script starts/stops it as needed, and if the engine is neither running nor installable on `PATH` the script exits with an error explaining how to install it — relay that and stop, do not substitute another TTS.

- Install (Nix): `nix profile install nixpkgs#voicevox-engine`. Other install methods (the VOICEVOX app bundles the engine, or a standalone engine download) work too.
- The script auto-starts it via the `voicevox-engine` binary on `PATH` (override with `VOICEVOX_ENGINE_BIN`). If you prefer to keep an engine running yourself (`voicevox-engine` in a terminal), the script detects and reuses it.

## Procedure

Run the bundled script, giving the dialogue script path and an output path:

```sh
pdf-studio-audio-narrate/dialogue-to-audio.sh <script.txt> [output.m4a] [--play]
```

- If the output path is omitted, it defaults to the script path with an `.m4a` extension. The output format follows the extension you pass: `.m4a` encodes AAC (requires `ffmpeg`), any other extension writes WAV. Prerequisites (`python3`, `curl`, and `ffmpeg` for m4a) are checked up front, before the engine starts, so a missing tool fails fast.
- Write the audio into an `audio/` directory that sits beside the script's `dialogue/` directory: the script `<WORK_DIR>/dialogue/<slug>.txt` → audio `<WORK_DIR>/audio/<slug>.m4a`. Create `audio/` if missing. This keeps the editable script (`dialogue/`) separate from the disposable, re-synthesizable audio (`audio/`). Audio is re-synthesizable, but still don't silently clobber a file that's already there: if the target `<slug>.m4a` already exists, confirm before overwriting it.
- `--play` synthesizes and then plays the result with `afplay` (macOS).

> **Run without the command sandbox.** The script talks to a local VOICEVOX ENGINE over `localhost` (and spawns it when one isn't already running), which a command sandbox blocks. Invoke it with `dangerouslyDisableSandbox: true`. (The `ffmpeg` m4a encoding itself is self-contained and would run fine under a sandbox; it's the engine networking that needs it off.)

Report the output path and duration to the user.

## Voice styles (presets)

Voices come from a **STYLE preset** — a speaker pairing meant to match the script's 口調. The preset is chosen (highest priority first) from the `STYLE` env var, then a `# style: <preset>` marker line at the top of the script (written by [[pdf-studio-audio-dialogue]]), then the default.

| Preset | Speaker A (navigator) | Speaker B (explainer) | Pairs with 口調 |
|--------|----------------------|-----------------------|-----------------|
| `zundamon` *(default)* | 四国めたん / ノーマル (2) | ずんだもん / ノーマル (3) | めたん＆ずんだもん（「〜なのだ」） |
| `natural` | 四国めたん / ノーマル (2) | 青山龍星 / ノーマル (13) | 普通のフレンドリー敬体 |
| `formal` | No.7 / アナウンス (30) | 青山龍星 / しっとり (84) | 硬めの落ち着いた敬体 |

Because [[pdf-studio-audio-dialogue]] writes the matching `# style:` marker into the script, narration picks the right voices automatically — no need to pass `STYLE` yourself when narrating its output.

## Options

Override per run with environment variables:

```sh
STYLE=formal \
  pdf-studio-audio-narrate/dialogue-to-audio.sh script.txt out.m4a
```

| Var | Default | Meaning |
|-----|---------|---------|
| `VOICEVOX_URL` | `http://127.0.0.1:50021` | VOICEVOX ENGINE base URL |
| `VOICEVOX_ENGINE_BIN` | `voicevox-engine` | Engine binary used for auto-start |
| `STYLE` | *(marker → `zundamon`)* | Voice preset: `zundamon` / `natural` / `formal` |
| `SPEAKER_A` | *(from preset)* | Override speaker A **style id** |
| `SPEAKER_B` | *(from preset)* | Override speaker B **style id** |
| `SPEED` | `1.0` | `speedScale` applied to every turn |
| `PAUSE_MS` | `350` | Silence inserted between turns (ms) |
| `AAC_BITRATE` | `64k` | AAC bitrate for `.m4a` output (ffmpeg `-b:a`) |

`SPEAKER_A` / `SPEAKER_B` override the preset per speaker. List all speakers and their style IDs with `curl http://127.0.0.1:50021/speakers` — the engine ships 40+ characters, many with multiple emotional styles (ノーマル / あまあま / セクシー …).

## Requirements & notes

- Needs the **VOICEVOX ENGINE** installed (see Setup), plus `curl`, Python 3, and `ffmpeg` (for m4a). The script starts the engine when it is not already running and stops it afterward. The audio pipeline is cross-platform; the `--play` helper still uses macOS `afplay` when present, and the duration readout uses `ffprobe` (falling back to macOS `afinfo`).
- Output is **AAC/m4a** by default — far smaller than WAV (roughly 1/5 the size) and encoded with `ffmpeg` (cross-platform, no macOS-only tool). VOICEVOX returns 24 kHz mono 16-bit; ffmpeg keeps the input rate/channels, so the file stays 24 kHz mono (no wasteful upsampling). `ffmpeg` is required for m4a and its absence is a hard error (fail fast, no WAV fallback); pass an explicit `.wav` output path only if you deliberately want unencoded WAV.
- `AAC_BITRATE` (default `64k`) tunes size vs quality — 64 kbps is ample for 24 kHz mono speech.
- The `A:`/`B:` script format is backend-agnostic, so swapping in another TTS later (e.g. an API multi-speaker service) needs no change to [[pdf-studio-audio-dialogue]] output.

## Success criteria

- [ ] An audio file is produced from the script (non-empty m4a; or WAV only when a `.wav` output path was explicitly requested) and its path + duration are reported.
- [ ] Both speakers are voiced by distinct voices (`SPEAKER_A` ≠ `SPEAKER_B`).
- [ ] The script's turns are all present in order (no `A:`/`B:` turn silently dropped).
