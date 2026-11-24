import sys,os,json
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen
here=os.path.dirname(os.path.abspath(__file__)); D=sys.argv[1]
RED="#DB2031"; INK="#1D1B1A"; WHITE="#FFFFFF"
FONT=TTFont(os.path.join(here,"ArchivoBlack-Regular.ttf")); GS=FONT.getGlyphSet(); CM=FONT.getBestCmap()
# isometric cube geometry (viewBox units)
A=(15,35); E1=(85,25); E2=(85,-25); EV=(0,115)
B=(A[0]+E2[0],A[1]+E2[1]); F=(A[0]+E1[0],A[1]+E1[1]); R=(A[0]+E1[0]+E2[0],A[1]+E1[1]+E2[1])
def P(o,eu,ev,u,v): return (o[0]+eu[0]*u+ev[0]*v, o[1]+eu[1]*u+ev[1]*v)
def _b(ch):
    bp=BoundsPen(GS); GS[CM[ord(ch)]].draw(bp); return bp.bounds
_bc,_bx=_b("C"),_b("X")
# one shared scale (px per font unit) so both letters match, capped to 76% of the face width
K=min(.76*E1[0]/max(_bc[2]-_bc[0],_bx[2]-_bx[0]), .66*EV[1]/max(_bc[3]-_bc[1],_bx[3]-_bx[1]))
def glyph(ch,o,eu,ev,vc=.56):
    gn=CM[ord(ch)]; x0,y0,x1,y1=_b(ch)
    Wpx=(x1-x0)*K; Hpx=(y1-y0)*K; hfrac=Hpx/ev[1]
    kv=hfrac/(y1-y0); ku=(Wpx/eu[0])/(x1-x0)
    ul=.5-(Wpx/eu[0])/2; vb=vc+hfrac/2
    a=eu[0]*ku; c=-ev[0]*kv; e=o[0]+eu[0]*(ul-x0*ku)+ev[0]*(vb+y0*kv)
    b=eu[1]*ku; d=-ev[1]*kv; f=o[1]+eu[1]*(ul-x0*ku)+ev[1]*(vb+y0*kv)
    pen=SVGPathPen(GS,ntos=lambda v:f"{v:.2f}"); GS[gn].draw(TransformPen(pen,(a,b,c,d,e,f))); return pen.getCommands()
CP=glyph("C",A,E1,EV); XP=glyph("X",F,E2,EV)
def poly(pts): return "M"+"L".join(f"{x:.2f} {y:.2f}" for x,y in pts)+"Z"
t0,t1=.42,.58
tape_top=poly([P(A,E1,E2,0,t0),P(A,E1,E2,1,t0),P(A,E1,E2,1,t1),P(A,E1,E2,0,t1)])
tail=poly([P(F,E2,EV,t0,0),P(F,E2,EV,t1,0),P(F,E2,EV,t1,.17),P(F,E2,EV,.545,.135),P(F,E2,EV,.51,.18),P(F,E2,EV,.475,.135),P(F,E2,EV,t0,.17)])
Ap=P(A,(0,0),EV,0,1); Fp=P(F,(0,0),EV,0,1); Rp=P(R,(0,0),EV,0,1)
def cube(line,tapec,cc,xc,sw=8,ink=None):
    hexa=poly([A,B,R,Rp,Fp,Ap])
    inner=f'M{A[0]} {A[1]}L{F[0]} {F[1]}L{R[0]} {R[1]}M{F[0]} {F[1]}L{Fp[0]} {Fp[1]}'
    return (f'<path d="{hexa}" fill="none" stroke="{line}" stroke-width="{sw}" stroke-linejoin="round"/>'
            f'<path d="{inner}" fill="none" stroke="{line}" stroke-width="{sw*.75:.2f}" stroke-linejoin="round" stroke-linecap="round"/>'
            f'<path d="{tape_top}" fill="{tapec}"/><path d="{tail}" fill="{tapec}"/>'
            f'<path d="{CP}" fill="{cc}"/><path d="{XP}" fill="{xc}"/>')
