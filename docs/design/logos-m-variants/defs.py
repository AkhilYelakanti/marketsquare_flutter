import sys, os
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
OUT=sys.argv[1]
FD="/usr/share/fonts/opentype/inter/"
_f={}
def font(n):
    if n not in _f: _f[n]=TTFont(FD+n)
    return _f[n]
RED="#C4202E"; INK="#1D1B1A"; WHITE="#FFFFFF"; PINK="#FFC9CE"; LRED="#FF8A93"; BGL="#FAF8F7"; DARK="#17120F"
def tpath(fn,s,size,x,y,ls=0):
    f=font(fn); gs=f.getGlyphSet(); cm=f.getBestCmap(); sc=size/f['head'].unitsPerEm
    ds=[]; cx=x
    for ch in s:
        gn=cm[ord(ch)]; pen=SVGPathPen(gs,ntos=lambda v:f"{v:.2f}")
        gs[gn].draw(TransformPen(pen,(sc,0,0,-sc,cx,y))); ds.append(pen.getCommands()); cx+=gs[gn].width*sc+ls
    return " ".join(ds), cx-x-(ls if s else 0)
# ---- marks on a 100x100 grid. c1 primary, c2 secondary ----
def m1(c1,c2,bg=True):
    s=f'<rect x="4" y="4" width="92" height="92" rx="24" fill="{c1}"/>' if bg else ''
    return s+f'<path d="M24 74V30L50 56L76 30V74" fill="none" stroke="{c2}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/><rect x="43" y="15" width="14" height="14" rx="3" fill="{c2}"/>'
def m2(c1,c2):
    return (f'<rect x="8" y="8" width="38" height="38" rx="9" fill="{c1}"/><rect x="54" y="8" width="38" height="38" rx="9" fill="{c1}"/>'
            f'<rect x="8" y="54" width="38" height="38" rx="9" fill="{c1}"/><rect x="58" y="58" width="34" height="34" rx="9" fill="{c2}" transform="rotate(12 75 75)"/>')
def m3(c1,c2):
    return (f'<rect x="8" y="8" width="84" height="84" rx="20" fill="none" stroke="{c1}" stroke-width="9"/>'
            f'<path d="M30 70C30 44 70 56 70 30" fill="none" stroke="{c2}" stroke-width="7" stroke-linecap="round" stroke-dasharray="1 13.5"/>'
            f'<path d="M30 70C30 44 70 56 70 30" fill="none" stroke="{c2}" stroke-width="7" stroke-linecap="round" opacity="0"/>'
            f'<circle cx="30" cy="70" r="7" fill="{c1}"/><circle cx="70" cy="30" r="9" fill="{c2}"/>')
def m4(c1,c2):
    return (f'<path d="M14 84V42a18 18 0 0 1 36 0a18 18 0 0 1 36 0V84" fill="none" stroke="{c1}" stroke-width="12" stroke-linejoin="round" stroke-linecap="round"/>'
            f'<rect x="41" y="62" width="18" height="22" rx="3" fill="{c2}"/>')
def m5(c1,c2):
    return (f'<rect x="22" y="8" width="56" height="56" rx="14" fill="{c1}" transform="rotate(45 50 36)"/>'
            f'<rect x="40" y="26" width="20" height="20" rx="4" fill="{c2}"/><rect x="26" y="88" width="48" height="6" rx="3" fill="{c2}"/>')
def m6(c1,c2):
    return (f'<rect x="10" y="14" width="80" height="18" rx="6" fill="{c1}"/><rect x="26" y="41" width="64" height="18" rx="6" fill="{c1}"/>'
            f'<rect x="10" y="68" width="80" height="18" rx="6" fill="{c2}"/><rect x="10" y="41" width="10" height="18" rx="4" fill="{c2}"/>')
