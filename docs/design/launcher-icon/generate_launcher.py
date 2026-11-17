import json,os,sys
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import launcher as L
here=os.path.dirname(os.path.abspath(__file__))
L.T=json.load(open(os.path.join(here,"ms_trace.json")))
L.x0,L.y0,L.x1,L.y1=L.T["bbox"]; L.MW,L.MH=L.x1-L.x0,L.y1-L.y0
D=sys.argv[1]; B=dict(fit=.86,wst=4,bst=3)
def wr(n,s): open(f"{D}/svg/{n}.svg","w").write(s)
wr("launcher-icon",L.icon("rounded",**B)); wr("launcher-icon-square",L.icon("square",**B)); wr("launcher-icon-round",L.icon("round",fit=.72,wst=4,bst=3))
wr("adaptive-foreground",L.icon(frame=108,adaptive=True,fit=.58,wst=4,bst=3))
wr("adaptive-background",f'<svg xmlns="http://www.w3.org/2000/svg" width="108" height="108" viewBox="0 0 108 108"><rect width="108" height="108" fill="{L.RED}"/></svg>')
wr("adaptive-monochrome",L.icon(frame=108,adaptive=True,fit=.58,wst=4,bst=3,fg="#000000",k="#000000"))
jobs=[]
def add(n,out,w): jobs.append(dict(svg=n,png=out,w=w))
for dn,px in {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}.items():
    os.makedirs(f"{D}/png/android/mipmap-{dn}",exist_ok=True)
    add("launcher-icon",f"png/android/mipmap-{dn}/ic_launcher.png",px); add("launcher-icon-round",f"png/android/mipmap-{dn}/ic_launcher_round.png",px)
for n,o in (("adaptive-foreground","ic_launcher_foreground"),("adaptive-background","ic_launcher_background"),("adaptive-monochrome","ic_launcher_monochrome")): add(n,f"png/android/{o}-432.png",432)
add("launcher-icon-square","png/android/play-store-icon-512.png",512)
for px in (1024,180,167,152,120,87,80,76,60,58,40,29,20): add("launcher-icon-square",f"png/ios/AppIcon-{px}.png",px)
for px,nm in ((16,'favicon-16'),(32,'favicon-32'),(48,'favicon-48'),(180,'apple-touch-icon'),(192,'icon-192'),(512,'icon-512')): add("launcher-icon",f"png/web/{nm}.png",px)
add("launcher-icon","launcher-icon-1024.png",1024)
open(f"{D}/manifest.json","w").write(json.dumps(jobs)); print(len(jobs))
