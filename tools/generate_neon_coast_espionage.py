#!/usr/bin/env python3
"""Generate an original late-1980s nocturnal espionage gameplay loop.

All musical material and every sound are synthesized locally. No samples,
recordings, or third-party melodies are used. The deterministic seed makes the
render reproducible. The 48-bar arrangement is exactly loopable at 101 BPM.
"""

import math
import random
import struct
import subprocess
import tempfile
import wave
from pathlib import Path


SR = 44_100
BPM = 101
BEAT = 60.0 / BPM
BAR = BEAT * 4.0
BARS = 48
DURATION = BAR * BARS
SAMPLES = round(DURATION * SR)
ROOT = Path(__file__).resolve().parents[1]
OGG_OUTPUT = ROOT / "assets/music/neon_coast_espionage_loop.ogg"

random.seed(19890417)
left = [0.0] * SAMPLES
right = [0.0] * SAMPLES

SEMITONES = {
    "C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5,
    "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11,
}


def frequency(note):
    if isinstance(note, (int, float)):
        return float(note)
    octave = int(note[-1])
    midi = 12 * (octave + 1) + SEMITONES[note[:-1]]
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def pan_gains(pan):
    return math.sqrt((1.0 - pan) * 0.5), math.sqrt((1.0 + pan) * 0.5)


def envelope(t, duration, attack, decay, sustain, release):
    if t < 0.0 or t >= duration:
        return 0.0
    if t < attack:
        return t / max(attack, 1e-6)
    if t < attack + decay:
        return 1.0 - (1.0 - sustain) * (t - attack) / max(decay, 1e-6)
    if t > duration - release:
        return sustain * max(0.0, (duration - t) / max(release, 1e-6))
    return sustain


def oscillator(kind, phase):
    if kind == "bass":
        return math.sin(phase) + 0.31 * math.sin(2 * phase) + 0.09 * math.sin(3 * phase)
    if kind == "poly":
        return (math.sin(phase) + 0.27 * math.sin(2 * phase)
                + 0.12 * math.sin(3 * phase) + 0.05 * math.sin(5 * phase))
    if kind == "pad":
        return math.sin(phase) + 0.18 * math.sin(2 * phase) + 0.07 * math.sin(4 * phase)
    if kind == "glass":
        return (math.sin(phase) + 0.38 * math.sin(2.013 * phase)
                + 0.19 * math.sin(3.997 * phase) + 0.07 * math.sin(6.031 * phase))
    if kind == "lead":
        return (math.sin(phase) + 0.34 * math.sin(2 * phase)
                + 0.13 * math.sin(3 * phase) + 0.045 * math.sin(4 * phase))
    if kind == "tom":
        return math.sin(phase) + 0.12 * math.sin(2 * phase)
    return math.sin(phase)


def add_note(start, duration, note, amplitude, pan=0.0, kind="lead",
             attack=0.01, decay=0.08, sustain=0.7, release=0.14,
             vibrato=0.0, vibrato_rate=5.1, detune=0.0):
    freq = frequency(note) * 2.0 ** (detune / 1200.0)
    first = max(0, int(start * SR))
    last = int((start + duration) * SR)
    gain_l, gain_r = pan_gains(pan)
    phase_offset = random.random() * math.tau
    for index in range(first, last):
        t = index / SR - start
        phase = math.tau * freq * t + phase_offset
        if vibrato:
            phase += vibrato * math.sin(math.tau * vibrato_rate * t)
        value = oscillator(kind, phase) * envelope(
            t, duration, attack, decay, sustain, release) * amplitude
        target = index % SAMPLES
        left[target] += value * gain_l
        right[target] += value * gain_r


def add_noise(start, duration, amplitude, pan=0.0, brightness=1.0,
              attack=0.002, release=0.08):
    first = max(0, int(start * SR))
    last = min(SAMPLES, int((start + duration) * SR))
    gain_l, gain_r = pan_gains(pan)
    previous = 0.0
    for index in range(first, last):
        t = index / SR - start
        raw = random.random() * 2.0 - 1.0
        shaped = raw * brightness + previous * (1.0 - brightness)
        previous = shaped
        env = envelope(t, duration, attack, 0.012, 0.32, release)
        left[index] += shaped * amplitude * env * gain_l
        right[index] += shaped * amplitude * env * gain_r


