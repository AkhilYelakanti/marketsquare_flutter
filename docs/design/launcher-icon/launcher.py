import json,sys,os
T=None; x0=y0=x1=y1=MW=MH=0
RED="#DB2031"; INK="#1D1B1A"; WHITE="#FFFFFF"
def icon(shape="rounded",fit=.84,wst=0,bst=0,bg=RED,fg=WHITE,k=INK,frame=100,adaptive=False):
    s=min(fit*frame/MW,fit*frame/MH); mw,mh=MW*s,MH*s
    ox,oy=(frame-mw)/2,(frame-mh)/2
    sw=wst; sb=bst
    wstroke=f' stroke="{fg}" stroke-width="{wst}" stroke-linejoin="round"' if wst else ''
    bstroke=f' stroke="{k}" stroke-width="{bst}" stroke-linejoin="round"' if bst else ''
    mark=(f'<g transform="translate({ox:.3f} {oy:.3f}) scale({s:.5f}) translate({-x0:.3f} {-y0:.3f})">'
          f'<path d="{T["red"]}" fill="{fg}" fill-rule="evenodd"{wstroke}/><path d="{T["black"]}" fill="{k}" fill-rule="evenodd"{bstroke}/></g>')
    if adaptive: body=mark
    else:
        body={'rounded':f'<rect width="{frame}" height="{frame}" rx="{frame*.22}" fill="{bg}"/>','square':f'<rect width="{frame}" height="{frame}" fill="{bg}"/>','round':f'<circle cx="{frame/2}" cy="{frame/2}" r="{frame/2}" fill="{bg}"/>'}[shape]+mark
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{frame}" height="{frame}" viewBox="0 0 {frame} {frame}">{body}</svg>'
if __name__=="__main__":
    T=json.load(open(sys.argv[1])); OUT=sys.argv[2]; x0,y0,x1,y1=T["bbox"]; MW,MH=x1-x0,y1-y0
    cands={"A as traced":dict(fit=.84),"B bolder":dict(fit=.86,wst=4,bst=3),"C boldest":dict(fit=.88,wst=7,bst=5)}
    for n,kw in cands.items(): open(os.path.join(OUT,n[0]+".svg"),"w").write(icon(**kw))
