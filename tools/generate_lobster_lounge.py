#!/usr/bin/env python3
"""Generate an original melodic game-loop soundtrack for Lobster Clicker.

Direction: gentler indie-game soundtrack energy — more composed than procedural,
with held notes, rests, phrase rhythm, and an actual harmonic arc. Do not copy
any reference soundtrack; this is original music for the game.
"""
import math
import random
import struct
import wave
from pathlib import Path

SR = 44100
BPM = 92
BEAT = 60.0 / BPM
BAR = BEAT * 4
BARS = 48
DUR = BAR * BARS
N = int(DUR * SR)
random.seed(104)

L = [0.0] * N
R = [0.0] * N

BASE = {
    'C': 261.63, 'C#': 277.18, 'Db': 277.18, 'D': 293.66, 'D#': 311.13, 'Eb': 311.13,
    'E': 329.63, 'F': 349.23, 'F#': 369.99, 'Gb': 369.99, 'G': 392.00,
    'G#': 415.30, 'Ab': 415.30, 'A': 440.00, 'A#': 466.16, 'Bb': 466.16, 'B': 493.88,
}

def freq(note: str) -> float:
    name = note[:-1]
    octave = int(note[-1])
    return BASE[name] * (2 ** (octave - 4))

def pan_gains(pan):
    return math.sqrt((1 - pan) * 0.5), math.sqrt((1 + pan) * 0.5)

def env(t, dur, attack=0.025, release=0.18):
    if t < 0 or t > dur:
        return 0.0
    if t < attack:
        return t / max(attack, 1e-6)
    if t > dur - release:
        return max(0.0, (dur - t) / max(release, 1e-6))
    return 1.0

def osc(kind, x):
    if kind == 'sine':
        return math.sin(x)
    if kind == 'warm':
        return math.sin(x) + 0.22 * math.sin(2*x) + 0.08 * math.sin(3*x)
    if kind == 'bell':
        return math.sin(x) + 0.32 * math.sin(2.01*x) + 0.12 * math.sin(3.98*x)
    if kind == 'bass':
        return math.sin(x) + 0.14 * math.sin(2*x)
    if kind == 'pad':
        return math.sin(x) + 0.18 * math.sin(0.5*x) + 0.10 * math.sin(1.5*x)
    return math.sin(x)

def add_tone(t0, dur, note_or_freq, amp, pan=0.0, kind='sine', attack=0.02, release=0.18, vibrato=0.0):
    f0 = freq(note_or_freq) if isinstance(note_or_freq, str) else float(note_or_freq)
    start = max(0, int(t0 * SR))
    end = min(N, int((t0 + dur) * SR))
    lg, rg = pan_gains(pan)
    phase = random.random() * math.tau
    for i in range(start, end):
        t = i / SR - t0
        v = 1.0 + vibrato * math.sin(math.tau * 4.8 * t)
        x = math.tau * f0 * v * t + phase
        trem = 0.98 + 0.02 * math.sin(math.tau * 0.65 * (i / SR))
        s = osc(kind, x) * env(t, dur, attack, release) * amp * trem
        L[i] += s * lg
        R[i] += s * rg

def add_noise(t0, dur, amp, pan=0.0):
    start = max(0, int(t0 * SR))
    end = min(N, int((t0 + dur) * SR))
    lg, rg = pan_gains(pan)
    for i in range(start, end):
        t = i / SR - t0
        n = math.sin(i * 19.191) * 9176.271
        n = (n - math.floor(n)) * 2 - 1
        e = env(t, dur, attack=0.002, release=dur * 0.8)
        L[i] += n * amp * e * lg
        R[i] += n * amp * e * rg

def add_echoed(t0, dur, note, amp, pan, kind='bell', attack=0.015, release=0.22, vibrato=0.0015):
    add_tone(t0, dur, note, amp, pan, kind, attack, release, vibrato)
    add_tone(t0 + 0.38, dur * 0.72, note, amp * 0.28, -pan * 0.7, kind, attack, release, vibrato)
    add_tone(t0 + 0.76, dur * 0.55, note, amp * 0.14, pan * 0.3, kind, attack, release, vibrato)

# A minor / C major wistful loop, softened for idle-game background.
chords = [
    ('Am', ['A2','E3','A3','C4','E4']),
    ('F',  ['F2','C3','A3','C4','E4']),
    ('C',  ['C3','G3','C4','E4','G4']),
    ('G',  ['G2','D3','B3','D4','G4']),
    ('Dm', ['D3','A3','D4','F4','A4']),
    ('Am', ['A2','E3','A3','C4','E4']),
    ('F',  ['F2','C3','A3','C4','E4']),
    ('E',  ['E3','B3','D4','G#4','B4']),
]