def add_kick(start, amplitude=0.14):
    duration = 0.31
    first = int(start * SR)
    last = min(SAMPLES, int((start + duration) * SR))
    phase = 0.0
    for index in range(first, last):
        t = index / SR - start
        freq = 44.0 + 92.0 * math.exp(-t * 30.0)
        phase += math.tau * freq / SR
        click = (random.random() * 2.0 - 1.0) * math.exp(-t * 70.0) * 0.08
        value = (math.sin(phase) + click) * amplitude * math.exp(-t * 12.5)
        left[index] += value * 0.707
        right[index] += value * 0.707


def add_snare(start, amplitude=0.064):
    # Short, restrained gated tail rather than a large arena snare.
    add_noise(start, 0.19, amplitude, -0.04, 0.88, release=0.115)
    add_note(start, 0.145, 178.0, amplitude * 0.34, 0.05, "tom",
             attack=0.001, decay=0.035, sustain=0.10, release=0.09)


def add_tom(start, note, amplitude=0.045, pan=0.0):
    add_note(start, 0.24, note, amplitude, pan, "tom",
             attack=0.002, decay=0.04, sustain=0.22, release=0.16)


def add_lead(start, duration, note, amplitude=0.030, pan=0.05):
    # Expressive mono-style lead: one centered voice, subtle chorus and delay.
    add_note(start, duration, note, amplitude, pan, "lead",
             attack=0.026, decay=0.10, sustain=0.69, release=0.19,
             vibrato=0.021, vibrato_rate=5.25)
    add_note(start + 0.010, duration, note, amplitude * 0.27, pan - 0.21, "lead",
             attack=0.030, decay=0.10, sustain=0.62, release=0.19,
             vibrato=0.014, vibrato_rate=4.91, detune=-6.0)
    delay = 0.75 * BEAT
    if start + delay < DURATION:
        add_note(start + delay, duration * 0.68, note, amplitude * 0.13,
                 0.38, "lead", attack=0.024, decay=0.08,
                 sustain=0.52, release=0.16, detune=3.0)


# F minor with a chromatic flat-II color. The suspended dominant keeps the
# repeating cycle unsettled instead of creating a conclusive cadence.
PROGRESSION = [
    (["F3", "G3", "G#3", "C4", "D#4"], "F2", "C3"),       # Fm9
    (["C#3", "F3", "G#3", "C4"], "C#2", "G#2"),           # Dbmaj7
    (["D#3", "G3", "G#3", "C4"], "D#2", "G#2"),           # Ab/Eb color
    (["D#3", "F3", "A#3", "C4"], "D#2", "A#2"),          # Eb6/9
    (["A#2", "C3", "F3", "G#3"], "A#1", "F2"),            # Bbm7(add9)
    (["F#3", "A#3", "C#4", "F4"], "F#2", "C#3"),         # Gbmaj7
    (["C3", "F3", "G3", "A#3"], "C2", "G2"),             # Csus7
    (["C3", "F3", "G3", "C4"], "C2", "G2"),              # unresolved C11
]


# Warm polysynth and an airier pad. The final eight bars reuse compatible
# harmony/density so the loop boundary feels like continuation, not restart.
for bar in range(BARS):
    chord, _, _ = PROGRESSION[bar % 8]
    start = bar * BAR
    breakdown = 28 <= bar < 36
    level = 0.012 if bar < 4 else (0.009 if breakdown else 0.015)
    for voice, note in enumerate(chord):
        pan = -0.48 + voice * (0.96 / max(1, len(chord) - 1))
        add_note(start, BAR * 1.035, note, level, pan, "poly",
                 attack=0.16, decay=0.24, sustain=0.70, release=0.31,
                 detune=-3.5)
        add_note(start + 0.011, BAR * 1.035, note, level * 0.55, -pan, "pad",
                 attack=0.34, decay=0.30, sustain=0.66, release=0.42,
                 detune=4.5)


