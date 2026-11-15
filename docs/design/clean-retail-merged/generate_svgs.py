import os, sys
OUT = sys.argv[1]
RED="#C4202E"; INK="#1D1B1A"; BG="#FAF8F7"; LINE="#ECE7E4"; TINT="#FDECEE"; MUTED="#9A928D"
GRN="#1E7A3A"; GRNBG="#DFF3E4"; AMB="#8A5A00"; AMBBG="#FDF0D4"; ERR="#A3111F"; ERRBG="#FBE0E2"; WHITE="#FFFFFF"; PH="#F6EFE9"
W,H=360,760
FONT="Plus Jakarta Sans, Inter, Arial, sans-serif"
P={
'home':'M3 11l9-8 9 8v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z','plus':'M12 5v14M5 12h14','list':'M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01',
'scan':'M4 8V5a1 1 0 0 1 1-1h3M16 4h3a1 1 0 0 1 1 1v3M20 16v3a1 1 0 0 1-1 1h-3M8 20H5a1 1 0 0 1-1-1v-3M4 12h16','send':'M22 2L11 13M22 2l-7 20-4-9-9-4z',
'refresh':'M21 12a9 9 0 0 1-15.5 6.2M3 12A9 9 0 0 1 18.5 5.8M21 4v5h-5M3 20v-5h5','chat':'M21 12a8 8 0 0 1-11.8 7L3 21l2-5.5A8 8 0 1 1 21 12z',
'box':'M21 8l-9-5-9 5v8l9 5 9-5zM3 8l9 5 9-5M12 13v8','check':'M5 12l5 5L20 7','search':'M21 21l-4.3-4.3M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14z',
'tag':'M20 12l-8 8-9-9V3h8zM7.5 7.5h.01','file':'M14 3H6a1 1 0 0 0-1 1v16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V8zM14 3v5h5M9 13h6M9 17h6',
'gear':'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM19 12h2M3 12h2M12 3v2M12 19v2M5.6 5.6L7 7M17 17l1.4 1.4M18.4 5.6L17 7M7 17l-1.4 1.4','chev':'M9 6l6 6-6 6',
'back':'M15 6l-6 6 6 6','wifi':'M2 9a15 15 0 0 1 20 0M5 13a10 10 0 0 1 14 0M8.5 16.4a5 5 0 0 1 7 0M12 20h.01','store':'M3 9l1-5h16l1 5M5 12v8h14v-8M3 9h18',
'clock':'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2','user':'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21a8 8 0 0 1 16 0','lock':'M6 11h12v9H6zM8 11V8a4 4 0 0 1 8 0v3',
}
def esc(s): return s.replace("&","&amp;").replace("<","&lt;")
def T(x,y,s,size=12,w=500,fill=INK,anchor="start",ls=None,op=None):
    a=f' text-anchor="{anchor}"' if anchor!="start" else ""
    l=f' letter-spacing="{ls}"' if ls else ""
    o=f' opacity="{op}"' if op else ""
    return f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" font-weight="{w}" fill="{fill}"{a}{l}{o}>{esc(s)}</text>'
def R(x,y,w,h,r=0,fill=WHITE,stroke=None,sw=1,op=None):
    s=f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
    o=f' opacity="{op}"' if op else ""
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}"{s}{o}/>'
def C(cx,cy,r,fill): return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}"/>'
def I(n,x,y,size=18,col=INK,sw=1.9):
    sc=size/24
    return f'<g transform="translate({x} {y}) scale({sc})" fill="none" stroke="{col}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"><path d="{P[n]}"/></g>'
def G(name,*c): return f'<g id="{esc(name).replace(chr(34),"")}">'+"".join(c)+'</g>'
def status(light=True):
    c=WHITE if light else INK
    return G("Status bar",T(20,19,"9:41",12,700,c),I('wifi',320,5,18,c))
def header(title,sub=None,h=96,back=True,right=None):
    d=f'M0 0H{W}V{h-24}a24 24 0 0 1 -24 24H24a24 24 0 0 1 -24 -24Z'
    p=[f'<path d="{d}" fill="{RED}"/>',status()]
    x=20
    if back: p.append(I('back',16,44,22,WHITE,2.2)); x=48
    p.append(T(x,58,title,19,800,WHITE))
    if sub: p.append(T(x,76,sub,11,500,"#FFFFFF",op=.85))
    if right: p.append(I(right,324,44,22,WHITE,2.0))
    return G("Header",*p)
