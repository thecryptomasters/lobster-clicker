#!/usr/bin/env python3
import math, random, struct, wave, subprocess
from pathlib import Path

SR = 44100
BPM = 84
BEAT = 60 / BPM
# 6/8 feel: one bar = 6 eighth notes = 3 quarter-note beats here
BAR = BEAT * 3
BARS = 48
DUR = BAR * BARS
N = int(DUR * SR)
random.seed(20260504)
L=[0.0]*N; R=[0.0]*N
BASE={'C':261.63,'C#':277.18,'D':293.66,'D#':311.13,'E':329.63,'F':349.23,'F#':369.99,'G':392.00,'G#':415.30,'A':440.0,'A#':466.16,'B':493.88}
def f(note):
    name=note[:-1]; oct=int(note[-1]); return BASE[name]*(2**(oct-4))
def gains(p): return math.sqrt((1-p)*0.5), math.sqrt((1+p)*0.5)
def adsr(t,d,a=0.025,r=0.18):
    if t<0 or t>d: return 0
    if t<a: return t/max(a,1e-6)
    if t>d-r: return max(0,(d-t)/max(r,1e-6))
    return 1

def tri(x): return 2/math.pi*math.asin(math.sin(x))
def osc(kind,x):
    if kind=='sine': return math.sin(x)
    if kind=='flute': return math.sin(x)+0.10*math.sin(2*x)+0.035*math.sin(3*x)
    if kind=='accordion': return math.sin(x)+0.22*math.sin(2*x)+0.11*math.sin(3*x)+0.04*math.sin(4*x)
    if kind=='pluck': return tri(x)+0.16*math.sin(2*x)
    if kind=='bass': return math.sin(x)+0.10*math.sin(2*x)
    if kind=='bell': return math.sin(x)+0.20*math.sin(2.01*x)+0.06*math.sin(3.97*x)
    return math.sin(x)

def add(t0,dur,note,amp,pan=0,kind='sine',a=0.02,r=0.18,vib=0):
    fr=f(note) if isinstance(note,str) else note
    st=max(0,int(t0*SR)); en=min(N,int((t0+dur)*SR)); gl,gr=gains(pan)
    phase=random.random()*math.tau
    for i in range(st,en):
        t=i/SR-t0
        vv=1+vib*math.sin(math.tau*5.1*t)
        x=math.tau*fr*vv*t+phase
        s=osc(kind,x)*adsr(t,dur,a,r)*amp
        L[i]+=s*gl; R[i]+=s*gr

def add_echo(t,dur,note,amp,pan=0,kind='flute'):
    add(t,dur,note,amp,pan,kind,a=0.045,r=min(0.35,dur*0.55),vib=0.0018)
    add(t+0.42,dur*0.62,note,amp*0.18,-pan*0.7,kind,a=0.045,r=0.25,vib=0.0018)

def noise(t0,dur,amp,pan=0):
    st=max(0,int(t0*SR)); en=min(N,int((t0+dur)*SR)); gl,gr=gains(pan)
    for i in range(st,en):
        t=i/SR-t0
        n=math.sin(i*17.173)*31847.13; n=(n-math.floor(n))*2-1
        e=adsr(t,dur,0.003,dur*0.8)
        L[i]+=n*amp*e*gl; R[i]+=n*amp*e*gr

# G major / E minor, consonant nautical 6/8 progression
chords=[
 ('G',['G2','D3','G3','B3','D4']), ('D',['D3','A3','D4','F#4','A4']),
 ('Em',['E3','B3','E4','G4','B4']), ('C',['C3','G3','C4','E4','G4']),
 ('G',['G2','D3','G3','B3','D4']), ('Bm',['B2','F#3','B3','D4','F#4']),
 ('C',['C3','G3','C4','E4','G4']), ('D',['D3','A3','D4','F#4','A4']),
]

