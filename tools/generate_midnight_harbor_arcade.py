#!/usr/bin/env python3
"""Generate Lobster Clicker's original nautical synthwave game loop.

Every sound is synthesized locally; no samples, recordings, or third-party
musical material are used. The deterministic seed makes the shipped asset
reproducible.
"""

import math
import random
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

SR = 44100
BPM = 108
BEAT = 60.0 / BPM
BAR = BEAT * 4.0
BARS = 32
DURATION = BAR * BARS
SAMPLES = int(DURATION * SR)
ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/music/midnight_harbor_arcade_loop.ogg"

random.seed(1986)
left = [0.0] * SAMPLES
right = [0.0] * SAMPLES

SEMITONES = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5,
             "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def frequency(note):
    if isinstance(note, (int, float)):
        return float(note)
    octave = int(note[-1])
    midi = 12 * (octave + 1) + SEMITONES[note[:-1]]
    return 440.0 * (2.0 ** ((midi - 69) / 12.0))


def pan_gains(pan):
    return math.sqrt((1.0 - pan) * 0.5), math.sqrt((1.0 + pan) * 0.5)


def envelope(t, duration, attack=0.01, decay=0.08, sustain=0.72, release=0.16):
    if t < 0.0 or t >= duration:
        return 0.0
    if t < attack:
        return t / max(attack, 1e-6)
    if t < attack + decay:
        return 1.0 - (1.0 - sustain) * ((t - attack) / max(decay, 1e-6))
    if t > duration - release:
        return sustain * max(0.0, (duration - t) / max(release, 1e-6))
    return sustain


def oscillator(kind, phase):
    if kind == "bass":
        return math.sin(phase) + 0.24 * math.sin(2 * phase) + 0.08 * math.sin(3 * phase)
    if kind == "pad":
        return (math.sin(phase) + 0.32 * math.sin(2 * phase) +
                0.14 * math.sin(3 * phase) + 0.06 * math.sin(5 * phase))
    if kind == "pluck":
        return (math.sin(phase) + 0.42 * math.sin(2 * phase) +
                0.18 * math.sin(3 * phase) + 0.08 * math.sin(4 * phase))
    if kind == "lead":
        return (math.sin(phase) + 0.38 * math.sin(2 * phase) +
                0.18 * math.sin(3 * phase) + 0.07 * math.sin(5 * phase))
    if kind == "bell":
        return (math.sin(phase) + 0.40 * math.sin(2.01 * phase) +
                0.20 * math.sin(3.98 * phase) + 0.08 * math.sin(6.03 * phase))
    return math.sin(phase)


def add_note(start, duration, note, amplitude, pan=0.0, kind="lead",
             attack=0.01, decay=0.08, sustain=0.72, release=0.16,
             vibrato=0.0, detune=0.0):
    freq = frequency(note) * (2.0 ** (detune / 1200.0))
    first = max(0, int(start * SR))
    last = min(SAMPLES, int((start + duration) * SR))
    gain_l, gain_r = pan_gains(pan)
    phase_offset = random.random() * math.tau
    for i in range(first, last):
        t = i / SR - start
        phase = math.tau * freq * t + phase_offset
        if vibrato:
            phase += vibrato * math.sin(math.tau * 5.2 * t)
        value = oscillator(kind, phase) * envelope(
            t, duration, attack, decay, sustain, release) * amplitude
        left[i] += value * gain_l
        right[i] += value * gain_r


def add_lead(start, duration, note, amplitude=0.034):
    add_note(start, duration, note, amplitude, 0.06, "lead",
             attack=0.025, decay=0.10, sustain=0.70, release=0.22, vibrato=0.018)
    add_note(start + 0.008, duration, note, amplitude * 0.45, -0.18, "lead",
             attack=0.03, decay=0.10, sustain=0.65, release=0.22, detune=-7.0)
    # Tempo-locked stereo echo keeps the melody spacious without muddying the loop.
    if start + 0.75 * BEAT < DURATION:
        add_note(start + 0.75 * BEAT, duration * 0.72, note, amplitude * 0.16,
                 0.42, "lead", attack=0.025, decay=0.08, sustain=0.55, release=0.18)


