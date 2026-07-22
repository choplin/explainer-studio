#!/usr/bin/env bash
# dialogue-to-audio.sh — Turn a two-speaker dialogue script into a single audio file
# using a local VOICEVOX ENGINE for natural neural Japanese TTS.
#
# The VOICEVOX ENGINE is a local HTTP server (no API key, offline). Install (Nix):
#   nix profile install nixpkgs#voicevox-engine
# Turns are synthesized with curl and stitched with Python 3 stdlib (`wave`).
#
# Final output is a compact AAC/m4a file, encoded with `ffmpeg` (cross-platform — works on
# Linux/macOS/Windows). ffmpeg is a hard prerequisite for m4a output: if it is missing the
# script errors out up front rather than falling back (pass an explicit `.wav` output path
# to skip AAC encoding). VOICEVOX is 24 kHz mono, so the AAC keeps that rate — see the
# encoding note near the bottom.
#
# Engine lifecycle: if a VOICEVOX ENGINE is already reachable at VOICEVOX_URL it is used and
# left running. Otherwise this script starts one (needs the `voicevox-engine` binary on PATH,
# or VOICEVOX_ENGINE_BIN), waits until it is ready, and stops that engine when it finishes —
# only the engine it started, never one you were already running.
#
# Dialogue script format (plain text / markdown):
#   - A line beginning with "A:" or "B:" starts a turn for that speaker.
#   - Following lines without a speaker prefix continue the current turn.
#   - Lines starting with "#" are comments and are ignored.
#   - Blank lines are ignored (turn boundaries come from the speaker prefix).
# Example:
#   A: 今日は分散データベースの話をします。
#   B: よろしくお願いします。まずは概要から。
#
# Usage:
#   ./dialogue-to-audio.sh <script.txt> [output.m4a|output.wav] [--play]
#
# Voices come from a STYLE preset (a voice pairing that matches a script 口調):
#   zundamon  A=四国めたん(2)          B=ずんだもん(3)          [default]
#   natural   A=四国めたん(2)          B=青山龍星(13)
#   formal    A=No.7/アナウンス(30)  B=青山龍星/しっとり(84)
# The style is taken from $STYLE, else a '# style: <preset>' marker line in the script,
# else the default. $SPEAKER_A / $SPEAKER_B override the preset's picks per speaker.
#
# Env (speaker values are VOICEVOX *style IDs*; see `curl $VOICEVOX_URL/speakers`):
#   VOICEVOX_URL         VOICEVOX ENGINE base URL (default: http://127.0.0.1:50021)
#   VOICEVOX_ENGINE_BIN  engine binary used for auto-start (default: voicevox-engine on PATH)
#   STYLE                voice preset: zundamon | natural | formal
#   SPEAKER_A            override speaker A style id
#   SPEAKER_B            override speaker B style id
#   SPEED                speedScale applied to every turn (default: 1.0)
#   PAUSE_MS             silence inserted between turns, milliseconds (default: 350)
#   AAC_BITRATE          AAC bitrate for m4a output, passed to ffmpeg -b:a (default: 64k)
set -euo pipefail

VOICEVOX_URL="${VOICEVOX_URL:-http://127.0.0.1:50021}"
VOICEVOX_ENGINE_BIN="${VOICEVOX_ENGINE_BIN:-voicevox-engine}"
STYLE="${STYLE:-}"
SPEAKER_A="${SPEAKER_A:-}"
SPEAKER_B="${SPEAKER_B:-}"
SPEED="${SPEED:-1.0}"
PAUSE_MS="${PAUSE_MS:-350}"
AAC_BITRATE="${AAC_BITRATE:-64k}"

die() { echo "error: $*" >&2; exit 1; }

[ $# -ge 1 ] || die "usage: $0 <script.txt> [output.m4a|output.wav] [--play]"
SCRIPT="$1"; shift
[ -f "$SCRIPT" ] || die "script not found: $SCRIPT"

OUT=""
PLAY=0
for arg in "$@"; do
  case "$arg" in
    --play) PLAY=1 ;;
    *)      OUT="$arg" ;;
  esac
done
# Output format follows the extension: '.m4a' (default) encodes AAC, any other writes WAV.
if [ -z "$OUT" ]; then
  OUT="${SCRIPT%.*}.m4a"
fi

# --- Prerequisites (fail fast, before starting the engine) ----------------------
command -v python3 >/dev/null 2>&1 || die "'python3' not found"
command -v curl >/dev/null 2>&1 || die "'curl' not found"
# m4a output requires ffmpeg — check up front rather than after synthesizing.
case "$OUT" in
  *.m4a|*.M4A)
    command -v ffmpeg >/dev/null 2>&1 || die \
      "'.m4a' output needs 'ffmpeg' (not found) — install ffmpeg or pass a '.wav' output path to skip AAC encoding"
    ;;
