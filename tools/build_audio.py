#!/usr/bin/env python3
"""Original synthetic sounds; no third-party samples. Upload before use in Roblox."""
import math, random, struct, wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SR=22050
random.seed(173)
def save(name,seconds,sample):
 p=ROOT/'assets/audio'/f'{name}.wav';p.parent.mkdir(parents=True,exist_ok=True)
 with wave.open(str(p),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(SR)
  values=[]
  for n in range(int(seconds*SR)):
   t=n/SR;value=max(-.95,min(.95,sample(t)))
   values.append(struct.pack('<h',round(value*32767)))
  f.writeframes(b''.join(values))
def tone(t,f):return math.sin(2*math.pi*f*t)
save('break',.16,lambda t:(random.uniform(-1,1)*.18+tone(t,330)*.2)*math.exp(-30*t))
save('sell',.5,lambda t:tone(t,660 if t<.18 else 880)*.28*math.exp(-6*(t if t<.18 else t-.18)))
notes=[523.25,659.25,783.99,1046.5]
save('rank',.8,lambda t:tone(t,notes[min(3,int(t/.2))])*.24*math.exp(-8*(t%.2)))
# Integer-cycle frequencies and smooth fade make the short loop unobtrusive.
save('music',8,lambda t:sum(tone(t,f) for f in [130.75,164.75,196])/3*.12*min(1,t/.1,(8-t)/.1))
print('Generated four original WAV files')
