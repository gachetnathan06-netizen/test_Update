import numpy as np, wave, os
from scipy.signal import butter, lfilter
SR=44100
OUT='Sources/Sounds'
rng=np.random.default_rng(7)
def t(d): return np.arange(int(SR*d))/SR
def env(n,a=.005,r=.1,curve=3):
    e=np.ones(n); na=max(1,int(a*SR)); nr=max(1,int(r*SR))
    e[:na]=np.linspace(0,1,na); e[-nr:]*=np.linspace(1,0,nr)**curve
    return e
def decay(d,tau): return np.exp(-t(d)/tau)
def filt(x,kind,f,order=2):
    b,a=butter(order,f/(SR/2),btype=kind); return lfilter(b,a,x)
def noise(d): return rng.standard_normal(int(SR*d))
def sine(f,d,ph=0): 
    f=np.broadcast_to(f,(int(SR*d),)) if np.isscalar(f) else f
    return np.sin(2*np.pi*np.cumsum(f)/SR+ph)
def sweep(f0,f1,d,curve='exp'):
    n=int(SR*d); x=np.linspace(0,1,n)
    f=f0*(f1/f0)**x if curve=='exp' else f0+(f1-f0)*x
    return sine(f,d)
def bell(f,d,tau=.35,bright=1.0):
    # inharmonic FM-ish bell/marimba
    x=sine(f,d)*1+0.4*sine(f*2.76,d)*bright*np.exp(-t(d)/(tau*.4))+0.2*sine(f*5.4,d)*np.exp(-t(d)/(tau*.2))
    return x*decay(d,tau)
def pluck(f,d,tau=.25):
    x=sine(f,d)+.5*sine(2*f,d)*np.exp(-t(d)/(tau*.5))+.25*sine(3*f,d)*np.exp(-t(d)/(tau*.3))
    return x*decay(d,tau)*env(len(x),.002,.02)
def place(buf,x,at,g=1):
    i=int(at*SR); n=min(len(x),len(buf)-i)
    if n>0: buf[i:i+n]+=x[:n]*g
def reverb(x,mix=.18,size=1):
    # simple multi-tap decaying noise IR
    n=int(SR*.35*size); ir=rng.standard_normal(n)*np.exp(-np.arange(n)/(SR*.09*size)); ir=filt(ir,'low',5000)
    ir/=np.abs(ir).sum()**.5*3
    w=np.convolve(x,ir)[:len(x)]
    return x+mix*w*4
