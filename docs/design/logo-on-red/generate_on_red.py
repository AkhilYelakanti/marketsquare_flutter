import sys,os
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen
OUT=sys.argv[1]; FONT=sys.argv[2]
HR="#DB2031"; INK="#1D1B1A"; WHITE="#FFFFFF"
def spath(h=14.5,cx=50,cy=76.2,scale=1.0):
    f=TTFont(FONT); gs=f.getGlyphSet(); gn=f.getBestCmap()[ord("S")]
    bp=BoundsPen(gs); gs[gn].draw(bp); x0,y0,x1,y1=bp.bounds
    sc=h*scale/(y1-y0); xc,yc=(x0+x1)/2,(y0+y1)/2
    pen=SVGPathPen(gs,ntos=lambda v:f"{v:.2f}"); gs[gn].draw(TransformPen(pen,(sc,0,0,-sc,cx-sc*xc,cy+sc*yc))); return pen.getCommands()
SP=spath()
_id=[0]
def mark(cm,cb,cs,knock=False,thick=12,badge=True):
    """100x100 grid mark. cs None + knock -> S cut out of badge."""
    m=f'<path d="M20 84V20L50 56L80 20V84" fill="none" stroke="{cm}" stroke-width="{thick}" stroke-linejoin="round" stroke-linecap="round"/>'
    if not badge: return m
    if knock:
        _id[0]+=1; i=f"k{_id[0]}"
        return (f'<defs><mask id="{i}"><rect x="38" y="64" width="24" height="24" fill="#fff"/><path d="{SP}" fill="#000"/></mask></defs>'
                +m+f'<rect x="38" y="64" width="24" height="24" rx="6" fill="{cb}" mask="url(#{i})"/>')
    return m+f'<rect x="38" y="64" width="24" height="24" rx="6" fill="{cb}"/><path d="{SP}" fill="{cs}"/>'
def place(x,y,size,body,tile=None):
    g=f'<g transform="translate({x} {y}) scale({size/100})">'
    if tile: g+=f'<rect width="100" height="100" rx="24" fill="{tile}"/><g transform="translate(14 13) scale(.72)">{body}</g>'
    else: g+=body
    return g+'</g>'
FONTS='font-family="Inter, Arial, sans-serif"'
def bar(bg,fg,left,right=None,title="SETUP/RESET DEVICE",sub="MS ORDERING",line=None):
    s=f'<rect width="360" height="60" fill="{bg}"/>'
    if line: s+=f'<rect y="59" width="360" height="1" fill="{line}"/>'
    s+=f'<text x="180" y="20" text-anchor="middle" {FONTS} font-size="11" font-weight="500" fill="{fg}">{sub}</text><text x="180" y="42" text-anchor="middle" {FONTS} font-size="17" font-weight="600" fill="{fg}">{title}</text>'
    return s+left+(right or "")
L=(12,16,28)
opts=[]
# 0 current
cur=mark(WHITE,INK,WHITE)
opts.append(("Current","White M with black badge. At 28dp the badge is a dot and the S disappears.",
  bar(HR,WHITE,place(*L,cur),place(320,16,28,cur)), place(0,0,100,cur), HR))
# A white tile
A=mark(HR,INK,WHITE)
opts.append(("A · White tile","The full-colour mark on a white tile. Same logo as everywhere else, best contrast, S stays readable.",
  bar(HR,WHITE,place(12,14,32,A,tile=WHITE),place(316,14,32,A,tile=WHITE)), place(0,0,100,A,tile=WHITE), HR))
# B knockout mono
B=mark(WHITE,WHITE,None,knock=True)
opts.append(("B · White knockout","All white, S cut out of the badge so the red shows through. Cleanest, but the S is small.",
  bar(HR,WHITE,place(*L,B),place(320,16,28,B)), place(0,0,100,B), HR))
# C simplified small
C=mark(WHITE,None,None,badge=False,thick=14)
opts.append(("C · M only at small sizes","Header cut: heavy white M, no badge. Keep the badge for 48dp and larger.",
  bar(HR,WHITE,place(*L,C),place(320,16,28,C)), place(0,0,100,C), HR))
# D header lockup
def wm(x,y,size,fill):
    return f'<text x="{x}" y="{y}" {FONTS} font-size="{size}" font-weight="800" fill="{fill}">Market<tspan font-weight="500">Square</tspan></text>'
D_left=place(12,14,32,A,tile=WHITE)+wm(50,36,16,WHITE)
D=f'<rect width="360" height="60" fill="{HR}"/>'+D_left+f'<text x="348" y="36" text-anchor="end" {FONTS} font-size="13" font-weight="600" fill="{WHITE}">SETUP/RESET</text>'
opts.append(("D · Tile + name","Tile plus the wordmark in the header, no logo on the right. Screen title moves to the right.",
  D, place(0,0,100,A,tile=WHITE)+f'<text x="125" y="62" {FONTS} font-size="26" font-weight="800" fill="{WHITE}">Market<tspan font-weight="500">Square</tspan></text>', HR))
# E white bar
E=mark(HR,INK,WHITE)
opts.append(("E · White app bar","White header with the colour mark, red stays on the bottom bar. Biggest change.",
  bar(WHITE,INK,place(10,12,36,E),place(314,12,36,E),line="#E6E1DE"), place(0,0,100,E), "#FFFFFF"))
CW,CH=600,330; pad=30; cols=2; rows=3; W=pad+cols*(CW+pad); H=100+rows*(CH+pad)
P=[f'<rect width="{W}" height="{H}" fill="#EFEBE8"/>',f'<text x="{pad}" y="48" {FONTS} font-size="26" font-weight="800" fill="{INK}">Logo on the red header</text>',f'<text x="{pad}" y="74" {FONTS} font-size="14" fill="#6D6763">Header red #DB2031 from the current app, shown at 1.5x real size</text>']
for i,(t,n,hdr,zoom,zbg) in enumerate(opts):
    x=pad+(i%cols)*(CW+pad); y=100+(i//cols)*(CH+pad)
    P.append(f'<g transform="translate({x} {y})"><rect width="{CW}" height="{CH}" rx="16" fill="#fff"/><text x="22" y="36" {FONTS} font-size="16" font-weight="800" fill="{INK}">{t}</text><text x="22" y="58" {FONTS} font-size="12" fill="#6D6763">{n}</text>')
    P.append(f'<g transform="translate(30 80) scale(1.5)"><clipPath id="c{i}"><rect width="360" height="60"/></clipPath><g clip-path="url(#c{i})">{hdr}</g></g>')
    P.append(f'<rect x="30" y="190" width="540" height="124" rx="12" fill="{zbg}" stroke="#ECE7E4"/>')
    P.append(f'<g transform="translate(60 212)">{zoom}</g>')
    P.append('</g>')
open(os.path.join(OUT,"00-overview.svg"),"w").write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">'+"".join(P)+'</svg>')
# standalone assets
def save(name,body,size=100,bg=None,tile=None):
    inner=place(0,0,size,body,tile=tile)
    b=f'<rect width="{size}" height="{size}" fill="{bg}"/>' if bg else ''
    open(os.path.join(OUT,name),"w").write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">{b}{inner}</svg>')
save("mark-on-red-A-white-tile.svg",A,100,tile=WHITE)
save("mark-on-red-B-white-knockout.svg",B,100)
save("mark-on-red-C-m-only.svg",C,100)
print("ok")