def nav(active):
    items=[('home','Home'),('box','Orders'),('search','Catalog'),('chat','Inbox')]
    p=[R(0,690,W,70,0,WHITE),f'<rect x="0" y="690" width="{W}" height="1" fill="{LINE}"/>']
    for i,(ic,l) in enumerate(items):
        cx=45+i*90; on=l==active; col=RED if on else MUTED
        p+= [I(ic,cx-10,702,20,col,2.0),T(cx,738,l,10,700 if on else 600,col,"middle")]
    return G("Bottom navigation",*p)
def pill(x,y,t,kind="ok"):
    bg,fg={"ok":(GRNBG,GRN),"wait":(AMBBG,AMB),"err":(ERRBG,ERR),"red":(RED,WHITE)}[kind]
    w=len(t)*5.6+18
    return G(f"Status pill/{t}",R(x,y,w,20,10,bg),T(x+w/2,y+14,t,10,700,fg,"middle")),w
def pillr(xr,y,t,kind="ok"):
    w=len(t)*5.6+18; s,_=pill(xr-w,y,t,kind); return s
def card(x,y,w,h,name="Card",fill=WHITE,r=16): return G(name,R(x,y,w,h,r,fill,LINE if fill==WHITE else None))
def btn(x,y,w,t,kind="red",h=40):
    if kind=="red": return G(f"Button/{t}",R(x,y,w,h,h/2,RED),T(x+w/2,y+h/2+4.5,t,13,700,WHITE,"middle"))
    return G(f"Button/{t}",R(x,y,w,h,h/2,WHITE,"#E3DEDB",1.5),T(x+w/2,y+h/2+4.5,t,13,700,INK,"middle"))
def chips(y,names,on=0,x=16):
    p=[]
    for i,n in enumerate(names):
        w=len(n)*6.4+24
        p.append(G(f"Chip/{n}",R(x,y,w,30,15,INK if i==on else WHITE,None if i==on else LINE),T(x+w/2,y+19.5,n,11.5,700,WHITE if i==on else INK,"middle")))
        x+=w+8
    return G("Filter chips",*p)
def stepper(x,y,q):
    return G("Quantity stepper",R(x,y,70,26,13,BG),T(x+14,y+18,"−",15,700,RED,"middle"),T(x+35,y+18,str(q),12,800,INK,"middle"),T(x+56,y+18,"+",15,700,RED,"middle"))
def pcard(x,y,e,name,price,q):
    p=[R(x,y,156,148,18,WHITE,LINE),R(x+8,y+8,140,76,12,PH),T(x+78,y+60,e,34,500,INK,"middle")]
    if q: p+= [R(x+114,y+14,28,18,9,RED),T(x+128,y+27,str(q),10,800,WHITE,"middle")]
    p+= [T(x+12,y+104,name,11.5,700),T(x+12,y+120,price,10.5,500,MUTED),stepper(x+78,y+112,q) if False else stepper(x+78,y+120,q)]
    return G(f"Product card/{name}",*p)
def field(x,y,w,l,v,ph=False):
    return G(f"Field/{l}",R(x,y,w,52,12,WHITE,"#E3DEDB",1.5),T(x+14,y+19,l.upper(),9.5,700,MUTED,ls=.6),T(x+14,y+40,v,13.5,600,MUTED if ph else INK))
def row(y,ic,t,s,right=None,x=16,w=328):
    p=[R(x,y,w,58,16,WHITE,LINE),R(x+10,y+11,36,36,11,TINT),I(ic,x+19,y+20,18,RED,2.0),T(x+58,y+26,t,12.5,700),T(x+58,y+42,s,10.5,500,MUTED)]
    if right: p.append(right)
    return G(f"List row/{t}",*p)
def floatbar(y,l1,l2,cta):
    return G("Floating order bar",R(14,y,332,58,29,INK),T(34,y+24,l1,10,500,"#FFFFFF",op=.7),T(34,y+43,l2,16,800,WHITE),R(236,y+9,100,40,20,RED),T(286,y+34,cta,13,700,WHITE,"middle"))
