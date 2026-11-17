import sys,os
sys.path.insert(0,os.path.dirname(__file__))
import defs as d
from defs import *
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen
OUT=sys.argv[1]; FDIR=os.path.join(os.path.dirname(__file__),"..","fonts")
FONTS=[("Inter ExtraBold",FD+"Inter-ExtraBold.otf","Same family as the wordmark"),
       ("Poppins Bold",FDIR+"/Poppins-Bold.ttf","Round geometric, friendly"),
       ("Montserrat ExtraBold",FDIR+"/Montserrat-ExtraBold.ttf","Wide and confident"),
       ("Archivo Black",FDIR+"/ArchivoBlack-Regular.ttf","Heaviest, strongest at small sizes"),
       ("Space Grotesk Bold",FDIR+"/SpaceGrotesk-Bold.ttf","Techy, distinctive S curve"),
       ("Playfair Display ExtraBold",FDIR+"/Playfair-ExtraBold.ttf","Serif, premium and traditional retail"),
       ("Zilla Slab Bold",FDIR+"/ZillaSlab-Bold.ttf","Slab serif, like a shop sign")]
def spath(fp,h=14.5,cx=50,cy=76.2):
    f=TTFont(fp); gs=f.getGlyphSet(); gn=f.getBestCmap()[ord("S")]
    bp=BoundsPen(gs); gs[gn].draw(bp); x0,y0,x1,y1=bp.bounds
    sc=h/(y1-y0); xc,yc=(x0+x1)/2,(y0+y1)/2
    pen=SVGPathPen(gs,ntos=lambda v:f"{v:.2f}"); gs[gn].draw(TransformPen(pen,(sc,0,0,-sc,cx-sc*xc,cy+sc*yc))); return pen.getCommands()
SCH={'light':(RED,INK,WHITE),'dark':(WHITE,LRED,DARK),'icon':(WHITE,INK,WHITE)}
d.SCHEME['light']=d.SCHEME['light']
cur=[None]
def mark4(sc):
    cm,cb,cs=SCH[sc]
    return (f'<path d="M20 84V20L50 56L80 20V84" fill="none" stroke="{cm}" stroke-width="12" stroke-linejoin="round" stroke-linecap="round"/>'
            f'<rect x="38" y="64" width="24" height="24" rx="6" fill="{cb}"/><path d="{cur[0]}" fill="{cs}"/>')
d.mark=lambda n,sc,bg=True: mark4(sc)
def icon(): return f'<rect width="100" height="100" rx="22" fill="{RED}"/><g transform="translate(15 15) scale(.7)">{mark4("icon")}</g>'
CW,CH,pad,cols=640,330,40,2; rows=4; SW=pad+cols*(CW+pad); SH=110+rows*(CH+pad)
P=[f'<rect width="{SW}" height="{SH}" fill="#EFEBE8"/>',f'<text x="{pad}" y="52" font-family="Inter, Arial, sans-serif" font-size="26" font-weight="800" fill="{INK}">S typeface options</text>',
   f'<text x="{pad}" y="78" font-family="Inter, Arial, sans-serif" font-size="14" fill="#6D6763">Same M, badge and colours. Only the S in the black square changes.</text>']
for i,(nm,fp,note) in enumerate(FONTS):
    cur[0]=spath(fp); slug=f"{i+1:02d}-"+nm.lower().replace(" ","-")
    b,w=d.lockup_body(4,'light',24,24); open(f"{OUT}/{slug}-lockup.svg","w").write(d.svg(b,int(w+48),112))
    open(f"{OUT}/{slug}-mark.svg","w").write(d.svg(mark4('light'),100,100)); open(f"{OUT}/{slug}-app-icon.svg","w").write(d.svg(icon(),100,100))
    x=pad+(i%cols)*(CW+pad); y=110+(i//cols)*(CH+pad)
    P.append(f'<g transform="translate({x} {y})"><rect width="{CW}" height="{CH}" rx="18" fill="{WHITE}"/><text x="24" y="38" font-family="Inter, Arial, sans-serif" font-size="16" font-weight="800" fill="{INK}">{i+1} · {nm}</text><text x="24" y="58" font-family="Inter, Arial, sans-serif" font-size="12" fill="#6D6763">{note}</text>')
    bd,w=d.lockup_body(4,'light',0,0,72); P.append(f'<g transform="translate({(CW-w)/2} 86)">{bd}</g>')
    b2,w2=d.lockup_body(4,'dark',0,0,34)
    P.append(f'<rect x="24" y="190" width="300" height="116" rx="14" fill="{DARK}"/><g transform="translate({24+(300-w2)/2} {190+41})">{b2}</g>')
    P.append(f'<g transform="translate(340 190)"><rect width="116" height="116" rx="14" fill="{BGL}" stroke="#ECE7E4"/><g transform="translate(18 18) scale(.8)">{mark4("light")}</g></g><g transform="translate(472 190)"><g transform="scale(1.16)">{icon()}</g></g></g>')
open(f"{OUT}/00-overview.svg","w").write(d.svg("".join(P),SW,SH)); print("ok")