# Long warm accordion/pad chords and singable bass in 6/8.
for bar in range(BARS):
    t=bar*BAR; cname,notes=chords[(bar//2)%len(chords)]
    if bar%2==0:
        for k,n in enumerate(notes[2:]):
            add(t+0.03*k,BAR*1.82,n,0.018,-0.18+0.14*k,'accordion',a=0.20,r=0.42,vib=0.0008)
    root,fifth=notes[0],notes[1]
    add(t+0.00*BEAT,0.95*BEAT,root,0.060,-0.05,'bass',a=0.025,r=0.22)
    add(t+1.55*BEAT,0.55*BEAT,fifth,0.036,-0.04,'bass',a=0.020,r=0.18)
    if bar%4 in (1,2): add(t+2.35*BEAT,0.38*BEAT,notes[2],0.026,-0.03,'bass',a=0.018,r=0.14)

# Nautical rhythm: gentle 6/8 lilt, not a straight metronome.
for bar in range(BARS):
    t=bar*BAR
    # low soft thump on 1, lighter on 4 (beat 1.5 in quarter-note units)
    add(t,0.12,68,0.038,0,'sine',a=0.004,r=0.11)
    if bar%2==0: add(t+1.50*BEAT,0.10,92,0.020,0,'sine',a=0.004,r=0.09)
    for pos,amp in [(0.74,0.0045),(1.50,0.0065),(2.24,0.0045),(2.70,0.0035)]:
        noise(t+pos*BEAT,0.045,amp,0.45)

# Main melody: original shanty-like hook with held notes, pickups, and rests.
phrases=[
 [('D5',0.00,0.55),('G5',0.68,0.45),('A5',1.18,0.85),('B5',2.15,0.55),
  ('A5',0.15,0.65),('G5',0.98,0.70),('E5',1.95,0.85),
  ('D5',0.20,0.50),('E5',0.82,0.42),('G5',1.35,1.10),('R',2.55,0.30),
  ('A5',0.05,0.55),('G5',0.72,0.55),('E5',1.38,0.62),('D5',2.18,0.72)],
 [('B4',0.10,0.70),('D5',0.98,0.46),('G5',1.50,0.95),
  ('F#5',0.08,0.55),('E5',0.78,0.64),('D5',1.55,1.12),
  ('E5',0.20,0.46),('G5',0.82,0.52),('A5',1.52,0.72),('G5',2.34,0.44),
  ('D5',0.12,0.70),('B4',1.00,0.55),('A4',1.72,0.95)],
 [('G5',0.00,1.18),('B5',1.45,0.46),('A5',2.08,0.58),
  ('G5',0.12,0.72),('E5',1.05,0.52),('D5',1.80,0.92),
  ('C5',0.20,0.56),('D5',0.88,0.50),('E5',1.58,1.02),
  ('D5',0.08,0.62),('B4',0.92,0.55),('G4',1.70,1.05)],
]
for sec in range(6):
    base=sec*8
    phrase=phrases[sec%3]
    for idx,(note,pos,length) in enumerate(phrase):
        bar=base+idx//4
        if bar>=base+4 or bar>=BARS or note=='R': continue
        t=bar*BAR+pos*BEAT; dur=length*BEAT
        add_echo(t,dur,note,0.025 if sec!=2 else 0.022,0.18,'flute')
        # consonant harmony only on long notes
        if length>0.75:
            harm={'G5':'D5','A5':'F#5','B5':'G5','E5':'B4','D5':'B4','C5':'G4'}.get(note)
            if harm: add(t+0.06,dur*0.88,harm,0.008,-0.18,'accordion',a=0.08,r=0.24,vib=0.0008)

# Between melody phrases: rolling arpeggio like a little ship bobbing.
arp_positions=[0.05,0.52,1.05,1.72,2.18]
for bar in range(4,BARS,8):
    for b in range(bar,min(bar+4,BARS)):
        cname,notes=chords[(b//2)%len(chords)]
        t=b*BAR; arp=notes[2:]
        for k,pos in enumerate(arp_positions):
            add(t+pos*BEAT,0.42*BEAT,arp[k%len(arp)],0.011,0.32,'pluck',a=0.014,r=0.20,vib=0.0005)

# final gentle resolve to make loop return feel natural
for n,p in [('G3',-0.2),('B3',-0.05),('D4',0.1),('G4',0.24)]:
    add((BARS-2)*BAR,BAR*1.55,n,0.012,p,'accordion',a=0.55,r=0.65,vib=0.0008)

peak=max(max(abs(x) for x in L),max(abs(x) for x in R),1e-9)
gain=0.76/peak
fade=int(0.08*SR)
for i in range(N):
    edge=1
    if i<fade: edge=i/fade
    elif i>N-fade: edge=(N-i)/fade
    L[i]=math.tanh(L[i]*gain*1.08)*edge
    R[i]=math.tanh(R[i]*gain*1.08)*edge

wav=Path('/Users/rosseaton/.openclaw/workspace/lobster-clicker-new-nautical-preview.wav')
mp3=Path('/Users/rosseaton/.openclaw/workspace/lobster-clicker-new-nautical-preview.mp3')
with wave.open(str(wav),'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    for l,r in zip(L,R):
        w.writeframes(struct.pack('<hh',int(max(-1,min(1,l))*32767),int(max(-1,min(1,r))*32767)))
subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(wav),'-codec:a','libmp3lame','-b:a','160k',str(mp3)],check=True)
print(mp3, f'{DUR:.2f}s')
