import sys,os
sys.path.insert(0,os.path.dirname(__file__))
import defs as d
from defs import *
OUT=sys.argv[1]
def a(c1,c2):   # arches over two shelf bars
    return (f'<path d="M16 54V34a17 17 0 0 1 34 0a17 17 0 0 1 34 0V54" fill="none" stroke="{c1}" stroke-width="12" stroke-linejoin="round" stroke-linecap="round"/>'
            f'<rect x="12" y="66" width="76" height="9" rx="4.5" fill="{c1}"/><rect x="28" y="80" width="60" height="9" rx="4.5" fill="{c2}"/>')
def b(c1,c2):   # arch M with shelf rack in the centre
    return (f'<path d="M14 86V42a18 18 0 0 1 36 0a18 18 0 0 1 36 0V86" fill="none" stroke="{c1}" stroke-width="12" stroke-linejoin="round" stroke-linecap="round"/>'
            f'<rect x="40" y="56" width="20" height="6" rx="3" fill="{c2}"/><rect x="40" y="67" width="20" height="6" rx="3" fill="{c2}"/><rect x="40" y="78" width="20" height="6" rx="3" fill="{c2}"/>')
def c(c1,c2):   # solid scalloped top bar over shelf bars
    return (f'<path d="M10 46V38a20 20 0 0 1 40 0a20 20 0 0 1 40 0V46Z" fill="{c1}"/>'
            f'<rect x="10" y="54" width="80" height="14" rx="5" fill="{c1}"/><rect x="26" y="74" width="64" height="14" rx="5" fill="{c2}"/>')
def e(c1,c2):   # M: arch top, legs built from shelf bars
    return (f'<path d="M20 46V34a15 15 0 0 1 30 0a15 15 0 0 1 30 0V46" fill="none" stroke="{c1}" stroke-width="12" stroke-linejoin="round" stroke-linecap="round"/>'
            f'<rect x="10" y="58" width="28" height="12" rx="4" fill="{c1}"/><rect x="10" y="76" width="28" height="12" rx="4" fill="{c1}"/>'
            f'<rect x="62" y="58" width="28" height="12" rx="4" fill="{c1}"/><rect x="62" y="76" width="28" height="12" rx="4" fill="{c2}"/>')
def f(c1,c2,bg=True,inner=WHITE,inner2=PINK):  # badge: arch M + two shelf bars
    s=f'<rect x="4" y="4" width="92" height="92" rx="24" fill="{c1}"/>' if bg else ''
    return s+(f'<path d="M22 58V42a14 14 0 0 1 28 0a14 14 0 0 1 28 0V58" fill="none" stroke="{inner}" stroke-width="9" stroke-linejoin="round" stroke-linecap="round"/>'
              f'<rect x="22" y="68" width="56" height="7" rx="3.5" fill="{inner}"/><rect x="34" y="80" width="44" height="7" rx="3.5" fill="{inner2}"/>')
d.MARKS.update({7:a,8:b,9:c,10:e,11:f})
NM={7:"arches-over-shelves",8:"arch-m-rack",9:"scallop-shelf",10:"shelf-leg-m",11:"badge-m-shelf"}
TT={7:"A · Arches over shelves",8:"B · Arch M with rack",9:"C · Scalloped shelf",10:"D · Shelf-leg M",11:"E · Badge M"}
ID={7:"Your M arches on top, two shelf levels below (second one offset)",8:"Arch M kept whole, a three-level rack replaces the plaza",9:"Shelf stack whose top bar is the market awning",10:"M legs are shelf bars, arch top joins them",11:"Rounded app badge: white arch M over two shelf bars"}
orig_word=d.word
d.word=lambda n,sc: orig_word(4 if n>=7 else n,sc)
orig_mark=d.mark
def mk(n,sc,bg=True):
    if n==11:
        s=d.SCHEME[sc]
        return f(RED,None,True,WHITE,PINK) if sc=='light' else f(s['c1'],None,True,DARK if sc=='dark' else RED,RED if sc=='red' else LRED)
    return orig_mark(n,sc,bg)
d.mark=mk
def icon(n):
    m=f(None,None,False,WHITE,PINK) if n==11 else d.MARKS[n](WHITE,PINK)
    sc=.74 if n==11 else .64; off=(100-100*sc)/2
    return f'<rect width="100" height="100" rx="22" fill="{RED}"/><g transform="translate({off} {off}) scale({sc})">{m}</g>'
ns=[7,8,9,10,11]
for n in ns:
    nm=f"{n-6:02d}-{NM[n]}"
    for sc,suf,bg in (('light','lockup',None),('dark','lockup-dark',DARK)):
        bd,w=d.lockup_body(n,sc,24,24); open(f"{OUT}/{nm}-{suf}.svg","w").write(d.svg(bd,int(w+48),112,bg))
    open(f"{OUT}/{nm}-mark.svg","w").write(d.svg(mk(n,'light'),100,100))
    open(f"{OUT}/{nm}-app-icon.svg","w").write(d.svg(icon(n),100,100))
CW,CH,pad,cols=640,330,40,2; rows=3; SW=pad+cols*(CW+pad); SH=110+rows*(CH+pad)
P=[f'<rect width="{SW}" height="{SH}" fill="#EFEBE8"/>',f'<text x="{pad}" y="52" font-family="Inter, Arial, sans-serif" font-size="26" font-weight="800" fill="{INK}">Shelf Stack + Arch Market</text>',
   f'<text x="{pad}" y="78" font-family="Inter, Arial, sans-serif" font-size="14" fill="#6D6763">5 ways to merge the two directions</text>']
for i,n in enumerate(ns):
    x=pad+(i%cols)*(CW+pad); y=110+(i//cols)*(CH+pad)
    P.append(f'<g transform="translate({x} {y})"><rect width="{CW}" height="{CH}" rx="18" fill="{WHITE}"/><text x="24" y="38" font-family="Inter, Arial, sans-serif" font-size="16" font-weight="800" fill="{INK}">{TT[n]}</text><text x="24" y="58" font-family="Inter, Arial, sans-serif" font-size="12" fill="#6D6763">{ID[n]}</text>')
    bd,w=d.lockup_body(n,'light',0,0,72); P.append(f'<g transform="translate({(CW-w)/2} 86)">{bd}</g>')
    b2,w2=d.lockup_body(n,'dark',0,0,34)
    P.append(f'<rect x="24" y="190" width="300" height="116" rx="14" fill="{DARK}"/><g transform="translate({24+(300-w2)/2} {190+41})">{b2}</g>')
    P.append(f'<g transform="translate(340 190)"><rect width="116" height="116" rx="14" fill="{BGL}" stroke="#ECE7E4"/><g transform="translate(18 18) scale(.8)">{mk(n,"light")}</g></g><g transform="translate(472 190)"><g transform="scale(1.16)">{icon(n)}</g></g></g>')
open(f"{OUT}/00-overview.svg","w").write(d.svg("".join(P),SW,SH)); print("ok")