VB=(5,2,190,182)  # x,y,w,h
COL={'light':(RED,RED,RED,INK),'dark':(RED,RED,RED,WHITE),'red':(WHITE,WHITE,WHITE,INK),'monob':(INK,INK,INK,INK),'monow':(WHITE,WHITE,WHITE,WHITE)}
def svg(body,w,h,vb=None): 
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{vb or f"0 0 {w} {h}"}">{body}</svg>'
def wr(n,s): open(f"{D}/svg/{n}.svg","w").write(s)
jobs=[]
def add(n,out,w): jobs.append(dict(svg=n,png=out,w=w))
for sc,nm in (('light','mark'),('dark','mark-reversed'),('red','mark-on-red'),('monob','mark-mono-black'),('monow','mark-mono-white')):
    wr(f"cx-{nm}",svg(cube(*COL[sc]),VB[2]*4,VB[3]*4,f"{VB[0]} {VB[1]} {VB[2]} {VB[3]}")); add(f"cx-{nm}",f"png/mark/cx-{nm}.png",1024)
def tile(shape,bg,sc,fit=.84,sw=8):
    s=min(fit*100/VB[2],fit*100/VB[3]); w,h=VB[2]*s,VB[3]*s; ox,oy=(100-w)/2,(100-h)/2
    sh={'rounded':f'<rect width="100" height="100" rx="22" fill="{bg}"/>','square':f'<rect width="100" height="100" fill="{bg}"/>','round':f'<circle cx="50" cy="50" r="50" fill="{bg}"/>'}[shape]
    return svg(sh+f'<g transform="translate({ox:.3f} {oy:.3f}) scale({s:.5f}) translate({-VB[0]} {-VB[1]})">{cube(*COL[sc],sw=sw)}</g>',100,100)
wr("cx-launcher-icon",tile('rounded',RED,'red',.86,9)); wr("cx-launcher-icon-square",tile('square',RED,'red',.86,9)); wr("cx-launcher-icon-round",tile('round',RED,'red',.72,9))
wr("cx-icon-white",tile('rounded',WHITE,'light',.84,8)); wr("cx-header-tile",tile('rounded',WHITE,'light',.80,8))
for n,px in (("cx-launcher-icon",1024),("cx-launcher-icon",512),("cx-launcher-icon-square",1024),("cx-icon-white",1024)): add(n,f"png/app-icon/{n}-{px}.png",px)
for px in (32,48,64,96,128,192,512,1024): add("cx-header-tile",f"png/header-tile/cx-header-tile-{px}.png",px)
for k,px in (("1.0x",36),("2.0x",72),("3.0x",108)):
    os.makedirs(f"{D}/png/header-tile/flutter/{k}",exist_ok=True); add("cx-header-tile",f"png/header-tile/flutter/{k}/cx_header_tile.png",px)
for dn,px in {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}.items():
    os.makedirs(f"{D}/png/android/mipmap-{dn}",exist_ok=True); add("cx-launcher-icon",f"png/android/mipmap-{dn}/ic_launcher.png",px); add("cx-launcher-icon-round",f"png/android/mipmap-{dn}/ic_launcher_round.png",px)
s=.58*108/VB[2]; fg=svg(f'<g transform="translate({(108-VB[2]*s)/2:.3f} {(108-VB[3]*s)/2:.3f}) scale({s:.5f}) translate({-VB[0]} {-VB[1]})">{cube(*COL["red"],sw=9)}</g>',108,108)
wr("cx-adaptive-foreground",fg); wr("cx-adaptive-background",svg(f'<rect width="108" height="108" fill="{RED}"/>',108,108))
add("cx-adaptive-foreground","png/android/ic_launcher_foreground-432.png",432); add("cx-adaptive-background","png/android/ic_launcher_background-432.png",432); add("cx-launcher-icon-square","png/android/play-store-icon-512.png",512)
for px in (1024,180,167,152,120,87,80,76,60,58,40,29,20): add("cx-launcher-icon-square",f"png/ios/AppIcon-{px}.png",px)
for px,nm in ((16,'favicon-16'),(32,'favicon-32'),(48,'favicon-48'),(180,'apple-touch-icon'),(192,'icon-192'),(512,'icon-512')): add("cx-launcher-icon",f"png/web/{nm}.png",px)
open(f"{D}/manifest.json","w").write(json.dumps(jobs)); print(len(jobs))