def bottombar(*bs):
    n=len(bs); gap=10; w=(W-32-gap*(n-1))/n
    return G("Bottom action bar",R(0,684,W,76,0,WHITE),f'<rect x="0" y="684" width="{W}" height="1" fill="{LINE}"/>',*[btn(16+i*(w+gap),700,w,t,k,44) for i,(t,k) in enumerate(bs)])

# ---------- screens ----------
def s_home():
    p=[R(0,0,W,H,0,BG)]
    p.append(f'<path d="M0 0H{W}V176a24 24 0 0 1 -24 24H24a24 24 0 0 1 -24 -24Z" fill="{RED}"/>'.replace("V176","V166").replace("a24 24 0 0 1 -24 24H24a24 24 0 0 1 -24 -24","a24 24 0 0 1 -24 24H24a24 24 0 0 1 -24 -24").replace("H24a24","H24a24"))
    # simpler header geometry
    p[-1]=f'<path d="M0 0H{W}V142a24 24 0 0 1 -24 24H24a24 24 0 0 1 -24 -24Z" fill="{RED}"/>'
    p+=[status(),T(20,52,"Good morning, Akhil",11,500,WHITE,op=.85),T(20,78,"Store 4521",22,800,WHITE),
        G("Connection chip",R(262,56,78,24,12,"#FFFFFF",op=.2),C(276,68,4,"#7CE0A0"),T(285,72,"Online",11,700,WHITE)),
        G("Search bar",R(16,100,328,44,14,WHITE),I('search',30,112,20,MUTED,2),T(58,127,"Search items or scan",13,500,MUTED),I('scan',312,112,20,RED,2))]
    p+=[G("Draft card",R(16,170,328,118,18,TINT),T(32,196,"DRAFT IN PROGRESS",10,800,ERR,ls=.8),T(312,196,"Saved 2 min ago",10,500,ERR,"end"),
        T(32,222,"Grocery · 24 items · $1,284",16,800),btn(32,238,148,"Continue","red",38),btn(190,238,138,"Repeat last","white",38))]
    for i,(n,l) in enumerate([("3","Unsent"),("2","Approvals"),("4","Messages")]):
        x=16+i*112
        p.append(G(f"KPI/{l}",R(x,304,104,62,16,WHITE,LINE),T(x+52,332,n,20,800,RED if l=="Approvals" else INK,"middle"),T(x+52,352,l,10.5,600,MUTED,"middle")))
    sc=[('plus','New order'),('send','Send'),('file','Orders'),('list','Catalog'),('check','Approve'),('box','Backroom'),('refresh','Sync'),('gear','More')]
    for i,(ic,l) in enumerate(sc):
        x=16+(i%4)*84; y=386+(i//4)*88
        p.append(G(f"Shortcut/{l}",R(x+9,y,54,54,18,WHITE,LINE),I(ic,x+24,y+15,24,RED,2),T(x+36,y+72,l,10.5,600,INK,"middle")))
    p.append(G("Message teaser",R(16,566,328,64,16,WHITE,LINE),R(28,580,36,36,12,AMBBG),I('chat',37,589,18,AMB,2),T(76,596,"4 new messages",12.5,700),T(76,613,"Holiday cutoff moves to Tuesday",10.5,500,MUTED),I('chev',318,589,18,MUTED,2)))
    p.append(nav("Home")); return p
def s_ordertype():
    p=[R(0,0,W,H,0,BG),header("New order","Store 4521 · Maple St Market")]
    p.append(G("Repeat order card",R(16,112,328,104,18,INK),T(32,138,"FASTEST WAY",10,800,"#FFFFFF",ls=.8,op=.7),T(32,162,"Repeat last grocery order",16,800,WHITE),T(32,180,"24 items · $1,284 · sent 12 Nov",11,500,"#FFFFFF",op=.75),btn(32,188,0,"x","red",0) if False else ""))
    p.append(G("Repeat button",R(232,166,96,36,18,RED),T(280,189,"Repeat",13,700,WHITE,"middle")))
    p.append(T(16,248,"Or start a new one",13,800))
    ty=[('box','Item order'),('tag','Ad order'),('refresh','Price change'),('tag','Tag order'),('list','TPR'),('file','Credit request')]
    for i,(ic,l) in enumerate(ty):
        x=16+(i%2)*168; y=262+(i//2)*86
        p.append(G(f"Order type/{l}",R(x,y,160,76,16,WHITE,LINE),R(x+12,y+12,34,34,11,TINT),I(ic,x+20,y+20,18,RED,2),T(x+12,y+64,l,12.5,700)))
    p.append(row(530,'clock',"Standing orders","3 saved templates",I('chev',318,549,18,MUTED,2)))
    p.append(nav("Orders")); return p
def s_filling():
    p=[R(0,0,W,H,0,BG),header("Item order","Grocery · PO 88213",right='scan'),chips(106,["All","Cereal","Drinks","Dairy","Bakery"],0)]
    it=[('🥣','Cheerios 18 oz','$38.40 / case',3),('🥤','Coca-Cola 12 pk','$17.96 / case',5),('🥛','2% Milk gal','$14.28 / case',2),('🍞','Wheat Bread','$19.52 / case',0),('🧀','Cheddar 8 oz','$31.80 / case',0),('🥚','Large Eggs dz','$27.15 / case',1)]
    for i,(e,n,pr,q) in enumerate(it): p.append(pcard(16+(i%2)*172,148+(i//2)*158,e,n,pr,q))
    p.append(floatbar(686,"11 cases · 28 cu ft","$1,284.20","Review")); return p
def s_sheet():
    p=[R(0,0,W,H,0,BG),header("Dairy","148 items",right='scan')]
    for i,(e,n,pr,q) in enumerate([('🥛','2% Milk gal','$14.28 / case',2),('🧀','Cheddar 8 oz','$31.80 / case',0)]): p.append(pcard(16+i*172,112,e,n,pr,q))
    p.append(G("Scrim",R(0,0,W,H,0,"#000000",op=.45)))
    p.append(G("Item bottom sheet",R(0,300,W,460,28,WHITE),R(162,310,36,4,2,"#E3DEDB"),R(16,336,72,72,18,PH),T(52,384,"🥤",36,500,INK,"middle"),
        T(104,360,"Coca-Cola 12 pk cans",16,800),T(104,378,"#1190334 · 2 per case",11,500,MUTED),pill(104,388,"Ad ends 30 Nov","wait")[0]))
    for i,(l,v,c) in enumerate([("Case cost","$17.96",INK),("Retail","$7.99",INK),("Margin","24%",GRN)]):
        x=16+i*112; p.append(G(f"Metric/{l}",R(x,430,104,56,14,BG),T(x+14,449,l,10,600,MUTED),T(x+14,473,v,17,800,c)))
    p.append(G("Suggestion",R(16,500,328,40,12,TINT),T(30,525,"Suggested 6 cases from your last 4 orders",11.5,600,ERR)))
    p.append(G("Quantity picker",C(116,596,20,WHITE),f'<circle cx="116" cy="596" r="20" fill="none" stroke="#E3DEDB" stroke-width="1.5"/>',T(116,603,"−",20,700,INK,"middle"),T(180,606,"5",30,800,INK,"middle"),C(244,596,20,RED),T(244,603,"+",20,700,WHITE,"middle"),T(300,600,"cases",11,500,MUTED)))
    p.append(btn(16,640,328,"Add to order · $89.80","red",52)); return p
def s_catalog():
    p=[R(0,0,W,H,0,BG)]
    p.append(f'<path d="M0 0H{W}V132a24 24 0 0 1 -24 24H24a24 24 0 0 1 -24 -24Z" fill="{RED}"/>')
    p+=[status(),T(20,58,"Catalog",21,800,WHITE),G("Search bar",R(16,76,328,44,14,WHITE),I('search',30,88,20,MUTED,2),T(58,103,"Search items, UPC or brand",13,500,MUTED),I('scan',312,88,20,RED,2)),chips(172,["All","Deals","New","Saved","Images"],0)]
    p.append(T(16,232,"Browse by",13,800))
    for i,(ic,l) in enumerate([('box','Department'),('tag','C&S category'),('list','Neilson category'),('tag','Deals')]):
        x=16+(i%2)*168; y=244+(i//2)*72
        p.append(G(f"Browse/{l}",R(x,y,160,62,16,WHITE,LINE),R(x+12,y+13,36,36,11,TINT),I(ic,x+21,y+22,18,RED,2),T(x+58,y+36,l,11.5,700)))
    p.append(T(16,414,"Deals this week",13,800))
    for i,(e,n,s,k) in enumerate([('🥣','Cheerios Family 18 oz','Save $2.10 per case',"Ad"),('🧀','Cheddar 8 oz','Save $1.40 per case',"Deal"),('🥛','2% Milk gal','Save $0.80 per case',"Deal")]):
        y=428+i*74
        p.append(G(f"Deal row/{n}",R(16,y,328,64,16,WHITE,LINE),R(26,y+10,44,44,12,PH),T(48,y+40,e,22,500,INK,"middle"),T(82,y+28,n,12.5,700),T(82,y+45,s,10.5,500,MUTED),pillr(332,y+22,k,"wait")))
    p.append(nav("Catalog")); return p
def s_review():
    p=[R(0,0,W,H,0,BG),header("Review & send","Store 4521")]
    p.append(G("Summary",R(16,112,328,64,16,WHITE,LINE),T(32,138,"2 orders ready",14,800),T(32,158,"Delivery Thu 20 Nov · 8 AM to noon",10.5,500,MUTED),T(328,146,"$1,926",18,800,RED,"end")))
    for i,(n,s,a) in enumerate([("Grocery","24 items · 14 cases","$1,284"),("Dairy","12 items · 6 cases","$642")]):
        y=188+i*66
        p.append(G(f"Order row/{n}",R(16,y,328,58,16,WHITE,LINE),R(26,y+11,36,36,11,TINT),I('box',35,y+20,18,RED,2),T(74,y+26,n,12.5,700),T(74,y+42,s,10.5,500,MUTED),T(328,y+34,a,13,800,INK,"end")))
    p.append(G("Timeline card",R(16,332,328,230,16,WHITE,LINE),T(32,358,"What happens next",12.5,800)))
    steps=[("Order sent","Today",True),("Approval","Usually within 1 hour",False),("Picked and loaded","Wed 19 Nov",False),("Delivered","Thu 20 Nov",False)]
    tl=[]
    for i,(t,s,d) in enumerate(steps):
        y=386+i*42
        if i<3: tl.append(f'<rect x="40" y="{y+14}" width="2" height="30" fill="#E3DEDB"/>')
        tl.append(C(41,y+6,9,RED if d else WHITE)); 
        if not d: tl.append(f'<circle cx="41" cy="{y+6}" r="8" fill="none" stroke="#E3DEDB" stroke-width="2"/>')
        else: tl.append(I('check',35,y,12,WHITE,3))
        tl+= [T(62,y+4,t,12,700),T(62,y+20,s,10.5,500,MUTED)]
    p.append(G("Timeline",*tl))
    p.append(bottombar(("Send 2 orders","red"))); return p
def s_orders():
    p=[R(0,0,W,H,0,BG),header("Orders","Store 4521",back=False),chips(108,["Needs approval","Sent","Drafts","Invoices"],0)]
    for i,(n,c,i2,a,k,t) in enumerate([("Grocery","Conf# 77120","24 items","$1,284","wait","Pending"),("Dairy","Conf# 77118","12 items","$642","wait","Pending"),("Produce","Conf# 77102","18 items","$512","ok","Approved"),("Frozen","Conf# 77090","9 items","$380","ok","Approved")]):
        y=156+i*88
        p.append(G(f"Order card/{n}",R(16,y,328,78,16,WHITE,LINE),T(32,y+28,n,14,800),T(32,y+48,f"{c} · {i2}",11,500,MUTED),pillr(328,y+14,t,k),T(328,y+56,a,16,800,INK,"end")))
    p.append(nav("Orders")); return p
def s_approval():
    p=[R(0,0,W,H,0,BG),header("Grocery · 77120","Submitted by 3381, 9:12 AM")]
    for i,(n,l) in enumerate([("24","Items"),("14","Cases"),("$1,284","Estimate")]):
        x=16+i*112; p.append(G(f"KPI/{l}",R(x,112,104,60,16,WHITE,LINE),T(x+52,138,n,18,800,"middle" and INK,"middle"),T(x+52,158,l,10.5,600,MUTED,"middle")))
    p.append(G("Warning",R(16,184,328,38,12,AMBBG),T(30,208,"3 items changed price since last order",11.5,700,AMB)))
    for i,(e,n,pr,q) in enumerate([('🥣','Cheerios Family 18 oz','$38.40 / case',3),('🥤','Coca-Cola 12 pk','$17.96 / case',5),('🥛','2% Milk gal','$14.28 / case',2)]):
        y=234+i*68
        p.append(G(f"Line/{n}",R(16,y,328,60,16,WHITE,LINE),R(26,y+10,40,40,11,PH),T(46,y+37,e,20,500,INK,"middle"),T(78,y+26,n,12,700),T(78,y+43,pr,10.5,500,MUTED),T(328,y+36,f"{q} cs",13,800,INK,"end")))
    p.append(field(16,446,328,"Add a note","Optional comment for the store",True))
    p.append(bottombar(("Reject","white"),("Approve","red"))); return p
def s_inbox():
    p=[R(0,0,W,H,0,BG),header("Inbox","4 unread",back=False)]
    p.append(G("Important alert",R(16,112,328,82,16,ERRBG),R(16,112,5,82,2,RED),T(34,136,"Important",12,800,ERR),T(328,136,"8:05 AM",10,500,ERR,"end"),T(34,158,"Holiday cutoff moves to Tuesday 6 PM.",11.5,600,INK),T(34,176,"Send your orders early.",11.5,500,INK)))
    for i,(t,s,d,u) in enumerate([("Price update","Dairy cost changes effective Monday","Yesterday",True),("Delivery","Thursday truck delayed 2 hours","Yesterday",True),("Welcome","Your store is set up for ordering","12 Nov",False)]):
        y=206+i*66
        p.append(row(y,'chat',t,s,T(328,y+24,d,10,500,MUTED,"end")+(C(322,y+40,4,RED) if u else "")))
    p.append(nav("Inbox")); return p
def s_login():
    p=[R(0,0,W,H,0,BG),f'<path d="M0 0H{W}V232a32 32 0 0 1 -32 32H32a32 32 0 0 1 -32 -32Z" fill="{RED}"/>',status(),
       G("Logo",R(24,70,52,52,15,WHITE),T(50,104,"MS",20,800,RED,"middle")),T(24,158,"Welcome back",26,800,WHITE),T(24,182,"Sign in to place and track store orders.",12.5,500,WHITE,op=.85),
       field(24,292,312,"User ID","3381"),field(24,356,312,"Password","••••••••••"),
       R(24,430,18,18,6,RED),I('check',27,433,12,WHITE,3.2),T(52,444,"Keep me signed in on this device",11.5,500,MUTED),
       btn(24,470,312,"Sign in","red",50),btn(24,530,312,"Use fingerprint","white",50),T(180,730,"Device setup complete · v4.2.0",10.5,500,MUTED,"middle")]
    return p
SCREENS=[("01-sign-in",s_login),("02-home",s_home),("03-order-type",s_ordertype),("04-order-filling",s_filling),("05-item-sheet",s_sheet),("06-catalog",s_catalog),("07-review-send",s_review),("08-orders",s_orders),("09-approval-detail",s_approval),("10-inbox",s_inbox)]
def svg(body,w,h): return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>'
over=[]
for i,(name,fn) in enumerate(SCREENS):
    inner="".join(fn())
    clip=f'<clipPath id="c{i}"><rect width="{W}" height="{H}" rx="0"/></clipPath>'
    one=svg(f'<defs>{clip}</defs><g clip-path="url(#c{i})" id="{name}">{inner}</g>',W,H)
    open(os.path.join(OUT,name+".svg"),"w").write(one)
    x=40+(i%5)*(W+40); y=80+(i//5)*(H+80)
    over.append(f'<defs>{clip}</defs><text x="{x}" y="{y-16}" font-family="{FONT}" font-size="16" font-weight="800" fill="{INK}">{name[3:].replace("-"," ").title()}</text><g transform="translate({x} {y})"><g clip-path="url(#c{i})" id="{name}">{inner}</g></g>')
ow=40+5*(W+40); oh=80+2*(H+80)
open(os.path.join(OUT,"00-overview.svg"),"w").write(svg(f'<rect width="{ow}" height="{oh}" fill="#EFEBE8"/><text x="40" y="44" font-family="{FONT}" font-size="22" font-weight="800" fill="{INK}">MarketSquare · Clean Retail (merged)</text>'+"".join(over),ow,oh))
print("ok")