# Deep syncopated bass begins immediately but leaves breathing room.
for bar in range(BARS):
    _, root, fifth = PROGRESSION[bar % 8]
    start = bar * BAR
    breakdown = 28 <= bar < 36
    sparse = bar < 4 or bar >= 44
    pattern = [
        (0.0, root, 0.56), (0.75, root, 0.34), (1.50, fifth, 0.37),
        (2.25, root, 0.48), (3.00, fifth, 0.30), (3.55, root, 0.28),
    ]
    if sparse:
        pattern = [pattern[index] for index in (0, 2, 3, 5)]
    elif breakdown:
        pattern = [pattern[index] for index in (0, 3, 4)]
    for beat_pos, note, length in pattern:
        add_note(start + beat_pos * BEAT, length * BEAT, note,
                 0.050 if not breakdown else 0.037, -0.08, "bass",
                 attack=0.007, decay=0.065, sustain=0.61, release=0.085)


# Vintage drum-machine groove: controlled and lightly syncopated.
for bar in range(4, BARS):
    if 28 <= bar < 32 or bar >= 46:
        continue
    start = bar * BAR
    restrained = 32 <= bar < 36 or bar >= 44
    for beat_pos in ((0.0, 2.0) if restrained else (0.0, 1.75, 2.75)):
        add_kick(start + beat_pos * BEAT, 0.125 if restrained else 0.145)
    for beat_pos in (1.0, 3.0):
        add_snare(start + beat_pos * BEAT, 0.055 if restrained else 0.066)
    for eighth in range(8):
        if restrained and eighth % 2:
            continue
        pan = 0.27 if eighth % 2 else -0.23
        accent = 0.012 if eighth in (2, 6) else 0.0085
        add_noise(start + eighth * 0.5 * BEAT, 0.055, accent, pan, 0.95,
                  release=0.035)
    if bar in (11, 19, 27, 43):
        for step, note in enumerate(("F2", "G#2", "C3")):
            add_tom(start + (3.0 + step * 0.31) * BEAT, note,
                    0.036 + step * 0.004, -0.32 + step * 0.32)


# Glassy digital accents, sparse enough to remain gameplay-friendly.
GLASS_PATTERN = [(0.50, 1), (1.50, 3), (2.50, 2), (3.50, 4)]
for bar in range(6, 44):
    if 28 <= bar < 34 or bar % 2:
        continue
    chord = PROGRESSION[bar % 8][0]
    for beat_pos, chord_index in GLASS_PATTERN:
        note = chord[chord_index % len(chord)]
        high_note = note[:-1] + str(int(note[-1]) + 1)
        add_note(bar * BAR + beat_pos * BEAT, 0.24 * BEAT, high_note,
                 0.0105, -0.36 if chord_index % 2 else 0.36, "glass",
                 attack=0.003, decay=0.055, sustain=0.22, release=0.10)


# Entirely original four-bar motif: an oblique upward signal followed by a
# descending answer. It first appears only after the groove is established.
MOTIF = [
    (0, "C5", 0.25, 0.58), (0, "D#5", 1.00, 0.36),
    (0, "G#5", 1.55, 0.62), (0, "G5", 2.55, 0.34),
    (0, "F5", 3.08, 0.64),
    (1, "C#5", 0.35, 0.48), (1, "F5", 1.10, 0.39),
    (1, "G#5", 1.72, 0.54), (1, "D#5", 2.75, 0.72),
    (2, "C5", 0.18, 0.55), (2, "G#4", 1.02, 0.38),
    (2, "A#4", 1.62, 0.52), (2, "F5", 2.50, 0.43),
    (2, "D#5", 3.13, 0.58),
    (3, "G4", 0.35, 0.48), (3, "A#4", 1.08, 0.35),
    (3, "C5", 1.66, 0.72), (3, "G4", 2.80, 0.64),
]