def save(name,x,peak=.72,rev=0,fade=.01):
    x=np.asarray(x,float)
    if rev: x=np.concatenate([x,np.zeros(int(SR*.3))]); x=reverb(x,rev)
    x=x-x.mean(); x=filt(x,'high',30,1)
    x=x/max(1e-9,np.abs(x).max())*peak
    nf=min(int(fade*SR),len(x)//12); x[:nf]*=np.linspace(0,1,nf); x[-nf*3:]*=np.linspace(1,0,nf*3)
    # trim trailing silence
    idx=np.where(np.abs(x)>.002)[0]; x=x[:idx[-1]+int(.02*SR)] if len(idx) else x
    with wave.open(f'{OUT}/{name}.wav','wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x*32767).astype(np.int16).tobytes())
N=lambda m:440*2**((m-69)/12)

# --- Interactions
def blop(f0=420,f1=720,d=.16,tau=.05):
    x=sweep(f0,f1,d)*decay(d,tau*1.6)*env(int(SR*d),.002,.05); return x
save('poke', blop(380,760,.17)+.25*blop(760,1500,.1,.03)[:int(SR*.17)].tolist().__len__()*0 if False else np.pad(blop(380,760,.17),0), rev=.08)
# pitch variants
for i,(a,b) in enumerate([(330,640),(450,880),(520,1040)]): save(f'poke{i+2}', blop(a,b,.16), rev=.08)

# hug: warm purr swell
d=1.6; x=(sine(N(60),d)+.5*sine(N(67),d)+.3*sine(N(72),d))*(.6+.4*sine(26,d)**2)
x*=np.sin(np.linspace(0,np.pi,len(x)))**1.5
save('hug',filt(x,'low',1800),peak=.5,rev=.12)

# eat: munch crunches + gulp
b=np.zeros(int(SR*.9))
for k,at in enumerate([0,.14,.28]):
    c=filt(noise(.06),'band' if False else 'low',3500)*decay(.06,.012)
    c=filt(c,'high',300)
    place(b,c+.5*sweep(180,110,.06)*decay(.06,.02),at,1-.15*k)
g=sweep(220,120,.14)*decay(.14,.06); g+= .6*sweep(440,240,.14)*decay(.14,.05)
place(b,g,.5,.9); place(b,sweep(300,520,.08)*decay(.08,.04),.66,.5)
save('eat',b,rev=.06)

# play: boing
d=.55; f=300+0*t(d); f=f*(1+.5*np.sin(2*np.pi*14*t(d))*np.exp(-t(d)/.18)); f=f*np.exp(t(d)*1.2)
x=sine(f,d)*decay(d,.28)+.3*sine(f*2,d)*decay(d,.15)
save('boing',x*env(len(x),.003,.1),rev=.08)

# levelUp: arpeggio + sparkle
b=np.zeros(int(SR*1.6))
for i,m in enumerate([72,76,79,84,88]): place(b,bell(N(m),.9,.5),i*.085,.8)
place(b,bell(N(91),1.0,.7),.5,.7)
for i in range(10): place(b,filt(noise(.05),'high',6000)*decay(.05,.01)*.12,.4+i*.04)
save('levelup',b,rev=.2)

# achievement chime
b=np.zeros(int(SR*1.3)); place(b,bell(N(79),1,.5),0); place(b,bell(N(86),1.1,.6),.11); place(b,bell(N(91),1.2,.7),.22,.8)
save('achievement',b,rev=.22)

# coin
b=np.zeros(int(SR*.5)); 
def sq(f,d): return np.sign(sine(f,d))*.35+sine(f,d)*.65
place(b,sq(N(83),.08)*env(int(SR*.08),.002,.03),0); place(b,sq(N(88),.35)*decay(.35,.12)*env(int(SR*.35),.002,.05),.07)
save('coin',b,peak=.55,rev=.06)

# skin change: sparkle swish
d=.7; sw=filt(noise(d),'high',2500)*np.sin(np.linspace(0,np.pi,int(SR*d)))**2*.35
b=sw.copy()
for i,m in enumerate([84,88,91,96]): place(b,bell(N(m),.5,.25),.05+i*.07,.5)
save('skin',b,rev=.2)

# equip pop
x=sweep(900,300,.09)*decay(.09,.025)+.4*filt(noise(.03),'high',2000)[:int(SR*.09)].tolist().__len__()*0 if False else sweep(900,300,.09)*decay(.09,.025)
save('equip',x*env(len(x),.001,.03),rev=.05)

# sleep: descending lullaby
b=np.zeros(int(SR*2.2))
for i,m in enumerate([76,72,67,60]): place(b,pluck(N(m),.9,.5)+.3*sine(N(m)/2,.9)*decay(.9,.4),i*.3,.9-.1*i)
save('sleep',filt(b,'low',3500),peak=.55,rev=.3)
# wake: rising yawn + chime
b=np.zeros(int(SR*1.4)); y=sweep(200,420,.7,'lin')*np.sin(np.linspace(0,np.pi,int(SR*.7)))*.5+.2*sweep(400,840,.7,'lin')*np.sin(np.linspace(0,np.pi,int(SR*.7)))
place(b,filt(y,'low',1500),0); place(b,bell(N(79),.7,.4),.65); place(b,bell(N(84),.8,.5),.8,.8)
save('wake',b,peak=.6,rev=.18)

# confetti / pomodoro done fanfare
b=np.zeros(int(SR*2.2))
for at,ms in [(0,[67,72,76]),(.18,[69,74,77]),(.36,[72,76,79,84])]:
    for m in ms: place(b,(sq(N(m),.5)*.2+bell(N(m),.5,.3)*.6)*env(int(SR*.5),.004,.2),at,.5)
place(b,bell(N(84),1.4,.9),.7,.8)
pop=filt(noise(.12),'band' if False else 'high',1500)*decay(.12,.03)
for at in [.05,.3,.6]: place(b,pop,at,.4)
save('fanfare',b,rev=.25)

# pomodoro start (soft tick-tock + chime), break start
b=np.zeros(int(SR*.9)); place(b,bell(N(72),.6,.4),0); place(b,bell(N(79),.8,.5),.13)
save('focus_start',b,peak=.55,rev=.15)
b=np.zeros(int(SR*1.2)); place(b,bell(N(79),.6,.4),0); place(b,bell(N(74),.6,.4),.18); place(b,bell(N(67),.9,.6),.36)
save('break_start',b,peak=.55,rev=.2)

# landing thuds (soft splat)
for name,f,d,tau in [('land_soft',160,.18,.05),('land_hard',95,.3,.09)]:
    x=sweep(f*1.8,f*.6,d)*decay(d,tau)+.5*filt(noise(d),'low',900)*decay(d,tau*.5)
    save(name,x*env(len(x),.001,.06),peak=.8 if 'hard' in name else .5)
# throw / drag whoosh
d=.45; x=filt(noise(d),'low',2200)*np.sin(np.linspace(0,np.pi,int(SR*d)))**2
save('whoosh',filt(x,'high',400),peak=.4)
# wall bounce
x=sweep(260,140,.12)*decay(.12,.04); save('bounce',x*env(len(x),.001,.04),peak=.5)

# hoop
b=np.zeros(int(SR*.6)); n=filt(noise(.5),'high',3500)*np.sin(np.linspace(0,np.pi,int(SR*.5)))**1.5*.4
place(b,n,0); place(b,bell(N(86),.4,.15),.04,.5)
save('swish',b,peak=.6,rev=.08)
x=bell(N(77),.35,.1,1.5)+.6*filt(noise(.04),'high',3000)[:1].tolist().__len__()*0 if False else bell(N(77),.35,.1,1.5)
save('rim',x,peak=.55,rev=.05)
b=np.zeros(int(SR*.7)); place(b,sweep(520,170,.5)*decay(.5,.2)*env(int(SR*.5),.005,.2),0)
save('miss',filt(b,'low',2500),peak=.5,rev=.1)
b=np.zeros(int(SR*.9)); 
for i,m in enumerate([79,84,88]): place(b,bell(N(m),.5,.3),i*.07,.7)
save('streak',b,peak=.6,rev=.15)
# ball bounce on ground (hoop launch)
x=sweep(330,190,.1)*decay(.1,.03)+.3*filt(noise(.05),'low',1200)[:1].tolist().__len__()*0 if False else sweep(330,190,.1)*decay(.1,.03); save('launch',x*env(len(x),.001,.03),peak=.5)

# UI
x=sine(1800,.05)*decay(.05,.008)+.3*sine(3600,.05)*decay(.05,.005); save('tick',x,peak=.35)
b=np.zeros(int(SR*.4)); place(b,bell(N(84),.3,.12),0); place(b,bell(N(91),.3,.15),.06,.8); save('toast',b,peak=.45,rev=.08)
b=np.zeros(int(SR*.6)); place(b,bell(N(79),.5,.3),0); place(b,bell(N(79),.5,.3),.25); place(b,bell(N(86),.8,.4),.5)
save('reminder',b[:int(SR*1.4)] if len(b)>int(SR*1.4) else np.pad(b,(0,int(SR*1.4)-len(b))),peak=.65,rev=.2)
# stomach growl
d=.8; f=70+25*np.sin(2*np.pi*3*t(d)); x=filt(noise(d),'low',260,3)*(.5+.5*np.sin(2*np.pi*5*t(d)))+.5*sine(f,d)
x*=np.sin(np.linspace(0,np.pi,len(x)))
save('growl',x,peak=.55)
# battery low (sad descending), overheat (hiss + warble)
b=np.zeros(int(SR*1)); place(b,bell(N(67),.5,.3),0); place(b,bell(N(62),.6,.35),.2); place(b,bell(N(55),.9,.5),.42); save('battery',b,peak=.5,rev=.15)
d=1.0; h=filt(noise(d),'high',4000)*np.sin(np.linspace(0,np.pi,int(SR*d)))*.3; w=sine(700+80*np.sin(2*np.pi*9*t(d)),d)*.25*np.sin(np.linspace(0,np.pi,int(SR*d)))
save('hot',h+w,peak=.45)
# music/headphones reactions
b=np.zeros(int(SR*.8)); place(b,pluck(N(72),.4,.2),0); place(b,pluck(N(76),.4,.2),.1); place(b,pluck(N(79),.5,.25),.2); save('music',b,peak=.55,rev=.12)
b=np.zeros(int(SR*.5)); place(b,bell(N(84),.3,.15),0); place(b,bell(N(88),.3,.2),.08); save('headphones',b,peak=.5,rev=.08)
d=.075; x=(sine(560,d)+.3*sine(1120,d))*np.sin(np.linspace(0,np.pi,int(SR*d)))**1.5; save('talk',filt(x,'low',3000),peak=.4)
# camera shutter
b=np.zeros(int(SR*.3)); place(b,filt(noise(.02),'high',2000)*decay(.02,.006),0); place(b,filt(noise(.04),'high',1200)*decay(.04,.01),.08,.8); save('shutter',b,peak=.5)
# hungry/eat coin purchase fail
b=np.zeros(int(SR*.3)); place(b,sine(180,.12)*decay(.12,.05)+.3*sine(150,.12)*decay(.12,.05),0); place(b,sine(140,.15)*decay(.15,.06),.1); save('deny',b,peak=.45)

# --- Seasonal stingers
b=np.zeros(int(SR*2.4))  # Noel: sleigh bells + carol
for i,m in enumerate([79,79,79]): place(b,bell(N(m+12),.6,.35,1.6),i*.16,.5)
for i in range(14): place(b,filt(noise(.08),'high',5500)*decay(.08,.02)*(np.sin(2*np.pi*(3000+rng.integers(0,900))*t(.08))),.0+i*.07,.18)
place(b,bell(N(84),1.4,.9),.55,.7); place(b,bell(N(88),1.4,.9),.7,.55); place(b,bell(N(91),1.6,1),.85,.55)
save('season_noel',b,peak=.6,rev=.3)
b=np.zeros(int(SR*2.6))  # Halloween: eerie
sw=sweep(220,180,2.4,'lin')*(1+.3*sine(5.5,2.4)); env2=np.sin(np.linspace(0,np.pi,len(sw)))**2
b[:len(sw)]+=.35*sw*env2
b[:len(sw)]+=.2*sweep(233*1.5,233*1.41,2.4,'lin')*env2
place(b,bell(N(66),1.2,.7,.6),.3,.5); place(b,bell(N(59),1.4,.9,.6),.9,.5)
for at in [1.2,1.45,1.6]: place(b,filt(noise(.1),'band' if False else 'high',3500)*decay(.1,.03)*.3,at)
save('season_halloween',filt(b,'low',4000),peak=.55,rev=.35)
b=np.zeros(int(SR*2.2))  # Sakura: koto pentatonic
for i,m in enumerate([76,79,83,79,86,83]): place(b,pluck(N(m),1.0,.4),i*.17,.8)
place(b,pluck(N(88),1.4,.6),1.1,.7)
save('season_sakura',b,peak=.6,rev=.25)
b=np.zeros(int(SR*2.6))  # Ete/Ocean: wave + steel drum
d=2.2; wv=filt(noise(d),'low',1400)*(np.sin(np.linspace(0,np.pi,int(SR*d)))**2)*.5
wv+=filt(noise(d),'high',3000)*(np.sin(np.linspace(.4,np.pi+.4,int(SR*d)))**3).clip(0)*.12
b[:len(wv)]+=wv
for i,m in enumerate([72,76,79,76,84]): place(b,bell(N(m),.5,.22,.5)*1.0,.6+i*.2,.5)
save('season_ete',b,peak=.55,rev=.2)
print(sorted(os.listdir(OUT)))