esac

# --- Resolve the STYLE preset into speaker ids ----------------------------------
# style: $STYLE env > '# style: <preset>' marker in the script > default.
marker_style="$(grep -m1 -iE '^[[:space:]]*#[[:space:]]*style[[:space:]]*:' "$SCRIPT" 2>/dev/null \
  | cut -d: -f2- | tr -d '[:space:]' | tr 'A-Z' 'a-z' || true)"
style="${STYLE:-${marker_style:-zundamon}}"
style="$(printf '%s' "$style" | tr 'A-Z' 'a-z')"
case "$style" in
  zundamon) def_a=2;  def_b=3  ;;   # 四国めたん / ずんだもん
  natural)  def_a=2;  def_b=13 ;;   # 四国めたん / 青山龍星
  formal)   def_a=30; def_b=84 ;;   # No.7(アナウンス) / 青山龍星(しっとり)
  *) die "unknown STYLE: '$style' (expected zundamon | natural | formal)" ;;
esac
# Explicit SPEAKER_A / SPEAKER_B override the preset per speaker.
SPEAKER_A="${SPEAKER_A:-$def_a}"
SPEAKER_B="${SPEAKER_B:-$def_b}"
echo "style: $style  (A=$SPEAKER_A B=$SPEAKER_B)" >&2

WORK="$(mktemp -d)"
ENGINE_PID=""            # set only when this script starts the engine
cleanup() {
  if [ -n "$ENGINE_PID" ]; then
    echo "stopping VOICEVOX ENGINE (pid $ENGINE_PID)" >&2
    kill "$ENGINE_PID" 2>/dev/null || true
    wait "$ENGINE_PID" 2>/dev/null || true
  fi
  rm -rf "$WORK"
}
trap cleanup EXIT

engine_up() { curl -s -m 2 "$VOICEVOX_URL/version" >/dev/null 2>&1; }

# --- Ensure a VOICEVOX ENGINE is available --------------------------------------
# Reuse an already-running engine (leave it alone); otherwise start our own and stop
# it on exit via the cleanup trap.
if engine_up; then
  echo "using already-running VOICEVOX ENGINE at $VOICEVOX_URL" >&2
else
  command -v "$VOICEVOX_ENGINE_BIN" >/dev/null 2>&1 || die \
"no VOICEVOX ENGINE at $VOICEVOX_URL and '$VOICEVOX_ENGINE_BIN' not on PATH.
  Install (Nix): nix profile install nixpkgs#voicevox-engine
  Or set VOICEVOX_ENGINE_BIN=/path/to/voicevox-engine"

  # Derive host/port from VOICEVOX_URL (e.g. http://127.0.0.1:50021).
  hostport="${VOICEVOX_URL#*://}"; hostport="${hostport%%/*}"
  host="${hostport%%:*}"
  port="${hostport##*:}"; [ "$port" = "$hostport" ] && port=50021

  echo "starting VOICEVOX ENGINE ($VOICEVOX_ENGINE_BIN) on $host:$port ..." >&2
  "$VOICEVOX_ENGINE_BIN" --host "$host" --port "$port" >"$WORK/engine.log" 2>&1 &
  ENGINE_PID=$!

  # Wait until it answers (or the process dies).
  ready=0
  for _ in $(seq 1 60); do
    if ! kill -0 "$ENGINE_PID" 2>/dev/null; then
      echo "--- engine log ---" >&2; cat "$WORK/engine.log" >&2
      die "VOICEVOX ENGINE exited during startup"
    fi
    if engine_up; then ready=1; break; fi
    sleep 1
  done
  [ "$ready" = 1 ] || { echo "--- engine log ---" >&2; cat "$WORK/engine.log" >&2; \
    die "VOICEVOX ENGINE did not become ready within 60s"; }
  echo "VOICEVOX ENGINE ready (pid $ENGINE_PID)" >&2
fi

# --- Per-turn synthesis ---------------------------------------------------------
# synth <style-id> <text> <out.wav>
synth() {
  local sid="$1" text="$2" out="$3"
  local q="$WORK/q.json"
  curl -s -m 60 -X POST "$VOICEVOX_URL/audio_query?speaker=$sid" \
    --get --data-urlencode "text=$text" -o "$q" \
    || die "audio_query failed (speaker=$sid)"
  [ -s "$q" ] || die "empty audio_query response (speaker=$sid) — bad style id?"
  # Apply SPEED to speedScale in the query.
  if [ "$SPEED" != "1.0" ]; then
    python3 - "$q" "$SPEED" <<'PY'
import sys, json
p, speed = sys.argv[1], float(sys.argv[2])
d = json.load(open(p))
d["speedScale"] = speed
json.dump(d, open(p, "w"))
PY
  fi
  curl -s -m 120 -X POST "$VOICEVOX_URL/synthesis?speaker=$sid" \
    -H 'Content-Type: application/json' -d @"$q" -o "$out" \
    || die "synthesis failed (speaker=$sid)"
  [ -s "$out" ] || die "empty synthesis output (speaker=$sid)"
}

