import sys,os
sys.path.insert(0,os.path.dirname(__file__))
import defs as d
from defs import *
OUT=sys.argv[1]
def bm(c1,extra=""):
    return f'<path d="M20 84V20L50 56L80 20V84" fill="none" stroke="{c1}" stroke-width="12" stroke-linejoin="round" stroke-linecap="round"/>'+extra
SC="M58 70C58 64 42 64 42 71C42 77 58 76 58 83C58 90 42 90 42 84"
def o1(c1,c2): # squared S
    return bm(c1,f'<path d="M58 67H43V76H57V85H42" fill="none" stroke="{c2}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>')
def o2(c1,c2): # curved S
    return bm(c1,f'<path d="{SC}" fill="none" stroke="{c2}" stroke-width="5" stroke-linecap="round"/>')
def o3(c1,c2): # solid square
    return bm(c1,f'<rect x="41" y="66" width="18" height="18" rx="4" fill="{c2}"/>')
def o4(c1,c2): # square badge with S knocked out
    sc=WHITE if c1==RED else (RED if c2==PINK else DARK)
    return bm(c1,f'<rect x="38" y="64" width="24" height="24" rx="6" fill="{c2}"/><path d="{SC}" fill="none" stroke="{sc}" stroke-width="6.5" stroke-linecap="round" transform="translate(50 76.5) scale(.5) translate(-50 -77)"/>')
def o5(c1,c2): # two offset squares (S flow)
    return bm(c1,f'<rect x="36" y="65" width="11" height="11" rx="2.5" fill="{c2}"/><rect x="53" y="77" width="11" height="11" rx="2.5" fill="{c2}"/>')
def o6(c1,c2): # route S with end dots
    return bm(c1,f'<path d="M40 70C62 70 38 83 60 83" fill="none" stroke="{c2}" stroke-width="3.5" stroke-linecap="round"/><circle cx="40" cy="70" r="4.5" fill="{c2}"/><circle cx="60" cy="83" r="5" fill="{c2}"/>')
def o7(c1,c2): # M inside a square frame
    return (f'<rect x="7" y="7" width="86" height="86" rx="20" fill="none" stroke="{c2}" stroke-width="7"/>'
            f'<g transform="translate(19 18) scale(.62)"><path d="M20 84V20L50 56L80 20V84" fill="none" stroke="{c1}" stroke-width="13" stroke-linejoin="round" stroke-linecap="round"/></g>')
ms={21:o1,22:o2,23:o3,24:o4,25:o5,26:o6,27:o7}
d.MARKS.update(ms)
NM={21:"squared-s",22:"curved-s",23:"solid-square",24:"square-s-badge",25:"offset-squares",26:"route-s",27:"m-in-square"}
TT={21:"1 · Squared S",22:"2 · Curved S",23:"3 · Solid square",24:"4 · Square with S",25:"5 · Offset squares",26:"6 · Route S",27:"7 · M in a square"}
ID={21:"S built from straight strokes, matches the M's angles",22:"Smooth S below the valley",23:"A square for the Square in the name",24:"Ink square with an S cut out, says both words at once",25:"Two squares stepping down, suggests an S and a handover",26:"S-shaped delivery route with start and end points",27:"Square frame around the M, no S"}
ow=d.word; d.word=lambda n,sc: ow(4,sc)
def mk(n,sc,bg=True):
    s=d.SCHEME[sc]; return ms[n](s['c1'],s['c2'])
d.mark=mk
def icon(n):
    return f'<rect width="100" height="100" rx="22" fill="{RED}"/><g transform="translate(18 18) scale(.64)">{ms[n](WHITE,PINK)}</g>'
ns=list(ms)
for n in ns:
    nm=f"{n-20:02d}-{NM[n]}"
    for sc,suf,bg in (('light','lockup',None),('dark','lockup-dark',DARK)):
        bd,w=d.lockup_body(n,sc,24,24); open(f"{OUT}/{nm}-{suf}.svg","w").write(d.svg(bd,int(w+48),112,bg))
    open(f"{OUT}/{nm}-mark.svg","w").write(d.svg(mk(n,'light'),100,100))
    open(f"{OUT}/{nm}-app-icon.svg","w").write(d.svg(icon(n),100,100))
CW,CH,pad,cols=640,330,40,2; rows=4; SW=pad+cols*(CW+pad); SH=110+rows*(CH+pad)
P=[f'<rect width="{SW}" height="{SH}" fill="#EFEBE8"/>',f'<text x="{pad}" y="52" font-family="Inter, Arial, sans-serif" font-size="26" font-weight="800" fill="{INK}">Straight M · S options</text>',
   f'<text x="{pad}" y="78" font-family="Inter, Arial, sans-serif" font-size="14" fill="#6D6763">Replacing the dark lines with something that says Square</text>']
for i,n in enumerate(ns):
    x=pad+(i%cols)*(CW+pad); y=110+(i//cols)*(CH+pad)
    P.append(f'<g transform="translate({x} {y})"><rect width="{CW}" height="{CH}" rx="18" fill="{WHITE}"/><text x="24" y="38" font-family="Inter, Arial, sans-serif" font-size="16" font-weight="800" fill="{INK}">{TT[n]}</text><text x="24" y="58" font-family="Inter, Arial, sans-serif" font-size="12" fill="#6D6763">{ID[n]}</text>')
    bd,w=d.lockup_body(n,'light',0,0,72); P.append(f'<g transform="translate({(CW-w)/2} 86)">{bd}</g>')
    b2,w2=d.lockup_body(n,'dark',0,0,34)
    P.append(f'<rect x="24" y="190" width="300" height="116" rx="14" fill="{DARK}"/><g transform="translate({24+(300-w2)/2} {190+41})">{b2}</g>')
    P.append(f'<g transform="translate(340 190)"><rect width="116" height="116" rx="14" fill="{BGL}" stroke="#ECE7E4"/><g transform="translate(18 18) scale(.8)">{mk(n,"light")}</g></g><g transform="translate(472 190)"><g transform="scale(1.16)">{icon(n)}</g></g></g>')
open(f"{OUT}/00-overview.svg","w").write(d.svg("".join(P),SW,SH)); print("ok")
