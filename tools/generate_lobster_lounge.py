#!/usr/bin/env python3
"""Generate a longer melodic, loopable lounge/sea-shanty background track for Lobster Clicker.

The goal is background music that has an actual tune without becoming a 7-second
brain drill. It uses four 16-bar sections (A/B/C/A') with shared harmony so the
final wrap feels intentional.
"""
import math
import random
import struct
import wave
from pathlib import Path

SR = 44100
BPM = 112
BEAT = 60.0 / BPM
BAR = BEAT * 4
BARS = 64
DUR = BAR * BARS
N = int(DUR * SR)
random.seed(42)

L = [0.0] * N
R = [0.0] * N

BASE = {
    'C': 261.63, 'C#': 277.18, 'Db': 277.18, 'D': 293.66, 'D#': 311.13, 'Eb': 311.13,
    'E': 329.63, 'F': 349.23, 'F#': 369.99, 'Gb': 369.99, 'G': 392.00,
    'G#': 415.30, 'Ab': 415.30, 'A': 440.00, 'A#': 466.16, 'Bb': 466.16, 'B': 493.88,
}

def note_freq(note: str) -> float:
    name = note[:-1]
    octave = int(note[-1])
    return BASE[name] * (2 ** (octave - 4))

NOTE = {f'{n}{o}': note_freq(f'{n}{o}') for n in BASE for o in range(2, 7)}

CHORDS = {
    'Am9': ['A3', 'C4', 'E4', 'G4', 'B4'],
    'Dm9': ['D3', 'F4', 'A4', 'C5', 'E5'],
    'G13': ['G3', 'F4', 'A4', 'B4', 'E5'],
    'Cmaj9': ['C3', 'E4', 'G4', 'B4', 'D5'],
    'Fmaj9': ['F3', 'A3', 'C4', 'E4', 'G4'],
    'E7': ['E3', 'G#3', 'B3', 'D4', 'E4'],
    'Em9': ['E3', 'G3', 'B3', 'D4', 'F#4'],
    'A7': ['A3', 'G4', 'C#5', 'E5'],
}

PROGRESSION = [
    'Am9', 'Dm9', 'G13', 'Cmaj9',
    'Fmaj9', 'Dm9', 'E7', 'E7',
    'Am9', 'Dm9', 'G13', 'Cmaj9',
    'Fmaj9', 'Em9', 'Dm9', 'E7',
]

SECTIONS = [
    # A: hook, singable and simple
    ['E5','G5','A5','C6','B5','A5','G5','E5', 'D5','E5','G5','A5','G5','E5','D5','C5'],
    # B: answer phrase, more sea-shanty contour
    ['A4','C5','E5','A5','G5','E5','D5','C5', 'D5','F5','A5','G5','E5','D5','C5','A4'],
    # C: little bridge so the loop breathes
    ['C5','D5','E5','G5','A5','G5','E5','D5', 'F5','E5','D5','C5','B4','C5','D5','E5'],
    # A': returns to hook with a small ending lift
    ['E5','G5','A5','C6','B5','A5','G5','E5', 'D5','E5','G5','B5','A5','G5','E5','A4'],
]

def envelope(t, dur, a=0.012, r=0.10):
    if t < 0 or t > dur:
        return 0.0
    if t < a:
        return t / a
    if t > dur - r:
        return max(0.0, (dur - t) / r)
    return 1.0

def pan_gains(pan):
    return math.sqrt((1 - pan) * 0.5), math.sqrt((1 + pan) * 0.5)

def wave_sample(kind, x):
    if kind == 'sine':
        return math.sin(x)
    if kind == 'bass':
        return math.sin(x) + 0.18 * math.sin(2 * x)
    if kind == 'lead':
        return 0.72 * (2 / math.pi) * math.asin(math.sin(x)) + 0.18 * math.sin(2 * x)
    if kind == 'organ':
        return math.sin(x) + 0.34 * math.sin(2 * x) + 0.12 * math.sin(3 * x)
    if kind == 'pluck':
        return math.sin(x) + 0.28 * math.sin(2 * x) + 0.10 * math.sin(4 * x)
    return math.sin(x)

def add_tone(t0, dur, freq, amp, pan=0.0, kind='sine', vib=0.0):
    start = max(0, int(t0 * SR))
    end = min(N, int((t0 + dur) * SR))
    lg, rg = pan_gains(pan)
    phase = random.random() * math.tau
    for i in range(start, end):
        t = i / SR - t0
        f = freq * (1.0 + vib * math.sin(math.tau * 4.4 * t))
        x = math.tau * f * t + phase
        trem = 0.94 + 0.06 * math.sin(math.tau * 1.25 * (i / SR))
        s = wave_sample(kind, x) * envelope(t, dur) * amp * trem
        L[i] += s * lg
        R[i] += s * rg

def add_noise(t0, dur, amp, pan=0.0):
    start = max(0, int(t0 * SR))
    end = min(N, int((t0 + dur) * SR))
    lg, rg = pan_gains(pan)
    for i in range(start, end):
        t = i / SR - t0
        # deterministic pseudo-random noise, softer than random.uniform in tight loops
        n = math.sin(i * 12.9898) * 43758.5453
        n = (n - math.floor(n)) * 2 - 1
        e = envelope(t, dur, a=0.002, r=dur * 0.82)
        L[i] += n * amp * e * lg
        R[i] += n * amp * e * rg

