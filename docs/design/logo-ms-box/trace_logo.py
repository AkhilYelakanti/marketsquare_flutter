import numpy as np, potrace, sys, json
from PIL import Image, ImageFilter
src,out=sys.argv[1],sys.argv[2]; K=6
im=Image.open(src).convert("RGBA"); bg=Image.new("RGBA",im.size,(255,255,255,255)); bg.alpha_composite(im); im=bg.convert("RGB")
big=im.resize((im.width*K,im.height*K),Image.BICUBIC).filter(ImageFilter.GaussianBlur(K*0.4))
a=np.asarray(big).astype(int); r,g,b=a[...,0],a[...,1],a[...,2]
white=(g>135)&(r>150)
black=(r<110)&(g<95)&(b<95)
M=K*5
for m_ in (white,black): m_[:M,:]=False; m_[-M:,:]=False; m_[:,:M]=False; m_[:,-M:]=False
def trace(mask):
    plist=potrace.Bitmap(~mask).trace(turdsize=80,turnpolicy=potrace.POTRACE_TURNPOLICY_MINORITY,alphamax=1.1,opticurve=True,opttolerance=0.6)
    d=[]
    for c in plist:
        sp=c.start_point; d.append(f"M{sp.x/K:.2f} {sp.y/K:.2f}")
        for s in c.segments:
            if s.is_corner: d.append(f"L{s.c.x/K:.2f} {s.c.y/K:.2f}L{s.end_point.x/K:.2f} {s.end_point.y/K:.2f}")
            else: d.append(f"C{s.c1.x/K:.2f} {s.c1.y/K:.2f} {s.c2.x/K:.2f} {s.c2.y/K:.2f} {s.end_point.x/K:.2f} {s.end_point.y/K:.2f}")
        d.append("Z")
    return "".join(d)
ys,xs=np.where(white|black); bbox=[xs.min()/K,ys.min()/K,xs.max()/K,ys.max()/K]
json.dump({"red":trace(white),"black":trace(black),"bbox":bbox,"size":[im.width,im.height]},open(out,"w")); print(bbox)