def place_motif(first_bar, level=1.0, transpose_octave=False):
    for offset, note, beat_pos, length in MOTIF:
        if transpose_octave and (offset + int(beat_pos)) % 3 == 0:
            note = note[:-1] + str(int(note[-1]) - 1)
        add_lead((first_bar + offset) * BAR + beat_pos * BEAT,
                 length * BEAT, note, 0.0285 * level)


place_motif(8, 0.92)
place_motif(20, 0.78, transpose_octave=True)
place_motif(36, 1.05)


# Restrained countermelody under later motif statements.
COUNTER = [
    (0, "F4", 0.0, 0.88), (0, "G#4", 1.42, 0.46), (0, "A#4", 2.42, 0.65),
    (1, "G#4", 0.12, 0.70), (1, "F4", 1.38, 0.46), (1, "D#4", 2.60, 0.75),
    (2, "C#4", 0.18, 0.78), (2, "D#4", 1.55, 0.48), (2, "F4", 2.62, 0.66),
    (3, "C4", 0.22, 0.72), (3, "D#4", 1.45, 0.46), (3, "G4", 2.42, 0.76),
]
for first_bar, level in ((20, 0.50), (36, 0.64)):
    for offset, note, beat_pos, length in COUNTER:
        add_note((first_bar + offset) * BAR + beat_pos * BEAT,
                 length * BEAT, note, 0.020 * level, -0.26, "poly",
                 attack=0.055, decay=0.11, sustain=0.56, release=0.19)


# Breakdown signal: fragmented and distant, leaving room before the return.
for offset, note, beat_pos, length in [
    (0, "C5", 0.50, 0.72), (1, "G#4", 1.50, 0.65),
    (2, "F4", 0.75, 0.90), (3, "C5", 2.25, 0.62),
    (4, "C#5", 0.50, 0.68), (5, "D#5", 1.75, 0.58),
    (6, "C5", 0.75, 0.72), (7, "G4", 2.00, 0.75),
]:
    add_note((28 + offset) * BAR + beat_pos * BEAT, length * BEAT,
             note, 0.013, 0.22, "glass", attack=0.008, decay=0.10,
             sustain=0.28, release=0.32)


# Low-level coastal ambience and tape hiss. Long, dark noise is intentionally
# subtle; it is seam-smoothed during mastering below.
add_noise(0.0, DURATION, 0.0025, -0.30, 0.025, attack=0.01, release=0.01)
add_noise(0.0, DURATION, 0.0022, 0.33, 0.020, attack=0.01, release=0.01)
add_noise(0.0, DURATION, 0.00085, 0.0, 0.72, attack=0.01, release=0.01)


# Gentle tape-style saturation. Notes that cross the bar-48 boundary are
# rendered circularly into bar one, so there is no fade-out or seam edit.
peak = max(max(abs(value) for value in left), max(abs(value) for value in right), 1e-9)
gain = 0.79 / peak
processed_l = [math.tanh(value * gain * 1.18) for value in left]
processed_r = [math.tanh(value * gain * 1.18) for value in right]

pcm = bytearray()
for sample_l, sample_r in zip(processed_l, processed_r):
    pcm.extend(struct.pack(
        "<hh",
        int(max(-1.0, min(1.0, sample_l)) * 32767),
        int(max(-1.0, min(1.0, sample_r)) * 32767),
    ))

OGG_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory() as temp_dir:
    wav_output = Path(temp_dir) / "neon_coast_espionage_loop.wav"
    with wave.open(str(wav_output), "wb") as wav_file:
        wav_file.setnchannels(2)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SR)
        wav_file.writeframes(pcm)

    subprocess.run([
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-i", str(wav_output), "-codec:a", "vorbis", "-strict", "experimental", "-q:a", "6",
        "-metadata", "title=Neon Coast Espionage",
        "-metadata", "artist=Lobster Clicker",
        "-metadata", "comment=Original synthesized gameplay loop; 101 BPM; F minor",
        str(OGG_OUTPUT),
    ], check=True)

print(f"Generated {OGG_OUTPUT} ({DURATION:.2f}s, {BPM} BPM)")