def add_chord(t0, chord_name, dur=0.72, amp=0.030, pan=-0.23):
    notes = CHORDS[chord_name][1:]
    for k, note in enumerate(notes):
        add_tone(t0 + 0.010 * k, dur, NOTE[note], amp, pan + 0.055 * k, 'pluck')

def root_and_fifth(chord_name):
    root = CHORDS[chord_name][0]
    fifths = {
        'A3': 'E3', 'D3': 'A3', 'G3': 'D3', 'C3': 'G3',
        'F3': 'C4', 'E3': 'B3',
    }
    return root, fifths.get(root, root)

# Harmony, bass, and rhythm bed.
for bar in range(BARS):
    t = bar * BAR
    chord = PROGRESSION[bar % len(PROGRESSION)]
    section = bar // 16

    patterns = ([0, 1.50, 2.50, 3.25], [0, 1.00, 2.25, 3.50], [0, 0.75, 2.00, 3.10], [0, 1.40, 2.40, 3.40])
    for hit in patterns[(bar // 4) % len(patterns)]:
        add_chord(t + hit * BEAT, chord, dur=0.95 if hit == 0 else 0.58, amp=0.028 + 0.002 * section)

    root, fifth = root_and_fifth(chord)
    add_tone(t + 0.02, 0.48, NOTE[root], 0.074, -0.10, 'bass')
    add_tone(t + 2.03 * BEAT, 0.40, NOTE[fifth], 0.055, -0.06, 'bass')
    if section >= 1:
        add_tone(t + 3.18 * BEAT, 0.30, NOTE[root] * 2, 0.030, -0.05, 'bass')

    # brushed drums / shaker / tiny clicker percussion
    for b in [0, 1, 2, 3]:
        add_noise(t + b * BEAT, 0.050, 0.010, 0.42)
    for off in [0.5, 1.5, 2.5, 3.5]:
        add_noise(t + off * BEAT, 0.038, 0.0075, 0.58)
    if bar % 2 == 1:
        add_tone(t + 1.98 * BEAT, 0.045, 1046.5, 0.014, 0.22, 'sine')
    if section >= 2 and bar % 4 == 2:
        add_tone(t + 3.45 * BEAT, 0.055, 1568.0, 0.012, 0.42, 'sine')

# Lead melody: two notes per bar, with variations in each 16-bar section.
for section, seq in enumerate(SECTIONS):
    base_bar = section * 16
    for j, note in enumerate(seq):
        bar = base_bar + (j // 2)
        beat = (j % 2) * 2
        # human-ish offsets, but keep first/last section clean for loop wrap
        if j % 4 == 1:
            beat += 0.16
        if j % 8 == 6:
            beat += 0.08
        t = bar * BAR + beat * BEAT
        dur = 0.82 if section != 2 else 0.70
        amp = [0.032, 0.029, 0.027, 0.033][section]
        add_tone(t, dur, NOTE[note], amp, 0.20, 'lead', vib=0.0025)
        add_tone(t + 0.012, dur * 0.92, NOTE[note] * 2, amp * 0.16, 0.30, 'sine', vib=0.002)
        # small call-and-response harmony on later sections, sparse enough not to grate
        if section in (1, 3) and j % 4 in (1, 3):
            harmony = seq[max(0, j - 2)]
            add_tone(t + 0.06, dur * 0.65, NOTE[harmony], amp * 0.34, -0.18, 'organ', vib=0.0015)

# Arpeggio sparkle appears after the intro, then backs off for the final return.
for bar in range(8, 56):
    chord = PROGRESSION[bar % len(PROGRESSION)]
    notes = CHORDS[chord][1:]
    t = bar * BAR
    for step in range(4):
        n = notes[(step + bar) % len(notes)]
        add_tone(t + (0.55 + step * 0.75) * BEAT, 0.22, NOTE[n] * 2, 0.0085, 0.48, 'sine', vib=0.001)

# Sea-air pad swells under each section; stop before the last bar so the loop boundary is clean.
for bar in range(0, BARS - 2, 8):
    t = bar * BAR + 0.10
    pad_chord = PROGRESSION[bar % len(PROGRESSION)]
    for n in CHORDS[pad_chord][1:4]:
        add_tone(t, BAR * 6.7, NOTE[n], 0.009, 0.0, 'sine', vib=0.001)

# Master: soft saturation, normalize, and short fade edges to avoid clicks.
peak = max(max(abs(x) for x in L), max(abs(x) for x in R), 1e-9)
gain = 0.82 / peak
fade = int(0.08 * SR)
for i in range(N):
    edge = 1.0
    if i < fade:
        edge = i / fade
    elif i > N - fade:
        edge = (N - i) / fade
    L[i] = math.tanh(L[i] * gain * 1.18) * edge
    R[i] = math.tanh(R[i] * gain * 1.18) * edge

out = Path('assets/music/lobster_lounge_loop.wav')
out.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(out), 'wb') as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    for l, r in zip(L, R):
        w.writeframes(struct.pack('<hh', int(max(-1, min(1, l)) * 32767), int(max(-1, min(1, r)) * 32767)))
print(out, f'{DUR:.2f}s')
