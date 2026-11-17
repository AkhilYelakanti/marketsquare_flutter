import sys,os,json
sys.path.insert(0,os.path.dirname(__file__))
import defs as d
from defs import *
D=sys.argv[1]
SC="M58 70C58 64 42 64 42 71C42 77 58 76 58 83C58 90 42 90 42 84"
SCH={'light':(RED,INK,WHITE),'dark':(WHITE,LRED,DARK),'red':(WHITE,PINK,RED),'monob':(INK,INK,None),'monow':(WHITE,WHITE,None)}
d.SCHEME['monob']=dict(c1=INK,c2=INK,a=INK,b=INK); d.SCHEME['monow']=dict(c1=WHITE,c2=WHITE,a=WHITE,b=WHITE)
def mark4(sc,badge=True):
    cm,cb,cs=SCH[sc]
    m=f'<path d="M20 84V20L50 56L80 20V84" fill="none" stroke="{cm}" stroke-width="12" stroke-linejoin="round" stroke-linecap="round"/>'
    sp=f'<path d="{SC}" fill="none" stroke="{{c}}" stroke-width="6.5" stroke-linecap="round" transform="translate(50 76.5) scale(.5) translate(-50 -77)"/>'
    if cs is None:
        return (f'<defs><mask id="ks"><rect x="38" y="64" width="24" height="24" fill="#fff"/>{sp.format(c="#000")}</mask></defs>'
                +m+f'<rect x="38" y="64" width="24" height="24" rx="6" fill="{cb}" mask="url(#ks)"/>')
    return m+f'<rect x="38" y="64" width="24" height="24" rx="6" fill="{cb}"/>'+sp.format(c=cs)
d.mark=lambda n,sc,bg=True: mark4(sc)
def wr(path,s): open(path,"w").write(s)
jobs=[]
def add(svgname,pngpath,w,bg=None): jobs.append(dict(svg=svgname,png=pngpath,w=w,bg=bg))
# lockups
LK={'light':'lockup','dark':'lockup-reversed','red':'lockup-on-red','monob':'lockup-mono-black','monow':'lockup-mono-white'}
for sc,nm in LK.items():
    b,w=d.lockup_body(4,sc,24,24); wr(f"{D}/svg/marketsquare-{nm}.svg",d.svg(b,int(w+48),112)); add(f"marketsquare-{nm}",f"png/lockup/marketsquare-{nm}.png",1600)
# stacked
for sc,nm in LK.items():
    nm=nm.replace('lockup','stacked'); paths,w,ch=d.word(4,sc); ms=88; W=int(max(w,ms)+96); base=24+ms+22+ch
    body=f'<g transform="translate({(W-ms)/2} 24) scale({ms/100})">{mark4(sc)}</g><g transform="translate({(W-w)/2} {base})"><path d="{paths[0][0]}" fill="{paths[0][1]}"/><path d="{paths[1][0]}" fill="{paths[1][1]}"/></g>'
    H=int(base+30); wr(f"{D}/svg/marketsquare-{nm}.svg",d.svg(body,W,H)); add(f"marketsquare-{nm}",f"png/lockup/marketsquare-{nm}.png",1200)
# marks
for sc,nm in {'light':'mark','dark':'mark-reversed','monob':'mark-mono-black','monow':'mark-mono-white'}.items():
    wr(f"{D}/svg/marketsquare-{nm}.svg",d.svg(mark4(sc),100,100)); add(f"marketsquare-{nm}",f"png/mark/marketsquare-{nm}.png",1024)
# app icons
def icon(shape,sz=100,k=.70):
    off=(100-100*k)/2; inner=f'<g transform="translate({off} {off}) scale({k})">{mark4("red")}</g>'
    bg={'rounded':f'<rect width="100" height="100" rx="22" fill="{RED}"/>','square':f'<rect width="100" height="100" fill="{RED}"/>','round':f'<circle cx="50" cy="50" r="50" fill="{RED}"/>'}[shape]
    return d.svg(bg+inner,100,100)
wr(f"{D}/svg/marketsquare-app-icon.svg",icon('rounded')); wr(f"{D}/svg/marketsquare-app-icon-square.svg",icon('square')); wr(f"{D}/svg/marketsquare-app-icon-round.svg",icon('round'))
add("marketsquare-app-icon","png/app-icon/marketsquare-app-icon-1024.png",1024); add("marketsquare-app-icon","png/app-icon/marketsquare-app-icon-512.png",512)
add("marketsquare-app-icon-square","png/app-icon/marketsquare-app-icon-square-1024.png",1024)
# android
for dn,px in {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}.items():
    os.makedirs(f"{D}/png/android/mipmap-{dn}",exist_ok=True)
    add("marketsquare-app-icon",f"png/android/mipmap-{dn}/ic_launcher.png",px); add("marketsquare-app-icon-round",f"png/android/mipmap-{dn}/ic_launcher_round.png",px)
fg=d.svg(f'<g transform="translate(24 24) scale(.6)">{mark4("red")}</g>',108,108)
wr(f"{D}/svg/android-adaptive-foreground.svg",fg); wr(f"{D}/svg/android-adaptive-background.svg",d.svg(f'<rect width="108" height="108" fill="{RED}"/>',108,108))
add("android-adaptive-foreground","png/android/ic_launcher_foreground-432.png",432); add("android-adaptive-background","png/android/ic_launcher_background-432.png",432)
add("android-adaptive-foreground","png/android/play-store-icon-512-source.png",512) if False else None
# ios (opaque square)
for px in (1024,180,167,152,120,87,80,76,60,58,40,29,20): add("marketsquare-app-icon-square",f"png/ios/AppIcon-{px}.png",px)
# web
for px,nm in ((16,'favicon-16'),(32,'favicon-32'),(48,'favicon-48'),(180,'apple-touch-icon'),(192,'icon-192'),(512,'icon-512')):
    add("marketsquare-app-icon",f"png/web/{nm}.png",px)
wr(f"{D}/manifest.json",json.dumps(jobs)); print(len(jobs))