def add_noise(start, duration, amplitude, pan=0.0, brightness=1.0):
    first = max(0, int(start * SR))
    last = min(SAMPLES, int((start + duration) * SR))
    gain_l, gain_r = pan_gains(pan)
    previous = 0.0
    for i in range(first, last):
        t = i / SR - start
        raw = random.random() * 2.0 - 1.0
        shaped = raw * brightness + previous * (1.0 - brightness)
        previous = shaped
        env = envelope(t, duration, 0.002, 0.015, 0.30, duration * 0.72)
        left[i] += shaped * amplitude * env * gain_l
        right[i] += shaped * amplitude * env * gain_r


def add_kick(start, amplitude=0.16):
    duration = 0.34
    first = int(start * SR)
    last = min(SAMPLES, int((start + duration) * SR))
    phase = 0.0
    for i in range(first, last):
        t = i / SR - start
        freq = 46.0 + 105.0 * math.exp(-t * 28.0)
        phase += math.tau * freq / SR
        env = math.exp(-t * 11.0)
        value = math.sin(phase) * amplitude * env
        left[i] += value * 0.707
        right[i] += value * 0.707


def add_snare(start, amplitude=0.075):
    add_noise(start, 0.22, amplitude, -0.05, 0.82)
    add_note(start, 0.16, 185.0, amplitude * 0.42, 0.04, "lead",
             attack=0.002, decay=0.03, sustain=0.12, release=0.11)


# D minor / F major progression: nocturnal, adventurous, and loop-friendly.
progression = [
    (["D3", "F3", "A3", "C4"], "D2", "A2"),
    (["A#2", "D3", "F3", "A3"], "A#1", "F2"),
    (["F3", "A3", "C4", "E4"], "F2", "C3"),
    (["C3", "E3", "G3", "A#3"], "C2", "G2"),
    (["D3", "F3", "A3", "C4"], "D2", "A2"),
    (["A#2", "D3", "F3", "A3"], "A#1", "F2"),
    (["G2", "A#2", "D3", "F3"], "G1", "D2"),
    (["A2", "C#3", "E3", "G3"], "A1", "E2"),
]

# Wide analog pads establish the moonlit harbor.
for bar in range(BARS):
    chord, _, _ = progression[bar % len(progression)]
    start = bar * BAR
    pad_level = 0.017 if bar < 4 else 0.021
    for index, note in enumerate(chord):
        pan = -0.45 + index * 0.30
        add_note(start, BAR * 1.03, note, pad_level, pan, "pad",
                 attack=0.30, decay=0.30, sustain=0.74, release=0.45, detune=-4.0)
        add_note(start + 0.012, BAR * 1.03, note, pad_level * 0.72, -pan, "pad",
                 attack=0.34, decay=0.30, sustain=0.68, release=0.45, detune=5.0)

# Driving octave bass enters after the four-bar harbor intro.
for bar in range(4, BARS):
    _, root, fifth = progression[bar % len(progression)]
    start = bar * BAR
    pattern = [(0.0, root, 0.68), (0.5, root, 0.38), (1.0, root, 0.58),
               (1.5, fifth, 0.34), (2.0, root, 0.62), (2.5, root, 0.34),
               (3.0, fifth, 0.52), (3.5, root, 0.32)]
    for beat_pos, note, length in pattern:
        add_note(start + beat_pos * BEAT, length * BEAT, note, 0.055, -0.08,
                 "bass", attack=0.008, decay=0.07, sustain=0.64, release=0.10)

# Sparkling arcade arpeggio; it thins out during the middle breakdown.
for bar in range(4, BARS):
    if 20 <= bar < 24:
        continue
    chord, _, _ = progression[bar % len(progression)]
    high_chord = chord[1:] + [chord[0][:-1] + str(int(chord[0][-1]) + 1)]
    start = bar * BAR
    for step in range(16):
        note = high_chord[step % len(high_chord)]
        add_note(start + step * 0.25 * BEAT, 0.23 * BEAT, note, 0.014,
                 -0.34 if step % 2 == 0 else 0.34, "pluck",
                 attack=0.004, decay=0.04, sustain=0.38, release=0.07)

# Linn-inspired drum machine groove.
for bar in range(4, BARS):
    start = bar * BAR
    for beat_pos in (0.0, 2.0):
        add_kick(start + beat_pos * BEAT, 0.16)
    if bar % 4 in (1, 3):
        add_kick(start + 2.75 * BEAT, 0.09)
    for beat_pos in (1.0, 3.0):
        add_snare(start + beat_pos * BEAT, 0.068)
    for eighth in range(8):
        hat_pan = 0.30 if eighth % 2 else -0.22
        add_noise(start + eighth * 0.5 * BEAT, 0.065,
                  0.014 if eighth % 2 else 0.010, hat_pan, 0.94)
    if bar >= 24:
        for sixteenth in (3, 7, 11, 15):
            add_noise(start + sixteenth * 0.25 * BEAT, 0.038, 0.006, 0.48, 0.98)

