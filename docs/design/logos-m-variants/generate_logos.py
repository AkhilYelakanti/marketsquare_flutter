import sys,os
sys.path.insert(0,os.path.dirname(__file__))
import defs as d
from defs import *
OUT=sys.argv[1]
def rack(c,ys,x=41,w=18):
    return "".join(f'<rect x="{x}" y="{y}" width="{w}" height="6" rx="3" fill="{c}"/>' for y in ys)
def v1(c1,c2): # straight M
    return f'<path d="M20 84V20L50 56L80 20V84" fill="none" stroke="{c1}" stroke-width="12" stroke-linejoin="round" stroke-linecap="round"/>'+rack(c2,[68,78],41,18)
def v2(c1,c2): # gable roofs
    return f'<path d="M16 86V38L33 18L50 38L67 18L84 38V86" fill="none" stroke="{c1}" stroke-width="12" stroke-linejoin="round" stroke-linecap="round"/>'+rack(c2,[54,64,74])
def v3(c1,c2): # squared m
    return f'<path d="M16 86V28H84V86M50 28V86" fill="none" stroke="{c1}" stroke-width="12" stroke-linejoin="round" stroke-linecap="round"/>'+f'<rect x="26" y="40" width="14" height="6" rx="3" fill="{c2}"/><rect x="60" y="40" width="14" height="6" rx="3" fill="{c2}"/>'
def v4(c1,c2): # solid block with two arched bays (evenodd)
    p=("M28 18H72A18 18 0 0 1 90 36V86H10V36A18 18 0 0 1 28 18Z "
       "M20 86V58a12 12 0 0 1 24 0V86Z M56 86V58a12 12 0 0 1 24 0V86Z")
    return f'<path d="{p}" fill="{c1}" fill-rule="evenodd"/>'
def v5(c1,c2): # bar-column M
    hs=[70,52,36,52,70]; s=""
    for i,h in enumerate(hs):
        x=10+i*17; col=c2 if i==2 else c1
        s+=f'<rect x="{x}" y="{86-h}" width="13" height="{h}" rx="6.5" fill="{col}"/>'
    return s
def v6(c1,c2): # stall M: scalloped awning + legs
    return (f'<path d="M12 44V36a19 19 0 0 1 38 0a19 19 0 0 1 38 0V44Z" fill="{c1}"/>'
            f'<rect x="16" y="52" width="12" height="36" rx="6" fill="{c1}"/><rect x="72" y="52" width="12" height="36" rx="6" fill="{c1}"/>'+rack(c2,[56,66,76],41,18))
def v7(c1,c2): # lowercase m, three legs
    return f'<path d="M14 86V48a18 18 0 0 1 36 0V86M50 48a18 18 0 0 1 36 0V86" fill="none" stroke="{c1}" stroke-width="12" stroke-linejoin="round" stroke-linecap="round"/>'
ms={12:v1,13:v2,14:v3,15:v4,16:v5,17:v6,18:v7}
d.MARKS.update(ms)
NM={12:"straight-m",13:"gable-m",14:"squared-m",15:"arched-block",16:"bar-column-m",17:"stall-m",18:"lowercase-m"}
TT={12:"1 · Straight M",13:"2 · Gable roofs M",14:"3 · Squared m",15:"4 · Arched block",16:"5 · Bar-column M",17:"6 · Stall M",18:"7 · Lowercase m"}
ID={12:"Classic geometric M with a small rack under the valley",13:"Pitched market roofs form the M",14:"Three-legged m with square bays, like stalls in a row",15:"Solid block with two arched bays, reads as m and as a storefront",16:"Five bars, tall to short to tall: crates, stock levels",17:"Scalloped awning on top, legs below, rack in the middle",18:"Rounded three-leg m, the simplest option"}
ow=d.word; d.word=lambda n,sc: ow(4,sc)
om=d.mark
def mk(n,sc,bg=True):
    s=d.SCHEME[sc]; return ms[n](s['c1'],s['c2'])
d.mark=mk
def icon(n):
    return f'<rect width="100" height="100" rx="22" fill="{RED}"/><g transform="translate(18 18) scale(.64)">{ms[n](WHITE,PINK)}</g>'
ns=list(ms)
for n in ns:
    nm=f"{n-11:02d}-{NM[n]}"
    for sc,suf,bg in (('light','lockup',None),('dark','lockup-dark',DARK)):
        bd,w=d.lockup_body(n,sc,24,24); open(f"{OUT}/{nm}-{suf}.svg","w").write(d.svg(bd,int(w+48),112,bg))
    open(f"{OUT}/{nm}-mark.svg","w").write(d.svg(mk(n,'light'),100,100))
    open(f"{OUT}/{nm}-app-icon.svg","w").write(d.svg(icon(n),100,100))
CW,CH,pad,cols=640,330,40,2; rows=4; SW=pad+cols*(CW+pad); SH=110+rows*(CH+pad)
P=[f'<rect width="{SW}" height="{SH}" fill="#EFEBE8"/>',f'<text x="{pad}" y="52" font-family="Inter, Arial, sans-serif" font-size="26" font-weight="800" fill="{INK}">MarketSquare · M shape options</text>',
   f'<text x="{pad}" y="78" font-family="Inter, Arial, sans-serif" font-size="14" fill="#6D6763">Same lockup, colours and icon format, different M</text>']
for i,n in enumerate(ns):
    x=pad+(i%cols)*(CW+pad); y=110+(i//cols)*(CH+pad)
    P.append(f'<g transform="translate({x} {y})"><rect width="{CW}" height="{CH}" rx="18" fill="{WHITE}"/><text x="24" y="38" font-family="Inter, Arial, sans-serif" font-size="16" font-weight="800" fill="{INK}">{TT[n]}</text><text x="24" y="58" font-family="Inter, Arial, sans-serif" font-size="12" fill="#6D6763">{ID[n]}</text>')
    bd,w=d.lockup_body(n,'light',0,0,72); P.append(f'<g transform="translate({(CW-w)/2} 86)">{bd}</g>')
    b2,w2=d.lockup_body(n,'dark',0,0,34)
    P.append(f'<rect x="24" y="190" width="300" height="116" rx="14" fill="{DARK}"/><g transform="translate({24+(300-w2)/2} {190+41})">{b2}</g>')
    P.append(f'<g transform="translate(340 190)"><rect width="116" height="116" rx="14" fill="{BGL}" stroke="#ECE7E4"/><g transform="translate(18 18) scale(.8)">{mk(n,"light")}</g></g><g transform="translate(472 190)"><g transform="scale(1.16)">{icon(n)}</g></g></g>')
open(f"{OUT}/00-overview.svg","w").write(d.svg("".join(P),SW,SH)); print("ok")
