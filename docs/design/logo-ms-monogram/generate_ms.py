import sys,os,json
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import defs as d
from defs import RED,INK,WHITE,DARK
D=sys.argv[1]
T=json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),"ms_trace.json")))
x0,y0,x1,y1=T["bbox"]; MW,MH=x1-x0,y1-y0
d.SCHEME['monob']=dict(c1=INK,c2=INK,a=INK,b=INK); d.SCHEME['monow']=dict(c1=WHITE,c2=WHITE,a=WHITE,b=WHITE)
COL={'light':(RED,INK),'dark':(RED,WHITE),'red':(WHITE,INK),'monob':(INK,INK),'monow':(WHITE,WHITE),'tile':(RED,INK)}
def mark(sc,x=0,y=0,h=100):
    r,k=COL[sc]; s=h/MH
    return (f'<g transform="translate({x} {y}) scale({s:.5f}) translate({-x0:.3f} {-y0:.3f})">'
            f'<path d="{T["red"]}" fill="{r}" fill-rule="evenodd"/><path d="{T["black"]}" fill="{k}" fill-rule="evenodd"/></g>')
def svg(body,w,h,bg=None):
    b=f'<rect width="{w}" height="{h}" fill="{bg}"/>' if bg else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{b}{body}</svg>'
def wr(p,s): open(p,"w").write(s)
jobs=[]
def add(n,out,w): jobs.append(dict(svg=n,png=out,w=w))
def G(n,b): return f'<g id="{n}">{b}</g>'
# marks (tight crop + 2px padding in design units)
P=2
for sc,nm in (('light','mark'),('dark','mark-reversed'),('red','mark-on-red'),('monob','mark-mono-black'),('monow','mark-mono-white')):
    wr(f"{D}/svg/ms-{nm}.svg",svg(mark(sc,P,P,MH),int(MW+2*P),int(MH+2*P))); add(f"ms-{nm}",f"png/mark/ms-{nm}.png",1024)
# lockups
LK={'light':'lockup','dark':'lockup-reversed','red':'lockup-on-red','monob':'lockup-mono-black','monow':'lockup-mono-white'}
for sc,nm in LK.items():
    paths,w,ch=d.word(4,sc); ms=64; mw=ms*MW/MH; gap=18; X=24; Y=24
    body=mark(sc,X,Y,ms)+f'<g transform="translate({X+mw+gap:.2f} {Y+ms/2+ch/2:.2f})"><path d="{paths[0][0]}" fill="{paths[0][1]}"/><path d="{paths[1][0]}" fill="{paths[1][1]}"/></g>'
    wr(f"{D}/svg/ms-{nm}.svg",svg(body,int(mw+gap+w+48),112)); add(f"ms-{nm}",f"png/lockup/ms-{nm}.png",1600)
    nm2=nm.replace('lockup','stacked'); ms=96; mw=ms*MW/MH; W=int(max(w,mw)+96); base=24+ms+24+ch
    body=mark(sc,(W-mw)/2,24,ms)+f'<g transform="translate({(W-w)/2:.2f} {base:.2f})"><path d="{paths[0][0]}" fill="{paths[0][1]}"/><path d="{paths[1][0]}" fill="{paths[1][1]}"/></g>'
    wr(f"{D}/svg/ms-{nm2}.svg",svg(body,W,int(base+30))); add(f"ms-{nm2}",f"png/lockup/ms-{nm2}.png",1200)
# tiles / icons: monogram centred on a tile
def tile(shape,bg,sc,k=.72):
    mw=100*k; mh=mw*MH/MW
    if mh>100*k: mh=100*k; mw=mh*MW/MH
    bgsh={'rounded':f'<rect width="100" height="100" rx="24" fill="{bg}"/>','square':f'<rect width="100" height="100" fill="{bg}"/>','round':f'<circle cx="50" cy="50" r="50" fill="{bg}"/>'}[shape]
    return svg(bgsh+mark(sc,(100-mw)/2,(100-mh)/2+1,mh),100,100)
wr(f"{D}/svg/ms-app-icon.svg",tile('rounded',WHITE,'light')); wr(f"{D}/svg/ms-app-icon-square.svg",tile('square',WHITE,'light')); wr(f"{D}/svg/ms-app-icon-round.svg",tile('round',WHITE,'light'))
wr(f"{D}/svg/ms-app-icon-red.svg",tile('rounded',RED,'red')); wr(f"{D}/svg/ms-app-icon-red-square.svg",tile('square',RED,'red'))
wr(f"{D}/svg/ms-header-tile.svg",tile('rounded',WHITE,'light',.78))
for n,px in (("ms-app-icon",1024),("ms-app-icon",512),("ms-app-icon-square",1024),("ms-app-icon-red",1024)): add(n,f"png/app-icon/{n}-{px}.png",px)
for px in (32,48,64,96,128,192,512,1024): add("ms-header-tile",f"png/header-tile/ms-header-tile-{px}.png",px)
for k,px in (("1.0x",36),("2.0x",72),("3.0x",108)):
    os.makedirs(f"{D}/png/header-tile/flutter/{k}",exist_ok=True); add("ms-header-tile",f"png/header-tile/flutter/{k}/ms_header_tile.png",px)
for dn,px in {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}.items():
    os.makedirs(f"{D}/png/android/mipmap-{dn}",exist_ok=True); add("ms-app-icon",f"png/android/mipmap-{dn}/ic_launcher.png",px); add("ms-app-icon-round",f"png/android/mipmap-{dn}/ic_launcher_round.png",px)
mw=108*.42*MW/MH*1.0; mh=108*.42
fg=svg(mark('light',(108-mw)/2,(108-mh)/2,mh),108,108)
wr(f"{D}/svg/android-adaptive-foreground.svg",fg); wr(f"{D}/svg/android-adaptive-background.svg",svg(f'<rect width="108" height="108" fill="{WHITE}"/>',108,108))
add("android-adaptive-foreground","png/android/ic_launcher_foreground-432.png",432); add("android-adaptive-background","png/android/ic_launcher_background-432.png",432)
for px in (1024,180,167,152,120,87,80,76,60,58,40,29,20): add("ms-app-icon-square",f"png/ios/AppIcon-{px}.png",px)
for px,nm in ((16,'favicon-16'),(32,'favicon-32'),(48,'favicon-48'),(180,'apple-touch-icon'),(192,'icon-192'),(512,'icon-512')): add("ms-app-icon",f"png/web/{nm}.png",px)
wr(f"{D}/manifest.json",json.dumps(jobs)); print(len(jobs))
