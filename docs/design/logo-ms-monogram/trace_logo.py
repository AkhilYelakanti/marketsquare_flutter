import numpy as np, potrace, sys, json
from PIL import Image, ImageFilter
src=sys.argv[1]; out=sys.argv[2]
K=8
im=Image.open(src).convert("RGBA")
bg=Image.new("RGBA",im.size,(255,255,255,255)); bg.alpha_composite(im); im=bg.convert("RGB")
big=im.resize((im.width*K,im.height*K),Image.BICUBIC).filter(ImageFilter.GaussianBlur(K*0.35))
a=np.asarray(big).astype(int); r,g,b=a[...,0],a[...,1],a[...,2]
red=(r-np.maximum(g,b)>60)&(r>120)
black=(np.max(a,axis=2)<95)
def trace(mask):
    bm=potrace.Bitmap(~mask)
    plist=bm.trace(turdsize=60,turnpolicy=potrace.POTRACE_TURNPOLICY_MINORITY,alphamax=1.15,opticurve=True,opttolerance=0.5)
    d=[]
    for c in plist:
        sp=c.start_point; d.append(f"M{sp.x/K:.2f} {sp.y/K:.2f}")
        for s in c.segments:
            if s.is_corner: d.append(f"L{s.c.x/K:.2f} {s.c.y/K:.2f}L{s.end_point.x/K:.2f} {s.end_point.y/K:.2f}")
            else: d.append(f"C{s.c1.x/K:.2f} {s.c1.y/K:.2f} {s.c2.x/K:.2f} {s.c2.y/K:.2f} {s.end_point.x/K:.2f} {s.end_point.y/K:.2f}")
        d.append("Z")
    return "".join(d)
ys,xs=np.where(red|black); bbox=[xs.min()/K,ys.min()/K,xs.max()/K,ys.max()/K]
json.dump({"red":trace(red),"black":trace(black),"bbox":bbox,"size":[im.width,im.height]},open(out,"w"))
print(bbox)