# --- Parse the dialogue into per-turn segments ----------------------------------
seglist="$WORK/segs.txt"
: > "$seglist"

idx=0
cur_kind=""     # A or B
cur_text=""

flush_turn() {
  [ -n "$cur_kind" ] || return 0
  [ -n "${cur_text// /}" ] || { cur_kind=""; cur_text=""; return 0; }
  local seg sid
  seg="$(printf '%s/seg_%04d.wav' "$WORK" "$idx")"
  [ "$cur_kind" = A ] && sid="$SPEAKER_A" || sid="$SPEAKER_B"
  synth "$sid" "$cur_text" "$seg"
  printf '%s\n' "$seg" >> "$seglist"
  idx=$((idx + 1))
  cur_kind=""
  cur_text=""
}

while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    \#*) continue ;;            # comment
  esac
  if [[ "$line" =~ ^[[:space:]]*([AaBb])[:：][[:space:]]*(.*)$ ]]; then
    flush_turn
    case "${BASH_REMATCH[1]}" in
      A|a) cur_kind=A ;;
      B|b) cur_kind=B ;;
    esac
    cur_text="${BASH_REMATCH[2]}"
  else
    [ -n "$cur_kind" ] || continue
    [ -n "${line// /}" ] || continue
    cur_text="$cur_text $line"
  fi
done < "$SCRIPT"
flush_turn

[ -s "$seglist" ] || die "no dialogue turns found — check the A:/B: prefixes in $SCRIPT"

# --- Concatenate segments with inter-turn silence (Python stdlib wave) ----------
# Merge into an intermediate WAV; the final encode step below turns it into m4a.
MERGED="$WORK/merged.wav"
python3 - "$seglist" "$MERGED" "$PAUSE_MS" <<'PY'
import sys, wave

seglist, out_path, pause_ms = sys.argv[1], sys.argv[2], int(sys.argv[3])
paths = [l.strip() for l in open(seglist) if l.strip()]
if not paths:
    sys.exit("no segments to merge")

with wave.open(out_path, "wb") as out:
    params = None
    silence = b""
    for i, p in enumerate(paths):
        with wave.open(p, "rb") as r:
            if params is None:
                params = r.getparams()
                out.setparams(params)
                frames = int(params.framerate * pause_ms / 1000)
                silence = b"\x00" * (frames * params.sampwidth * params.nchannels)
            if i:
                out.writeframes(silence)
            out.writeframes(r.readframes(r.getnframes()))
print(f"merged {len(paths)} turns")
PY

# --- Encode the merged WAV to the requested output format -----------------------
# m4a (AAC) shrinks the file a lot vs WAV. VOICEVOX is ALWAYS 24 kHz mono; ffmpeg keeps the
# input rate/channels (no resample flags), so the AAC stays 24 kHz mono — upsampling would
# only inflate size with no quality gain. AAC_BITRATE tunes size/quality (64k is ample for
# 24 kHz mono speech). ffmpeg's presence was already verified up front for '.m4a' outputs.
case "$OUT" in
  *.m4a|*.M4A)
    ffmpeg -hide_banner -loglevel error -nostdin -y \
      -i "$MERGED" -c:a aac -b:a "$AAC_BITRATE" -movflags +faststart "$OUT" \
      || die "ffmpeg failed encoding m4a"
    ;;
  *)
    mv "$MERGED" "$OUT"
    ;;
esac
echo "wrote $OUT" >&2

# --- Report duration ------------------------------------------------------------
# Prefer ffprobe (cross-platform, ships with ffmpeg); fall back to macOS afinfo.
dur=""
if command -v ffprobe >/dev/null 2>&1; then
  dur="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT" 2>/dev/null)"
elif command -v afinfo >/dev/null 2>&1; then
  dur="$(afinfo "$OUT" 2>/dev/null | awk -F'[ ]' '/estimated duration/{print $3}')"
fi
[ -n "${dur:-}" ] && printf 'duration: %.1f sec\n' "$dur"
echo "output: $OUT"

if [ "$PLAY" -eq 1 ]; then
  command -v afplay >/dev/null 2>&1 && afplay "$OUT"
fi
