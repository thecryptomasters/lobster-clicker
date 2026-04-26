#!/usr/bin/env python3
"""Generate a soft, loopable bossa/sea-shanty background track for Lobster Clicker."""
import math, wave, struct, random
from pathlib import Path

SR = 44100
BPM = 96
BEAT = 60.0 / BPM
BAR = BEAT * 4
BARS = 32
DUR = BAR * BARS
N = int(DUR * SR)
random.seed(7)

# Stereo buffer
L = [0.0] * N
R = [0.0] * N

NOTE = {
    'C3':130.81,'D3':146.83,'E3':164.81,'F3':174.61,'G3':196.00,'A3':220.00,'Bb3':233.08,'B3':246.94,
    'C4':261.63,'D4':293.66,'E4':329.63,'F4':349.23,'G4':392.00,'A4':440.00,'Bb4':466.16,'B4':493.88,
    'C5':523.25,'D5':587.33,'E5':659.25,'F5':698.46,'G5':783.99,'A5':880.00
}

def env(t, dur, a=0.015, r=0.08):
    if t < 0 or t > dur: return 0.0
    if t < a: return t / a
    if t > dur - r: return max(0.0, (dur - t) / r)
    return 1.0

def add(t0, dur, freq, amp, pan=0.0, kind='sine', vib=0.0):
    start = max(0, int(t0*SR)); end = min(N, int((t0+dur)*SR))
    lp = math.sqrt((1-pan)*0.5); rp = math.sqrt((1+pan)*0.5)
    phase = random.random() * math.tau
    for i in range(start, end):
        t = i/SR - t0
        f = freq * (1.0 + vib * math.sin(math.tau*4.2*t))
        x = math.tau * f * t + phase
        if kind == 'sine':
            s = math.sin(x)
        elif kind == 'soft_square':
            s = math.sin(x) + 0.28*math.sin(3*x) + 0.10*math.sin(5*x)
        elif kind == 'guitar':
            s = math.sin(x) + 0.38*math.sin(2*x) + 0.18*math.sin(3*x)
        elif kind == 'bass':
            s = math.sin(x) + 0.18*math.sin(2*x)
        else:
            s = math.sin(x)
        e = env(t, dur)
        # gentle low-fi tremolo, keeps elevator-lounge feel
        trem = 0.92 + 0.08 * math.sin(math.tau*1.5*(i/SR))
        L[i] += s * amp * e * trem * lp
        R[i] += s * amp * e * trem * rp

def add_chord(t0, notes, dur=1.45, amp=0.045, pan=-0.25):
    # staggered bossa comp, like muted nylon guitar/organ
    for k, n in enumerate(notes):
        add(t0 + 0.012*k, dur, NOTE[n], amp, pan + 0.06*k, 'guitar')

def add_noise(t0, dur, amp, pan=0.0, hp=False):
    start=max(0,int(t0*SR)); end=min(N,int((t0+dur)*SR))
    lp=math.sqrt((1-pan)*0.5); rp=math.sqrt((1+pan)*0.5)
    last=0.0
    for i in range(start,end):
        t=i/SR-t0
        raw=random.uniform(-1,1)
        if hp:
            raw = raw - last*0.96
            last = raw
        e=env(t,dur,a=0.002,r=dur*0.8)
        L[i]+=raw*amp*e*lp
        R[i]+=raw*amp*e*rp

progression = [
    ('C3', ['E4','G4','B4','D5']),   # Cmaj9-ish
    ('A3', ['C4','E4','G4','B4']),   # Am9
    ('D3', ['F4','A4','C5','E5']),   # Dm9
    ('G3', ['B3','F4','A4','D5']),   # G13
    ('E3', ['G4','B4','D5','F5']),   # Em7b9 color
    ('A3', ['C4','E4','G4','C5']),
    ('D3', ['F4','A4','C5','E5']),
    ('G3', ['F4','A4','B4','D5']),
]
melody = ['E5','G5','A5','G5','E5','D5','C5','D5', 'E5','D5','C5','A4','G4','A4','C5','D5']
shanty = ['C5','E5','G5','A5','G5','E5','D5','C5', 'D5','F5','A5','G5','E5','D5','C5','G4']

for bar in range(BARS):
    t = bar * BAR
    root, chord = progression[bar % len(progression)]
    # bossa clave-ish comping; varies every pass so loop length feels long
    hits = [0, 1.5, 2.5, 3.25] if (bar//8) % 2 == 0 else [0, 1.0, 2.25, 3.5]
    for h in hits:
        add_chord(t + h*BEAT, chord, dur=0.72 if h else 1.05, amp=0.034)
    # warm walking bass on 1 and syncopated 3+
    add(t + 0.02, 0.48, NOTE[root], 0.075, -0.08, 'bass')
    fifth = {'C3':'G3','A3':'E3','D3':'A3','G3':'D3','E3':'B3'}[root]
    add(t + 2.05*BEAT, 0.42, NOTE[fifth], 0.058, -0.05, 'bass')
    # soft brushes / shaker, deliberately understated
    for beat in [0, 1, 2, 3]:
        add_noise(t + beat*BEAT, 0.055, 0.012, 0.35, hp=True)
    for off in [0.5, 1.5, 2.5, 3.5]:
        add_noise(t + off*BEAT, 0.045, 0.008, 0.55, hp=True)
    # tiny rim/click every other bar
    if bar % 2 == 1:
        add(t + 1.98*BEAT, 0.05, 1046.5, 0.018, 0.25, 'sine')

# Melody: sea-shanty contour but played like a sleepy vibraphone/whistle.
for phrase in range(4):
    base_bar = phrase * 8
    seq = melody if phrase in (0, 3) else shanty
    for j, n in enumerate(seq):
        # leave air between notes; no huge tail at the loop boundary
        bar = base_bar + (j // 2)
        beat = (j % 2) * 2 + (0.18 if j % 4 == 1 else 0.0)
        t = bar*BAR + beat*BEAT
        if t + 0.95 < DUR - 0.08:
            add(t, 0.82, NOTE[n], 0.030 if phrase != 2 else 0.026, 0.22, 'soft_square', vib=0.0025)
            add(t + 0.01, 0.78, NOTE[n]*2, 0.006, 0.28, 'sine', vib=0.002)

# Gentle sea-air pad swells, avoiding final half-bar so the wrap is clean.
for bar in range(0, BARS-1, 4):
    t = bar * BAR + 0.15
    for n in ['C4','G4','D5']:
        add(t, BAR*3.5, NOTE[n], 0.012, 0.0, 'sine', vib=0.001)

# Master soft saturation + short fade edges to avoid clicks.
peak = max(max(abs(x) for x in L), max(abs(x) for x in R), 1e-9)
gain = 0.78 / peak
fade = int(0.06 * SR)
for i in range(N):
    edge = 1.0
    if i < fade: edge = i / fade
    elif i > N - fade: edge = (N - i) / fade
    l = math.tanh(L[i] * gain * 1.15) * edge
    r = math.tanh(R[i] * gain * 1.15) * edge
    L[i], R[i] = l, r

out = Path('assets/music/lobster_lounge_loop.wav')
out.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(out), 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    for l, r in zip(L, R):
        w.writeframes(struct.pack('<hh', int(max(-1,min(1,l))*32767), int(max(-1,min(1,r))*32767)))
print(out, f'{DUR:.2f}s')