# Original lighthouse-call melody. Its wide intervals and downward answers evoke
# harbor horns without quoting any existing composition.
hook = [
    ("D5", 0.0, 0.65), ("A5", 0.75, 0.42), ("C6", 1.25, 0.64),
    ("A5", 2.05, 0.42), ("F5", 2.55, 0.60), ("E5", 3.25, 0.55),
    ("F5", 0.0, 0.48), ("A5", 0.58, 0.48), ("C6", 1.20, 0.72),
    ("A5", 2.10, 0.50), ("G5", 2.72, 0.44), ("F5", 3.28, 0.52),
    ("C5", 0.0, 0.55), ("F5", 0.72, 0.40), ("A5", 1.24, 0.62),
    ("G5", 2.05, 0.42), ("E5", 2.58, 0.56), ("D5", 3.28, 0.50),
    ("E5", 0.0, 0.42), ("G5", 0.55, 0.42), ("A5", 1.12, 0.72),
    ("G5", 2.05, 0.45), ("E5", 2.62, 0.45), ("C#5", 3.20, 0.58),
]

def place_hook(first_bar, level=1.0):
    for index, (note, position, length) in enumerate(hook):
        bar = first_bar + index // 6
        add_lead(bar * BAR + position * BEAT, length * BEAT, note, 0.032 * level)


place_hook(8, 0.92)
place_hook(24, 1.08)

# A quieter answering motif bridges the two statements.
answer = [("D5", 0.0, 0.7), ("F5", 1.0, 0.45), ("G5", 1.65, 0.65),
          ("A5", 2.6, 0.8), ("C6", 0.0, 0.7), ("A5", 1.0, 0.52),
          ("F5", 1.75, 0.65), ("E5", 2.7, 0.72)]
for index, (note, position, length) in enumerate(answer):
    bar = 16 + index // 4
    add_lead(bar * BAR + position * BEAT, length * BEAT, note, 0.025)

# Sonar and ship-bell accents reinforce the nautical identity.
for bar in (0, 8, 16, 24):
    start = bar * BAR + 0.15 * BEAT
    add_note(start, 1.7 * BEAT, "D6", 0.020, 0.52, "bell",
             attack=0.004, decay=0.20, sustain=0.26, release=0.75)
    add_note(start + 0.75 * BEAT, 1.2 * BEAT, "A5", 0.009, -0.45, "bell",
             attack=0.004, decay=0.16, sustain=0.20, release=0.62)

# Gentle ocean-like filtered noise sits beneath the music.
add_noise(0.0, DURATION, 0.0032, -0.25, 0.035)
add_noise(0.0, DURATION, 0.0028, 0.30, 0.028)

# Soft limiting and a tiny edge fade prevent clicks at the compressed loop seam.
peak = max(max(abs(value) for value in left), max(abs(value) for value in right), 1e-9)
gain = 0.86 / peak
edge_samples = int(0.018 * SR)
pcm = bytearray()
for i, (sample_l, sample_r) in enumerate(zip(left, right)):
    edge = 1.0
    if i < edge_samples:
        edge = i / edge_samples
    elif i >= SAMPLES - edge_samples:
        edge = (SAMPLES - 1 - i) / edge_samples
    output_l = math.tanh(sample_l * gain * 1.12) * edge
    output_r = math.tanh(sample_r * gain * 1.12) * edge
    pcm.extend(struct.pack("<hh", int(max(-1.0, min(1.0, output_l)) * 32767),
                           int(max(-1.0, min(1.0, output_r)) * 32767)))

with tempfile.TemporaryDirectory() as temp_dir:
    wav_path = Path(temp_dir) / "midnight_harbor_arcade_loop.wav"
    with wave.open(str(wav_path), "wb") as wav_file:
        wav_file.setnchannels(2)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SR)
        wav_file.writeframes(pcm)
    subprocess.run([
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-i", str(wav_path), "-codec:a", "vorbis", "-strict", "experimental",
        "-q:a", "5", str(OUTPUT)
    ], check=True)

print(f"Generated {OUTPUT} ({DURATION:.2f}s, {BPM} BPM)")