MARKS={1:m1,2:m2,3:m3,4:m4,5:m5,6:m6}
NAMES={1:"crate-m",2:"pallet-grid",3:"route-square",4:"arch-market",5:"drop-pin",6:"shelf-stack"}
TITLE={1:"Crate M",2:"Pallet Grid",3:"Route Square",4:"Arch Market",5:"Drop Pin",6:"Shelf Stack"}
IDEA={1:"M drawn as a path with a parcel on top",2:"Market square of four blocks, one leaving the pallet",3:"A square frame with a delivery route inside",4:"Two market arches form the M, plaza below",5:"Pin shaped like a package, marks the store drop-off",6:"Shelf levels, one shifted: stock moving through"}
SCHEME={ 'light':dict(c1=RED,c2=INK,a=INK,b=RED), 'dark':dict(c1=WHITE,c2=LRED,a=WHITE,b=LRED), 'red':dict(c1=WHITE,c2=PINK,a=WHITE,b=PINK) }
def mark(n,sc,bg=True):
    s=SCHEME[sc]
    if n==1:
        return m1(RED,WHITE,True) if sc=='light' else m1(s['c1'],RED if sc!='dark' else DARK,True)
    return MARKS[n](s['c1'],s['c2'])
def word(n,sc):
    s=SCHEME[sc]; a,b=s['a'],s['b']
    B="Inter-ExtraBold.otf"; M="Inter-Medium.otf"; SB="Inter-SemiBold.otf"; BD="Inter-Bold.otf"
    if n in (1,4,6):
        sz=33; p1,w1=tpath(B,"Market",sz,0,0,-.2); p2,w2=tpath(M if n!=6 else B,"Square",sz,w1+1,0,-.2)
        return [(p1,a),(p2,b)],w1+w2+1,sz*.73
    if n==2:
        sz=33; p1,w1=tpath(BD,"market",sz,0,0,-.2); p2,w2=tpath(M,"square",sz,w1+1,0,-.2)
        return [(p1,a),(p2,b)],w1+w2+1,sz*.55
    if n==3:
        sz=21; p1,w1=tpath(BD,"MARKET",sz,0,0,3.2); p2,w2=tpath(M,"SQUARE",sz,w1+10,0,3.2)
        return [(p1,a),(p2,b)],w1+w2+10,sz*.73
    if n==5:
        sz=26; p1,w1=tpath(BD,"Market",sz,0,-2,-.2); p2,w2=tpath(BD,"Square",sz,0,26,-.2)
        return [(p1,a),(p2,b)],max(w1,w2),50
def lockup_body(n,sc,x=0,y=0,ms=64):
    paths,w,ch=word(n,sc); gap=16
    body=f'<g transform="translate({x} {y}) scale({ms/100})">{mark(n,sc)}</g>'
    if n==5:
        wx=x+ms+gap; cy=y+ms/2; body+=f'<g transform="translate({wx} {cy-1})"><path d="{paths[0][0]}" fill="{paths[0][1]}"/><path d="{paths[1][0]}" fill="{paths[1][1]}"/></g>'
        # shift: first line baseline sits at -2+... align
    else:
        wx=x+ms+gap; base=y+ms/2+ch/2
        body+=f'<g transform="translate({wx} {base})"><path d="{paths[0][0]}" fill="{paths[0][1]}"/><path d="{paths[1][0]}" fill="{paths[1][1]}"/></g>'
    return body, ms+gap+w
def svg(inner,w,h,bg=None):
    b=f'<rect width="{w}" height="{h}" fill="{bg}"/>' if bg else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{b}{inner}</svg>'
def icon_body(n,size=100):
    # red app icon (rounded square) with inverse mark
    if n==1: m=f'<path d="M24 74V30L50 56L76 30V74" fill="none" stroke="{WHITE}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/><rect x="43" y="15" width="14" height="14" rx="3" fill="{WHITE}"/>'
    else: m=MARKS[n](WHITE,PINK)
    return f'<rect width="100" height="100" rx="22" fill="{RED}"/><g transform="translate(18 18) scale(.64)">{m}</g>'