# Pads and bass foundation: long notes first, so the track has shape.
for bar in range(BARS):
    cname, notes = chords[(bar // 2) % len(chords)]
    t = bar * BAR
    if bar % 2 == 0:
        # two-bar sustained pad, deliberately held and non-grating
        for idx, n in enumerate(notes[2:]):
            add_tone(t + 0.02 * idx, BAR * 1.92, n, 0.014, -0.12 + idx * 0.12, 'pad', attack=0.55, release=0.85, vibrato=0.001)
    # Bass has a rhythm, not a metronome: root, rest, fifth, passing tone.
    root = notes[0]
    fifth = notes[1]
    add_tone(t + 0.00 * BEAT, 1.35 * BEAT, root, 0.055, -0.08, 'bass', attack=0.03, release=0.25)
    if bar % 4 != 3:
        add_tone(t + 2.25 * BEAT, 0.80 * BEAT, fifth, 0.038, -0.04, 'bass', attack=0.03, release=0.20)
    if bar % 8 in (5, 6):
        add_tone(t + 3.35 * BEAT, 0.45 * BEAT, notes[2], 0.026, -0.04, 'bass', attack=0.02, release=0.16)

# Soft rhythmic bed: sparse brush/shaker, not click-clock-click-clock.
for bar in range(BARS):
    t = bar * BAR
    # gentle downbeat pulse every other bar
    if bar % 2 == 0:
        add_tone(t, 0.18, 74.0, 0.045, 0.0, 'sine', attack=0.004, release=0.16)
    for pos, amp in [(1.50, 0.006), (2.75, 0.008), (3.42, 0.005)]:
        if not (bar % 8 == 7 and pos > 3):
            add_noise(t + pos * BEAT, 0.060, amp, 0.46)
    if bar % 4 == 1:
        add_tone(t + 2.0 * BEAT, 0.07, 880.0, 0.008, 0.30, 'sine', attack=0.004, release=0.06)

# Main composed melody. Values are (note/rest, beat_offset, beat_duration).
# This deliberately mixes held notes, short pickups, silence, and phrase endings.
phrase_a = [
    ('E5',0.25,0.75), ('G5',1.25,0.50), ('A5',2.00,1.50),
    ('R',0.00,1.00),  ('C6',1.00,0.50), ('B5',1.75,0.75), ('A5',2.75,1.00),
    ('G5',0.50,1.20), ('E5',2.10,0.70), ('D5',3.10,0.55),
    ('E5',0.00,1.00), ('R',1.00,0.50), ('C5',1.60,0.70), ('A4',2.55,1.20),
]
phrase_b = [
    ('C5',0.00,0.80), ('D5',1.10,0.40), ('E5',1.70,1.40),
    ('G5',0.30,0.65), ('A5',1.20,1.00), ('G5',2.55,0.90),
    ('F5',0.10,1.15), ('E5',1.70,0.55), ('D5',2.45,1.10),
    ('C5',0.20,0.65), ('E5',1.10,0.50), ('D5',1.90,0.80), ('A4',3.00,0.85),
]
phrase_c = [
    ('A4',0.00,1.70), ('C5',2.10,0.55), ('D5',3.00,0.50),
    ('E5',0.15,0.90), ('R',1.05,0.35), ('G5',1.55,0.75), ('E5',2.65,0.80),
    ('D5',0.00,1.20), ('F5',1.65,0.45), ('E5',2.30,1.25),
    ('C5',0.30,0.75), ('B4',1.35,0.55), ('C5',2.15,1.35),
]
phrases = [phrase_a, phrase_b, phrase_a, phrase_c, phrase_a, phrase_b]

for section, phrase in enumerate(phrases):
    base_bar = section * 8
    if base_bar >= BARS:
        break
    # Melody is active for 4 bars, then leaves space / accompaniment breathes.
    for idx, (n, beat_pos, beat_len) in enumerate(phrase):
        bar = base_bar + idx // 3
        if bar >= base_bar + 4 or bar >= BARS:
            continue
        if n == 'R':
            continue
        t = bar * BAR + beat_pos * BEAT
        dur = beat_len * BEAT
        amp = 0.026 if section != 3 else 0.023
        add_echoed(t, dur, n, amp, 0.18, 'bell', attack=0.035, release=min(0.42, dur * 0.65), vibrato=0.0015)
        # occasional lower harmony, only on held notes
        if beat_len >= 1.0 and idx % 2 == 0:
            harmony = {'A5':'E5','G5':'E5','E5':'C5','D5':'A4','C6':'A5','C5':'A4'}.get(n)
            if harmony:
                add_tone(t + 0.08, dur * 0.90, harmony, amp * 0.36, -0.22, 'warm', attack=0.06, release=0.35, vibrato=0.001)

# Piano/guitar-like arpeggios in the breathing spaces, with uneven rhythm.
arpeggio_times = [0.0, 0.85, 1.65, 2.70, 3.25]
for bar in range(4, BARS, 8):
    for b in range(bar, min(bar + 4, BARS)):
        cname, notes = chords[(b // 2) % len(chords)]
        t = b * BAR
        arp_notes = notes[2:] + [notes[3]]
        for k, pos in enumerate(arpeggio_times):
            if b % 8 == 7 and k > 2:
                continue
            add_tone(t + pos * BEAT, 0.55 * BEAT, arp_notes[k % len(arp_notes)], 0.012, 0.34, 'warm', attack=0.018, release=0.22, vibrato=0.0008)

# A gentle final swell back into the start, but leave last beat quiet for looping.
for n, pan in [('A3', -0.20), ('C4', 0.0), ('E4', 0.20), ('A4', 0.08)]:
    add_tone((BARS - 2) * BAR, BAR * 1.55, n, 0.010, pan, 'pad', attack=0.7, release=0.7, vibrato=0.001)

# Master soft saturation + normalization + click-free edges.
peak = max(max(abs(x) for x in L), max(abs(x) for x in R), 1e-9)
gain = 0.78 / peak
fade = int(0.10 * SR)
for i in range(N):
    edge = 1.0
    if i < fade:
        edge = i / fade
    elif i > N - fade:
        edge = (N - i) / fade
    L[i] = math.tanh(L[i] * gain * 1.12) * edge
    R[i] = math.tanh(R[i] * gain * 1.12) * edge

out = Path('assets/music/lobster_lounge_loop.wav')
out.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(out), 'wb') as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    for l, r in zip(L, R):
        w.writeframes(struct.pack('<hh', int(max(-1, min(1, l)) * 32767), int(max(-1, min(1, r)) * 32767)))
print(out, f'{DUR:.2f}s')
