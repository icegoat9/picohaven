function _init()a=2ew()eb()e9()ev()nA()palt(2)music(1,1000)o"splash"end function _draw()local n=128-2*p clip(p,p,n,n)r()clip()end function _update60()if N<1then ek()else np=0for e in all(l)do
if(e.hp<=0and e~=n)e.x=-99
end if btnp(❎)and not X and nN then X,ej,i=true,i,e_ else i()end end ez()end function ez()ni+=1nm=flr(ni/eO)%4p=max(0,p-5)if ni%eC==0and#R>4and V<(#R-4)*6and not X then V+=1end end function ek()N=min(N+eT,1)for n in all(l)do n.ox,n.oy=n.sox*(1-N),n.soy*(1-N)if N==1then n.sox,n.soy=0,0
if(n.ephem)del(l,n)
end end end function o(n,e)Z=w w=n F,H=false,false d,f,nl=1,1,1nN=false p=e or 63v,J=0,eV
if(nR[n])nR[w]()
end function nn()
if(btnp(🅾️))o(K)
end function eB()nA()
if(Z~="splash")music(0)
ng=eY[a]e"ᶜc🅾️ᶜ6:begin"K,i,r="newturn",nn,nL end function nL()n0(0)nS()nq()n8(ng,21,4,10,6)nD()ne()end function eI()nF()e"ᶜ7----- new round -----\narrows:inspect enemies\nᶜc🅾️ᶜ6:choose action cards"d,f,H=n.x,n.y,true i,r=eE,B end function eE()k(10,10,0,0)
if(btnp(🅾️))o"choosecards"
end function k(t,o,n,e)n,e=n or 1,e or 1for n=1,4do if btnp(n-1)then d+=ny[n]f+=nx[n]break end end d,f=min(max(n,d),t),min(max(e,f),o)nl=(d-1)*o+f end function eG()j={}for n in all(c)do add(j,n)end n1(nw)add(j,nw)add(j,z";confirm;1;\nconfirm\n\nᶜ6confirm\nthe two\nselected\ncards")e"select 2 cards to play\n(or rest+card to burn)\nᶜc🅾️ᶜ6:select\nᶜc❎ᶜ6:review map"n.crds={}i,r=eA,eN end function eA()k(2,(#j+1)\2)
if(nl>#j)f-=1
if btnp(🅾️)then local f=j[nl]if f[3]==0then if m(n.crds,f)then del(n.crds,f)else if f[2]=="rest"then n.crds={}end if nl==#j then for e in all(n.crds)do e[3]=1end eR(n.crds)o"precombat"elseif#n.crds<2then add(n.crds,f)if L then
if(#n.crds==1)e"now select 2nd card."
if(#n.crds==2)e"select ᶜ7confirmᶜ6 if done."
end end end j[#j][3]=#n.crds==2and 0or 1end elseif btnp(❎)then o"newturn"end end function eN()n0(5)print("ᶜ6your deck:\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n¹f ¹7 ⁵fdlegend:",8,14)Y("discard",94,108,1)Y("burned",94,118,2)local e,o=eL(j)na({e,o},0,19,n.crds,9)
if(#n.crds<1)O("ᶜ61st card chosen\nsets ᶜ7initiative,ᶜ6\nlow:act first◆",61,3)
ne()end function eR(n)if n[1][2]=="rest"then eS="ᶜ8burnedᶜ6 ["..n[2][2].."]"n[2][3]=2deli(n,2)else add(n,{0,I"swift"and"😐3"or"😐2"})add(n,{0,I"barbs"and"█2∧"or"█2"})end end function eq()eD()E,nb=eF(),1e"enemy actions drawn..."if L then e(E[1][3].." will act first\n with initiative ᶜ7"..E[1][1])end e"ᶜc🅾️ᶜ6:continue to combat"K,i,r="actloop",nn,B end function eD()local e=eH()for n in all(e)do n.crds=rnd(nH[n.id])n.init=n.crds[1][1]end for n in all(l)do
if(n.type)n.crds=n.type.crds
n.init=n.crds[1][1]n.crdi=1end end function eH()local e={}for o in all(l)do
if(o~=n and not(m(e,o.type)))add(e,o.type)
end return e end function eJ()i=eK r=B end function eK()if n.hp<=0then nJ()return end if nb>#E then o("cleanup",0)return end M=E[nb][2]local f=l[M]nb+=1
if(f.hp<1)return
if f==n and n.crds[1]==nw then eM()n.stun=nil elseif f.stun then e(f.name..": ▥, turn skipped")f.stun=nil else if f==n then o("actplayerpre",0)else o("actenemy",0)end end end function eP()i=eQ r=B end function eQ()local n=l[M]if n.crdi>#n.crds then o("actloop",0)return end n.crd=nr(n.crds[n.crdi][2])n.crdi+=1if n.crd.act==u"m"then if n.crdi<=#n.crds then local e=nr(n.crds[n.crdi][2])
if(e.act==u"a")n.crd.rng=e.rng
end end nK(n)end function nM(n)local o=n.type.summon local f=nc(n,true)if#f>0then local d=rnd(f)nP(o,d.x,d.y)e(n.name.." ᶜ8callsᶜ6 "..G[o].name.." (ᶜ8-2♥ᶜ6)")P(n,2)end end function eU(e)t=nQ(n9(e,n),e.crd.val,e.crd.rng)if not t or#t<=1then t=nQ(n9(e,n,false,true),e.crd.val,e.crd.rng)end o("animmovestep",0)end function nQ(e,t,i)
if(not e)return e
local d for f,o in ipairs(e)do local e=nu(o.x,o.y,true)if f==1or e and f<=t+1then d=f
if(Q(o,n)<=i and n2(o,n))break
end end return{unpack(e,1,d)}end function nu(n,e,f,d,t,i)
if(fget(mget(n,e),1)or no(n,e))return false
if(fget(mget(n,e),2)and(f or not d))return false
local o=nv(n,e)
if(f and o>0and t~=o)return false
if((i or t==1)and o>1and not d)return false
return true end function nc(n,t,i,l)local e={}for o=1,4do local f,d=n.x+ny[o],n.y+nx[o]if nu(f,d,t,i,nil,l)then add(e,nf(f,d))end end return e end function nU(d,o)local t=d.crd local l,a=t.stun,t.wound local f=t.val if d==n then local n=eW()e("you draw modifier ᶜ7"..n)
if(L)e" (custom dmg mod deck)"
if n=="*2"then f*=2ns()np=3elseif n=="/2"then f\=2ns()else if n[-1]=="▥"then t.stun=true n=sub(n,1,#n-1)elseif n[-1]=="∧"then t.wound=true n=sub(n,1,#n-1)end f+=tonum(n)end end sfx(12)local i=d.name.." █ "..o.name..":"if o==n and I("shld",true)then n.shld+=2e"ᶜ7great shield usedᶜ6: +★2"end if o.shld>0then i..=f.."-"..o.shld.."★:"f=max(0,f-o.shld)end i..="ᶜ8-"..f.."♥ᶜ6"if d.crd.stun then i..="▥"o.stun=true end if d.crd.wound then i..="∧"o.wound=true end t.stun,t.wound=l,a e(i)local n=144+f
if(f>9)n=154
nk(nil,o.x,o.y,d.x,d.y,n)P(o,f)end function eW()if#A==0then ns()end local n=rnd(A)add(nj,n)del(A,n)return n end function eX(e)if Q(e,n)<=e.crd.rng and n2(e,n)then nU(e,n)end end function nW(n,f)local o=min(f,n.maxhp-n.hp)n.hp+=o e(n.name.." healed ᶜ8+"..o.."♥")n.wound=nil end function P(o,f)o.hp-=f if o.hp<=0then if o==n then if I("life",true)then o.hp,o.wound=1,false e"ᶜ7your life charm glows\n and you survive @ 1hp"else local n=rnd(U())if n then n[3]=2o.hp+=f e("you ᶜ8burnᶜ6 a random card\nᶜ8[ᶜ6"..n[2].."ᶜ8]ᶜ6 to avoid death")end end else e("ᶜ7"..o.name.." is defeated!")
if(L)e" and drops a coin (●)"
local f=57local e=mget(o.x,o.y)
if(e>=57and e<=58)f=e+1
if(e==59)f=e
mset(o.x,o.y,f)n.xp+=1end end end function eZ()n.actionsleft=2o("actplayer",0)end function on()n_(n)if n.actionsleft==0then n.crds,n.init=nil o("actloop",0)return end e("ᶜc⬆️⬇️,🅾️ᶜ6:choose card "..3-n.actionsleft)
if(L)e" or dflt act █2 / 😐2 ◆"
i=o0 r=B end function o0()k(1,#n.crds)if btnp(🅾️)then local e=n.crds[f]nX,oe=e,m(n.crds,e)n.crd=nr(e[2])
if(I"goggl"and n.crd.rng and n.crd.rng>1)n.crd.rng+=2
n.actionsleft-=1nK(n)
if(n.crd.burn)e[3]=2
del(n.crds,e)end end function nK(d)local f=d.crd if f.act==u"m"then if d==n then o("actplayermove",0)else eU(d)end elseif f.aoe==8then local n=b("x;-1;y;-1|x;0;y;-1|x;1;y;-1|x;-1;y;0|x;1;y;0|x;-1;y;1|x;0;y;1|x;1;y;1",true)foreach(n,o1)foreach(n,nz)o("actplayer",0)elseif f.act==u"a"then if d==n then o("actplayerattack",0)else eX(d)end else
if(f.act==u"h")nW(d,f.val)
if f.act==u"s"then d.shld+=f.val e(d.name.." ★+"..f.val)elseif f.act==u"l"and d==n then e("looting treasure @➡️"..f.val)oo(f.val)elseif f.act=="hail▒"then foreach(nZ(n,f.rng),nz)elseif f.act=="howl"then e(d.name.." howls.. ᶜ8-1♥,▥")P(n,1)n.stun=true elseif f.act=="call"then nM(d)end
if(d==n)o("actplayer",0)
end
if(f.burn)n.xp+=2
end function o1(e)e.x+=n.x e.y+=n.y end function nz(e)local o=nv(e.x,e.y)if o>1then nU(n,l[o])else nk(nil,e.x,e.y,n.x,n.y,2)end end function nZ(e,n)local f={}for o=-n,n do for i=-n,n do local d,t=e.x+o,e.y+i local o=nf(d,t)
if(not no(d,t)and Q(e,o)<=n and n2(e,o))add(f,o)
end end return f end function eM()n.actionsleft=0e"you take a ᶜ7long restᶜ6:"foreach(c,n1)foreach(h,n1)nW(n,3)e(eS)end function en(f,d)local o=mget(f,d)if fget(o,5)then if o>=57and o<=59then local f=of*(o-56)n.gold+=f e("picked up "..f.."● (gold)")elseif o==37then if a==15then e0+=1e"you find a map piece!"else local f=rnd(od[C])local d,o=f[1],f[2]if d=="g"then n.gold+=o e("you find "..o.."●!")elseif d=="d"then e("chest is trapped! ᶜ8-"..o.."♥")P(n,o)end end end mset(f,d,33)end end function oo(o)for e in all(nZ(n,o))do en(e.x,e.y)end end function ot()H=true d,f=n.x,n.y t={nf(d,f)}
if(I"belt")n.crd.jmp=true
e("move up to "..n.crd.val)
if(L)e" (ᶜc🅾️ᶜ6:confirm, ᶜc❎ᶜ6:undo)"
i=oi r=B end function oi()local i,l=d,f k(10,10,0,0)if d~=i or f~=l then if#t>=2and t[#t-1].x==d and t[#t-1].y==f then deli(t,#t)elseif#t>n.crd.val or not nu(d,f,false,n.crd.jmp,1)then d,f=i,l else add(t,nf(d,f))end end F=#t-1<=n.crd.val and nu(d,f,true,false,1)if btnp(🅾️)then if F then
if(#t>1)sfx(11)
o("animmovestep",0)else e"invalid move"end elseif btnp(❎)then ee()end end function ee()n.actionsleft+=1t={}nX[3]=1add(n.crds,nX,oe)o"actplayer"end function ol()local n=l[M]if not t or#t<=1then t={}if M==1then o("actplayer",0)else o("actenemy",0)end else local e,o=t[1].x,t[1].y local f,d=t[2].x,t[2].y nk(n,f,d,e,o)i=oa n_(n,n.crd.jmp)end end function n_(f,d)local n,o=f.x,f.y if fget(mget(n,o),4)then if mget(n,o)==43and not d then e(f.name.." @ trap! ᶜ8-"..e1.."♥")P(f,e1)mset(n,o,33)end if fget(mget(n,o),7)then for e=1,4do eo(n+ny[e],o+nx[e])end ef()nO-=1mset(n,o,33)end end end function oa()deli(t,1)o("animmovestep",0)end function oc()H=true d,f=n.x,n.y e"select attack target"
if(L)e" (ᶜc🅾️ᶜ6:confirm, ᶜc❎ᶜ6:undo)"
i=ou r=B end function ou()k(10,10,0,0)local t=nf(d,f)local i=Q(n,t)local l=n.crd F=i<=l.rng and i>0and not no(d,f)and n2(n,t)if btnp(🅾️)then if F then nz(t)o("actplayer",0)else e" invalid target"end elseif btnp(❎)then ee()end end function o2()for o in all(l)do nC(o)
if(o.type)nC(o.type)
if o.wound and o.hp>0then e(o.name.." ∧:ᶜ8-1♥")P(o,1)end o.shld=o.pshld n_(o)
if(o.hp<=0and o~=n)del(l,o)
end en(n.x,n.y)local n=m(l,"noah","name")if a==18and ed()and not et then local o=l[n]et=true o.type.id+=1e"ᶜcthe blue barriers\n ᶜcdissipate and noah\n ᶜchowls with rage."ei()nM(o)end if#l==1and nO==0or ed()and(a==12or a==15)or a==18and not n then ei()os()elseif oh()then nJ()else if#U()<2then local n=o5()e("ᶜchand emptyᶜ6: you short\nrest, redraw, and ᶜ8burn\nrandom card: ᶜ8[ᶜ6"..n.."ᶜ8]")end e"ᶜc❎ᶜ6:'review msg' mode\nᶜc🅾️ᶜ6:next round"nN=true K,i="newturn",nn r=B end end function ei()for n=0,10do for e=0,10do
if(mget(n,e)==48)mset(n,e,33)
end end end function ed()if a==12or a==18then return not m(l,"rune","name")elseif a==15then return e0==4end end function o5()foreach(c,n1)local n=rnd(U())n[3]=2return n[2]end function U(o)local e={}for n in all(c)do
if(n[3]==0or o and n[3]==1)add(e,n)
end return e end function e_()if btnp(❎)or btnp(🅾️)then i,X=ej elseif btn(⬆️)then V=max(V-1,0)elseif btn(⬇️)and#R>4then V=min(V+1,(#R-4)*6)end end function o3()el()e"ᶜc🅾️ᶜ6:end of scenario"K,i="pretown",nn end function o6()e"ᶜc🅾️ᶜ6:return to town"K,r="town",nL i=nn end function os()local f=g[a]n.xp+=f.xp n.gold+=f.gp e("ᶜ7 victory!  ᶜ6(+"..f.xp.."xp)")
if(f.gp>0)e(" you are paid ●"..f.gp)
ng=o4[a]f.unlocked=false for n in all(split(f.unlocks))do
if(n~="")g[tonum(n)].unlocked=true
end
if(a==18)nT=true
if(a==14)add(h,ea)
o("endlevel",0)end function oh()
if(n.hp<=0)return true
if(#U(true)<2)return true
if(#U(true)==2and#U()<2)return true
end function nJ()e"ᶜ8you are exhausted"ng="defeated, you hobble back to town to nurse your wounds and plan a return."o("endlevel",0)end function n0(n)rectfill(0,0,127,127,n)end function B()n0(0)nS()nq()o7()nD()ne()end function nS()print(sub(g[a].name,1,15),0,0,7)O("♥"..n.hp.."/"..n.maxhp,66,0,8)end function ne()local n=X and 12or 13nh(v,99,v+J-1,127,5,n)clip(max(v,p)+1,max(101,p),min(v+J,127-2*p)-max(v,p)-2,126-2*p-max(101,p))n5(R,v,99-V,J,29,2,5)clip()
if(X)O("ᶜc⬆️\n\n\n\n⁴e⬇️",v+J-3,100)
end function nq()nh(0,6,91,97,0,5)end function o7()camera(rnd(np),rnd(np))for n=0,10do for e=0,10do local o=mget(n,e)
if(fget(mget(n,e),3))o+=nm
if(no(n,e))o=39
spr(o,2+8*n,8+8*e)end end camera(0,0)foreach(l,er)if#t>1then local e,o=t[1].x,t[1].y for n in all(t)do line(6+8*e,12+8*o,6+8*n.x,12+8*n.y,12)e,o=n.x,n.y end circfill(6+8*e,12+8*o,1,12)end
if(H)op()
end function er(e)local o=e.noanim and 0or nm if e.stun then o=0pal(z("1;12;3;12;4;12;5;12;6;12;7;12;13;12",false,true))end spr(e.spr+o,2+8*e.x+e.ox,8+8*e.y+e.oy)pal()palt(2)
if(e~=n and not e.ephem)er(n)
end function op()local n,e=1+d*8,7+f*8
if(not F)fillp(23130)
rect(n,e,n+9,e+9,12)fillp()end function om(n,e,d,o)local f=l[d]
if(not o)nV(n,e,f,o)
local d=f.type.crds if d and#d>=1then local o={}for n in all(d)do add(o,n[2])end n5(o,n+10,e+10,25,15,nil,nil,1)O(f.type.init.."³f:",n+2,e+15,7)end
if(o)nV(n,e,f,o)
end function nV(d,t,e,i)local f={"   "..e.name}local l,a=13,22local r="?/"..e.maxhp local o="\n⁴b ³e"
if(e.wound)o..="∧ ³f"
if(e.stun)o..="▥ ³f"
if(e.shld>0)o..="★"..e.shld
if e==n then a=37
if(n.init)add(f,"\n⁴d ³eᶜ7"..n.init..":")
add(f,"\n"..o)if#h>0then o="\n\n⁴d ³e"for n in all(h)do o..=n[5]end add(f,o)end else if i then r=e.hp e.type.hpdrawn=true l=12end add(f,"   ♥"..r)
if(i)add(f,o)
end n5(f,d,t,33,a,nil,l)spr(e.spr,d+2,t+2)end function og()local e,o=nB+2,ec+7nV(nB,ec,n)if w=="precombat"or w=="actenemy"or w=="actloop"or w=="animmovestep"and M~=1then if n.crds then for f=1,min(#n.crds,2)do Y(n.crds[f],e,o+10*f)end end elseif sub(w,1,9)=="actplayer"or w=="animmovestep"and M==1then for d,t in ipairs(n.crds)do local n=0
if(t[1]==0)n=5
local i=d==f and w=="actplayer"Y(t,e,o-10+10*d,n,i)fillp()end end end function Y(o,f,d,n,m,a,u)local r=o if not u then if a then r=o8(o)else
if(type(o)=="table")r=o[2]
end end local e,i,l,c,s=13,1,6local t,h,p=32,9,1
if(n==9)n=o[3]
if a then t,h,p=39,67,3else
if(n==1)e,l,c=0,5,true
if(n==2)e,i,l,c=0,130,0,true
if(n==3)e=5
if(n==4)e=12
if(n==5)i=0
if(m)s=12
end n5(r,f,d,t,h,p,e,i,l,c,s)if a and not u then line(f,d+18,f+t-1,d+18,e)circfill(f+t-2,d-1,7,i)circ(f+t-2,d-1,7,e)print(o[1],f+t-5,d-3,l)end end function o8(o)local n=nr(o[2])local e={"ᶜ7"..o[4],"",""}if not n.special then nY(e,oy[n.act]..n.val)
if(n.jmp)add(e," jump")
if(n.rng>1)add(e," @ rng "..n.rng)
if(n.wound)add(e," ᶜ8wound")
if(n.stun)add(e," ᶜcstun")
if(n.aoe)nY(e,"multiple\n targets")
if(n.burn)add(e,"\nᶜ8burnᶜ6 crd\n on use")
end return e end function nD()local o={}for t,e in ipairs(l)do if e~=n and not e.ephem then local n=e.name
if(not m(o,n))add(o,n)
local i=eu*m(o,n)-eu local n=nv(d,f)==t and H if not e.type.hpdrawn then om(nB,i,t,n)end end end for n in all(G)do n.hpdrawn=false end og()end function ox()poke(22016,unpack(split"4,6,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,7,7,7,7,0,0,0,0,7,7,7,0,0,0,0,0,7,5,7,0,0,0,0,0,5,2,5,0,0,0,0,0,5,0,5,0,0,0,0,0,5,5,5,0,0,0,0,4,6,7,6,4,0,0,0,1,3,7,3,1,0,0,0,7,1,1,1,0,0,0,0,0,4,4,4,7,0,0,0,5,7,2,7,2,0,0,0,0,0,2,0,0,0,0,0,0,0,0,1,2,0,0,0,0,0,0,3,3,0,0,0,5,5,0,0,0,0,0,0,2,5,2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,2,0,0,0,5,5,0,0,0,0,0,0,5,7,5,7,5,0,0,0,7,3,6,7,2,0,0,0,5,4,2,1,5,0,0,0,3,3,6,5,7,0,0,0,2,1,0,0,0,0,0,0,2,1,1,1,2,0,0,0,2,4,4,4,2,0,0,0,5,2,7,2,5,0,0,0,0,2,7,2,0,0,0,0,0,0,0,2,1,0,0,0,0,0,7,0,0,0,0,0,0,0,0,0,2,0,0,0,4,2,2,2,1,0,0,0,7,5,5,5,7,0,0,0,3,2,2,2,7,0,0,0,7,4,7,1,7,0,0,0,7,4,6,4,7,0,0,0,5,5,7,4,4,0,0,0,7,1,7,4,7,0,0,0,1,1,7,5,7,0,0,0,7,4,4,4,4,0,0,0,7,5,7,5,7,0,0,0,7,5,7,4,4,0,0,0,0,2,0,2,0,0,0,0,0,2,0,2,1,0,0,0,4,2,1,2,4,0,0,0,0,7,0,7,0,0,0,0,1,2,4,2,1,0,0,0,7,4,6,0,2,0,0,0,2,5,5,1,6,0,0,0,0,6,5,7,5,0,0,0,0,3,3,5,7,0,0,0,0,6,1,1,6,0,0,0,0,3,5,5,3,0,0,0,0,7,3,1,6,0,0,0,0,7,3,1,1,0,0,0,0,6,1,5,7,0,0,0,0,5,5,7,5,0,0,0,0,7,2,2,7,0,0,0,0,7,2,2,3,0,0,0,0,5,3,5,5,0,0,0,0,1,1,1,6,0,0,0,0,7,7,5,5,0,0,0,0,3,5,5,5,0,0,0,0,6,5,5,3,0,0,0,0,6,5,7,1,0,0,0,0,2,5,3,6,0,0,0,0,3,5,3,5,0,0,0,0,6,1,4,3,0,0,0,0,7,2,2,2,0,0,0,0,5,5,5,6,0,0,0,0,5,5,7,2,0,0,0,0,5,5,7,7,0,0,0,0,5,2,2,5,0,0,0,0,5,7,4,3,0,0,0,0,7,4,1,7,0,0,0,3,1,1,1,3,0,0,0,1,2,2,2,4,0,0,0,6,4,4,4,6,0,0,0,2,5,0,0,0,0,0,0,0,0,0,0,7,0,0,0,2,4,0,0,0,0,0,0,7,5,7,5,5,0,0,0,7,5,3,5,7,0,0,0,6,1,1,1,6,0,0,0,3,5,5,5,7,0,0,0,7,1,3,1,7,0,0,0,7,1,3,1,1,0,0,0,6,1,1,5,7,0,0,0,5,5,7,5,5,0,0,0,7,2,2,2,7,0,0,0,7,2,2,2,3,0,0,0,5,5,3,5,5,0,0,0,1,1,1,1,7,0,0,0,7,7,5,5,5,0,0,0,3,5,5,5,5,0,0,0,6,5,5,5,3,0,0,0,7,5,7,1,1,0,0,0,2,5,5,3,6,0,0,0,7,5,3,5,5,0,0,0,6,1,7,4,3,0,0,0,7,2,2,2,2,0,0,0,5,5,5,5,6,0,0,0,5,5,5,7,2,0,0,0,5,5,5,7,7,0,0,0,5,5,2,5,5,0,0,0,5,5,7,4,7,0,0,0,7,4,2,1,7,0,0,0,6,2,3,2,6,0,0,0,2,2,2,2,2,0,0,0,3,2,6,2,3,0,0,0,0,4,7,1,0,0,0,0,0,2,5,2,0,0,0,0,16,8,5,2,5,0,0,0,17,10,4,10,17,0,0,0,0,0,4,0,0,0,0,0,0,31,14,4,0,0,0,0,21,0,21,0,21,0,0,0,14,23,31,31,14,0,0,0,14,31,31,31,14,0,0,0,10,31,31,14,4,0,0,0,21,0,0,0,0,0,0,0,6,9,9,29,9,0,0,0,0,0,0,0,31,0,0,0,4,14,21,4,31,0,0,0,3,3,15,31,31,0,0,0,3,3,15,31,0,0,0,0,14,17,21,17,14,0,0,0,4,12,31,12,4,0,0,0,0,0,4,2,1,0,0,0,23,12,28,18,17,0,0,0,31,31,31,14,4,0,0,0,4,0,17,0,4,0,0,0,0,4,14,31,0,0,0,0,0,0,0,0,0,0,0,0,4,14,23,31,14,0,0,0,14,21,27,21,14,0,0,0,0,0,31,0,0,0,0,0,21,4,31,4,21,0,0,0,18,9,5,18,13,0,0,0,4,17,4,17,4,0,0,0,0,10,31,10,0,0,0,0,14,31,31,14,14,0,0,0,16,24,13,6,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,1,0,16,8,0,0,0,0,0,4,0,0,0,0,0,0,0,10,0,0,0,0,0,0,14,21,14,4,0,0,0,16,24,12,4,0,0,0,0"))e2=z(" ; ³f;:;³f:;█;ᶜ6█;▒;ᶜ8▒;🐱;_;⬇️;ᶜc⬇️;░;ᶜ8░³aᶜ6🐱;✽;_;●;ᶜ6●³aᶜd✽;♥;ᶜ8♥;☉;ᶜ8☉³aᶜ6🐱;웃;ᶜ6웃;⌂;_;⬅️;ᶜ6⬅️³aᶜ9⌂;😐;ᶜ6😐³aᶜ4♪;♪;_;🅾️;ᶜc🅾️;◆;ᶜ6◆;…;_;➡️;ᶜ6➡️³aᶜ4…;★;ᶜ6★;⧗;ᶜ8⧗³aᶜ6🐱;⬆️;ᶜc⬆️;∧;ᶜ8∧;❎;ᶜc❎;▤;ᶜ8▤;▥;ᶜc▥;あ;あ³aᶜ8ち;い;い³aᶜ8つ;う;う³aᶜ1て;え;え³aᶜdと;お;ᶜ1お³aᶜ7な",false,true)end function O(o,n,d,e)e=e or 6local f="ᵉ"for d=1,#o do local n=o[d]if n==" "then n=" ³f"elseif e2[n]and e==6then n=e2[n].."ᶜ"..e end f..=n end print(f,n,d,e)end function u(n)return chr(ord(n)+31)end function n8(n,f,d,e,t)local o=split(n,"\n")for n in all(o)do while#n>f do local o=f+1while n[o]~=" "do o-=1end print(sub(n,1,o),d,e,t)n=sub(n,o+1)e+=6end print(sub(n,1,f),d,e,t)e+=9end end function n5(n,e,o,a,f,d,t,i,l,c,r)d=d or 1t=t or 13i=i or 5l=l or 6
if(type(n)~="table")n={n}
f=f or#n*6+3
if(c)fillp(23130)
nh(e,o,e+a-1,o+f-1,i,t)fillp()for f,t in ipairs(n)do O(t,e+d+1,o+d-5+6*f,l)end
if(r)rect(e-1,o-1,e+a,o+f,r)
end function na(n,e,c,o,l,t,i)o=o or{}t=t or 36e=e or 0local u=l==3and 8or 10for i=1,#n do for a,r in ipairs(n[i])do local s=e+8+(i-1)*t local e=c+5+(a-1)*u local n=l
if(m(o,r))n=4
local o=i==d and a==f Y(r,s,e,n,o)end end if d>0and f>0then local e=n[d][f]
if(i)e=es(e)
Y(e,85,24,0,true,true,i)end end function eh(o,n,i,e)e=e or 6for d,t in ipairs(o)do local o=i+(d-1)*8O(t,n,o,e)if f==d then rect(n-2,o-2,n+#t*4,o+6,12)end end end function e(n)nY(R,n)end function nF()R={}V=0end function nh(n,e,o,f,d,t)rectfill(n,e,o,f,d)rect(n,e,o,f,t)end function n2(n,e)local o=n9(n,e,true)return o and#o-1==Q(n,e)end function nr(o)local n={}local e=split(o,"")if e[#e]==u"b"then n.burn=true deli(e,#e)end if tonum(e[2])==nil then n.special=true n.act=o
if(o=="hail▒")n.val,n.rng=5,3
else n.act=e[1]n.val=e[2]
if(n.val==9)n.val=99
if#e>=3then n.mod=e[3]if#e>=4then if tonum(e[4])==nil then n.mod2=e[4]else n.modval=e[4]
if(#e>=5)n.mod2=e[5]
end end end
if(n.mod==u"j")n.jmp=true
n.rng=1
if(n.mod==u"r")n.rng=n.modval
if(e[#e]==u"e")n.aoe=8
if(n.mod==u"z"or n.mod2==u"z")n.stun=true
if(n.mod==u"w"or n.mod2==u"w")n.wound=true
end return n end function ns()while#nj>0do add(A,deli(nj))end end function el()for n in all(c)do n[3]=0end ns()end function n1(n)
if(n[3]==1)n[3]=0
end function nC(n)n.crds,n.init,n.crd=nil end function eL(n)local e={unpack(n,1,ceil(#n/2))}local o={unpack(n,ceil(#n/2)+1)}return e,o end function m(d,n,e)for o,f in ipairs(d)do if not e then
if(f==n)return o
else
if(f[e]==n)return o
end end end function nI(e)for o=1,#e do local n=o while n>1and tonum(e[n-1][1])>tonum(e[n][1])do e[n],e[n-1]=e[n-1],e[n]n-=1end end end function nf(n,e)return{x=n,y=e}end function ow(o)local n={}for e in all(o)do n[e]=(n[e]or 0)+1end return n end function nY(e,n)if type(n)~="table"then n=split(n,"\n")end for o in all(n)do add(e,o)end end function nv(e,o)for f,n in ipairs(l)do
if(n.x==e and n.y==o)return f
end return 0end function eF()E={}for e,n in ipairs(l)do add(E,{n.init,e,n.name})end nI(E)return E end function I(e,o)local n=m(h,e,6)
if(not n or h[n][3]~=0)return false
if(o)h[n][3]=1
return true end function nk(n,e,o,f,d,t)n=n or add(l,{spr=t,noanim=true,ephem=true})n.x,n.y=e,o n.sox,n.soy=8*(f-e),8*(d-o)n.ox,n.oy=n.sox,n.soy N=0end function Q(n,e)return abs(n.x-e.x)+abs(n.y-e.y)end function ob()e5=b"1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1"end function no(n,e)return n<0or n>10or e<0or e>10or e5[n+1][e+1]end function o9(n,e)e5[n+1][e+1]=false end function eo(e,o)
if(fget(mget(e,o),6))return
local f,d,t,i=10,10,0,0for n=0,10do if fget(mget(n,o),6)then if n<e then t=n else f=min(n,f)end end if fget(mget(e,n),6)then if n<o then i=n else d=min(n,d)end end end for n=t,f do for e=i,d do o9(n,e)end end end function z(o,f,d)local e={}local n=split(o,";",not f)if d then for o=1,#n,2do e[n[o]]=n[o+1]end return e end return n end function b(e,o)local f,n=split(e,"/"),{}for e,d in ipairs(f)do add(n,{})local f=split(d,"|")for d in all(f)do add(n[e],z(d,nil,o))end end while#n==1do n=n[1]end return n end function e3(n)local e=""while@n~=255do e..=chr(@n)n-=1end return e end function ew()ox()oy=b("█;atk ;😐;move ;♥;heal ;●;gold ;웃;jump;➡️;@ rng ;⬅️;get all\ntreasure\nwithin\nrange ➡️;★;shld ;∧;wound;▥;stun;▒;burn;░;adjacent",true)end function eb()eV,v,V,nB,eu,ec=92,0,0,93,27,81eO,nm,ni,N,p=15,0,0,1,0eC,eT=4,.05n3=b("txt;●easier● ;hp;-2;gp;1|txt;★normal★ ;hp;0;gp;1|txt;▥harder▥ ;hp;+2;gp;2|txt;▒brutal▒ ;hp;+5;gp;3",true)C=2ny,nx=split"-1,1,0,0",split"0,0,-1,1"R={}w,Z,K="","",""nR={newlevel=eB,splash=ov,town=ok,endlevel=o3,newturn=eI,choosecards=eG,precombat=eq,actloop=eJ,actenemy=eP,actplayerpre=eZ,actplayer=on,actplayermove=ot,animmovestep=ol,actplayerattack=oc,cleanup=o2,profile=oj,upgradedeck=o_,upgrademod=oz,store=oO,pretown=o6}end function nA()of,e1=n3[C].gp,4e0=0oC(a)ob()l={n}
if(I"mail")n.pshld=1
n.shld,n.stun,n.wound,n.hp=n.pshld,false,false,n.maxhp oT()eo(n.x,n.y)ef()t={}el()foreach(h,n1)d,f,H,F=n.x,n.y,true,false et=false G[#G].id=#G foreach(G,nC)L=a<7nF()end function oC(n)for e=0,10do for o=0,10do mset(e,o,mget(e+g[n].x0,o+g[n].y0))end end end function oT()nO=0for e=0,10do for o=0,10do if mget(e,o)==1then mset(e,o,33)n.x,n.y=e,o end
if(fget(mget(e,o),7))nO+=1
end end end function ef()for n=0,10do for e=0,10do for o,f in ipairs(G)do if f.spr==mget(n,e)and not no(n,e)then nP(o,n,e)mset(n,e,33)end end end end end function nP(n,o,f)local e=G[n]local n={type=e,x=o,y=f,ox=0,oy=0,sox=0,soy=0,maxhp=e.maxhp+n3[C].hp,spr=e.spr,name=e.name,pshld=e.pshld}
if(e.name=="elem"and I"slvst")n.pshld=0
n.shld,n.hp=n.pshld,n.maxhp
if(n.hp>0)add(l,n)
end function e9()g=b("name;test level;x0;11;y0;0;unlocks;2;xp;150;gp;150|name;unnamed tomb;x0;22;y0;0;unlocks;3,4;xp;60;gp;0|name;elgin mausoleum;x0;33;y0;0;unlocks;7,8;xp;30;gp;0|name;another tomb;x0;44;y0;0;unlocks;5;xp;10;gp;0|name;another tomb ;x0;55;y0;0;unlocks;6;xp;10;gp;0|name;another tomb  ;x0;66;y0;0;unlocks;4;xp;10;gp;0|name;elgin manor road;x0;77;y0;0;unlocks;11;xp;30;gp;0|name;job: guard caravan;x0;88;y0;0;unlocks;9;xp;20;gp;30|name;job: rescue hunter;x0;99;y0;0;unlocks;;xp;20;gp;20|name;job: defeat bandits;x0;110;y0;0;unlocks;;xp;20;gp;30|name;elgin manor;x0;0;y0;11;unlocks;12,13;xp;40;gp;0|name;mage guild;x0;11;y0;11;unlocks;14,15;xp;30;gp;30|name;ruined chapel;x0;22;y0;11;unlocks;17;xp;60;gp;0|name;mountain pass;x0;33;y0;11;unlocks;;xp;20;gp;0|name;guild library;x0;44;y0;11;unlocks;16;xp;20;gp;0|name;sewers;x0;55;y0;11;unlocks;17;xp;20;gp;0|name;catacombs;x0;66;y0;11;unlocks;18;xp;40;gp;0|name;lower catacombs;x0;77;y0;11;unlocks;;xp;100;gp;0",true)g[a].unlocked=true o4=z(e3(8191))eY=z(e3(17151))od=b"g;10|g;8|g;7|g;6|g;5/g;10|g;8|g;7|g;6|g;5|d;2/g;20|g;15|g;15|g;10|g;10|d;4/g;30|g;20|g;15|d;6"G=b("id;1;name;skel;spr;116;maxhp;4;pshld;0|id;2;name;zomb;spr;112;maxhp;8;pshld;0|id;3;name;skel+;spr;88;maxhp;6;pshld;1|id;4;name;zomb+;spr;84;maxhp;12;pshld;0|id;5;name;sklar;spr;120;maxhp;3;pshld;0|id;6;name;cult;spr;100;maxhp;6;summon;1;pshld;0|id;7;name;bandt;spr;128;maxhp;6;pshld;0|id;8;name;archr;spr;132;maxhp;4;pshld;0|id;9;name;wolf;spr;96;maxhp;5;pshld;0|id;10;name;warg;spr;104;maxhp;9;pshld;1|id;11;name;drake;spr;124;maxhp;15;pshld;2|id;12;name;elem;spr;108;maxhp;15;pshld;8|id;13;name;rune;spr;92;maxhp;5;pshld;0|id;14;name;noah;spr;140;maxhp;18;summon;12;pshld;0",true)oV="57;😐3|;█3/60;😐1|;█4/30;😐2|;♥2/21;😐3|;█2/19;😐2|;█2,78;█6/72;😐1|;█4/56;😐1|;█2∧/67;😐1|;█5,57;😐4|;█4/60;😐2|;█5/30;😐3|;♥3/21;😐4|;█3/19;😐3|;█3,78;█8/72;😐1|;█6/56;😐2|;█3∧/67;😐1|;█5∧,21;😐1|;█2➡️3/40;█3➡️3/50;😐1|;█1➡️4∧/70;█3➡️3/37;😐1|;█1➡️3,40;😐1|;█1/30;😐1|;█2/90;call,40;😐2|;█3/55;😐1|;█4/28;😐3|;█2/21;★2|;😐2/28;★2|;♥2,24;😐1|;█2➡️4/40;█3➡️4/50;😐1|;█1➡️6∧/36;😐1|;█2➡️5,65;howl/11;😐4|;█3/22;😐5|;█2/35;😐4|;█2∧,60;howl/8;😐4|;█4∧/17;😐5|;█2∧/20;😐4|;█3∧,57;😐1|;█3/60;😐1|;█4/72;😐1|;♥2/38;█6➡️3/31;😐2|;█2,78;😐1|;█5/72;😐1|;█4/53;😐2/60;😐1|;█3➡️3,95;█1|;♥1/95;█1|;♥1,40;█3➡️4/53;█2➡️5/70;♥1|;█1➡️7/60;█1➡️6∧/43;█1➡️6▥,43;call/40;😐3|;█3➡️4/53;😐1|;█2➡️5/70;♥1|;█1➡️7/60;😐2|;█2➡️6/43;😐1|;█1➡️6▥,40;😐3|;█3➡️4/53;😐1|;█2➡️5/70;♥1|;█1➡️7/60;😐2|;█2➡️6/43;😐1|;█1➡️6▥/85;♥3"nH={}for n in all(split(oV))do add(nH,b(n))end n=b("name;you;spr;66;bigspr;64;lvl;1;xp;0;gold;10;maxhp;10;pshld;0;ox;0;oy;0;sox;0;soy;0",true)S=b"15;😐2;0;\n  dash|35;😐3웃;0;\n  leap|45;█3;0;\n  chop|20;█2;0;\n   jab|42;█2➡️3;0; spare\n dagger|65;♥4▒;0; first\n  aid|60;█2;0;\n  stab|18;★2;0; braced\n stance|60;😐4;0;\nsidestep|70;█5➡️2▒;0;  hurl\n  sword|80;⬅️1;0;  loot\nlocally|45;█4;0;\n slash|31;😐5웃;0; mighty\n  leap|80;⬅️4▒;0; gather\ngreedily|41;█3░;0;\n stomp|17;█2▥;0;\nconcuss|65;█3➡️3;0;\njavelin|11;★4;0;\n  defy|34;█3∧;0;\n lance|64;█8▒;0; mighty\n swing|38;█4∧░▒;0; blade\ntornado|73;😐6웃;0; up and\n  over|46;♥3;0;bandage\n  self|34;█6;0; expert\n  blow|40;█7▥▒;0; giant\n killer|28;hail▒;0;hail of\nblades\n\nᶜ6█5 all\n enemies\n within\n rng ➡️3\n\nᶜ8burnᶜ6 crd\n on use|62;♥99▒;0;  rise\n again|99;rest;0;  long\n  rest\n\nᶜ6heal 3\n\n⁴drefresh\n items\n\n⁴dᶜ8burnᶜ6 the\n2nd card\n chosen"nw=S[#S]c={}nE=11for n=1,nE do add(c,S[n])end nI(c)A=z("/2;-2;-1;-1;-1;-1;+0;+0;+0;+0;+0;+0;+1;+1;+1;+1;+2;*2",true)nj={}n6=z("-2;-1;-1;-1>+0;+0;+0>+1;+0>+2;+0>+2;>+2;+0>+1∧;>+1∧;>+2;+1>+2∧;>+3;+1>+2∧",true)W={}e6=7for n=1,e6 do add(W,n6[n])end e4={}nd=b"50;😐 swift   ³f●50;0; swift\n boots\n\nᶜ6default\n 😐2 is\n now 😐3;😐;swift|60;い life    ●60;0;  life\n charm\n\nᶜ6negate a\n killing\n blow\n\n(refresh\n on long\n rest);い;life|40;웃 belt    ●40;0; winged\n  belt\n\nᶜ6😐 moves\n are all\n 웃 jumps;웃;belt|50;あ barbs   ³f●50;0; barbed\ngauntlet\n\nᶜ6default\n █2 also\n wounds∧;あ;barbs|60;う goggl   ³f●60;0;  keen\ngoggles\n\nᶜ6+2➡️ rng\n for all\n ranged\n attacks;う;goggl|30;★ shld    ●30;0; great\n shield\n\nᶜ6★2 first\n round\n attackd\n\n(refresh\n on long\n rest);★;shld|90;え mail    ●90;0; great\n  mail\n\nᶜ6permnent\n +★1;え;mail|;done;0;\n  done\n\nᶜ6return\nto town;;done|999;お slvst;0;slvrstl\n blade\n\nᶜ6blade of\nmystical\nmaterial\nthat can\npierce\nelements;お;slvst"q={}for n in all(nd)do add(q,n)end ea=nd[m(nd,"お slvst",2)]del(q,ea)h={}end function oj()d=0i,r=oB,oY end function oY()nh(0,0,127,127,5,13)spr(n.bigspr,5,4,2,2)O("       ᶜ6warrior   lvl ᶜ6"..n.lvl.."ᶜ6    xp ᶜ6"..n.xp.."\n                    ³e♥  ³fᶜ6"..n.maxhp.."    ●  ³f"..n.gold.."\n\n\n⁴eᶜ6actions:    ³fmods:        ³fitems:",7,6)line(1,24,126,24,13)na({c,e7(A),h},-2,31,nil,3,42)end function e7(e)local o,n=ow(e),{}for e,f in pairs(o)do add(n,"ᶜ5"..f.."x ᶜ6"..e)end return n end function oB()
if(btnp(🅾️))o(Z)
end function ov()i,r=oI,oE n4={"start new game"}
if(dget(0)==1)add(n4,"continue game",1)
end function oI()k(1,#n4)if btnp(🅾️)then if n4[f]=="continue game"then oG()o"town"else dset(0,0)o"newlevel"end end end function oE()if ni%10==0then cls(1)print("¹f ¹c ᶜ5V1.1aᶜ6\n\n¹7 ⁴d⁶i⁶w⁶tpicohaven⁶-w⁶-t⁶-i\n¹b ᶜd⁶iBY ICEGOAT⁶-i\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n⁴bᶜd¹2 CONTROLS:\n⁴b\n¹6 ³dᶜc⬅️⬆️➡️⬇️ᶜd, ᶜc🅾️ᶜd/ᶜczᶜd: ³fselect\n¹6 ³eᶜc❎ᶜd/ᶜcxᶜd: ³fcancel ³f/ ³fspecial",0,1)eh(n4,38,86,7)map(113,17,32,36,8,5)Y("█2➡️3",4,40)Y("😐3웃",4,51)end end function o_()n.maxhp+=1+n.lvl%2n.lvl+=1e"upgrade action deck:\nchoose an upgrade\ncard and a card to\nreplace. ᶜc🅾️ᶜ6:confirm"d,D=2,{{},{}}v,J=44,84n7={c,oA(n.lvl)}i,r=oN,ep end function oA(n)return{S[nE+(n-1)*2-1],S[nE+(n-1)*2]}end function oN()k(2,#c)f=min(f,#n7[d])if btnp(🅾️)then local n=n7[d][f]if D[d]==n then D[d]={}else D[d]=n end local n,f=D[1],D[2]if#n>0and#f>0then e("card "..n[2].." -> "..f[2])add(c,f)del(c,n)nI(c)o"upgrademod"end end end function oz()em(n.lvl)e"choose an upgrade\nfor your modifier\ndeck. ᶜc🅾️ᶜ6:confirm"d,D=2,{}v,J=44,84n7={e7(A),W}i,r=oR,ep end function em(n)add(W,n6[e6+n-1])end function oR()k(2,#W,2)if btnp(🅾️)then local n=W[f]eg(n)o"town"end end function ep()n0(5)O("ᶜ6deck:    ³eupgrades:",15,5)na(n7,0,10,D,0,nil,w=="upgrademod")ne()end function eg(n)local f,e,o=es(n)
if(e)del(A,e)
if(o)add(A,o)
del(W,n)add(e4,n)end function es(n)local e,o,f=""if n[1]~=">"then o=sub(n,1,2)e..="\nremove\n mod "..o n=sub(n,3)end if#n>0and n[1]==">"then f=sub(n,2)e..="\n\nadd\n mod "..f end return e,o,f end function ok()
if(Z=="splash"or Z=="pretown")music(8)
e8()ey="you return to the town of picohaven. "T=z"view profile;shop for gear"if n.xp>=n.lvl*60and n.lvl<9then ey..="you have gained enough xp to level up! "add(T,"* level up *",1)end if nT then add(T,"* retire *",1)else for n in all(g)do
if(n.unlocked)add(T,"go to: "..n.name)
end end add(T,"change difficulty: "..n3[C].txt)i,r=oL,oS end function oS()cls(5)print("ᶜ7  what next?⁴9ᶜ0⁶w⁶t¹4 ⌂ ⌂\n\n¹a ³c⌂  ⌂\n¹c ⌂\n\n\n\n",0,36)n8(ey,29,8,8,6)line(8,43,68,43,7)eh(T,8,48)end function oL()k(1,#T)if btnp(🅾️)then local n=T[f]if n=="view profile"then o"profile"elseif n=="* level up *"then o"upgradedeck"elseif n=="* retire *"then oq()elseif n=="shop for gear"then o"store"elseif sub(n,1,5)=="go to"then a=m(g,sub(n,8),"name")o"newlevel"elseif sub(n,1,10)=="change dif"then C=C%4+1T[#T]="change difficulty: "..n3[C].txt e8()end end end function oO()e"you browse the store..\nᶜc🅾️ᶜ6:select"i,r=oD,oF end function oD()k(1,#q)if btnp(🅾️)then local d=q[f]if d[2]=="done"then o"town"elseif n.gold<d[1]then e"not enough gold."else e("you bought "..d[6])add(h,d)del(q,d)n.gold-=d[1]end end end function oF()n0(5)na({q},5,10)O("ᶜ7you have:  ³f●"..n.gold,13,4)ne()end function oq()fillp(⌂\1|.375)rectfill(0,0,127,127,6)fillp()rectfill(8,8,119,119,5)n8("with the threat of the necromancer noah defeated, you have etched your place in picohaven's history.\nyou retire and serve as an advisor to the town council and mentor to younger adventurers for the rest of your days.\nand yet-- sometimes late at night you feel eyes watching you from across a deep void.\nᶜc ** until chapter two **",26,12,12,6)i=ex r=ex end function ex()end function n9(e,o,f,d)local n=nc
if(f)n=function(n)return nc(n,false,true)end
if(d)n=function(n)return nc(n,false,false,true)end
return oH(e,o,Q,n)end function oH(o,i,r,u,e)local n,l={last=o,cost_from_start=0,cost_to_goal=r(o,i,e)},{}l[nt(o,e)]=n local f,d,a,c={n},1,nt(i,e),32767.99while d>0do local t,o=c for n=1,d do local e=f[n].cost_from_start+f[n].cost_to_goal
if(e<=t)o,t=n,e
end n=f[o]f[o],n.dead=f[d],true d-=1local t=n.last if nt(t,e)==a then t={i}while n.prev do n=l[nt(n.prev,e)]add(t,n.last,1)end return t end for a in all(u(t,e))do local u=nt(a,e)local o,s=l[u],n.cost_from_start+1if not o then o={last=a,cost_from_start=c,cost_to_goal=r(a,i,e)}d+=1f[d],l[u]=o,o end if not o.dead and o.cost_from_start>s then o.cost_from_start,o.prev=s,t end end end end function nt(n)return n.y*128+n.x end function ev()cartdata"icegoat_picohaven_10"y=0end function x(n)dset(y,n)y+=1end function s()y+=1return dget(y-1)end function oG()y=0
if(s()==0)return
n.lvl=s()n.maxhp=s()n.xp=s()n.gold=s()nT=s()==1C=s()y=10c={}for n=1,s()do add(c,S[s()])end y=25for n=1,s()do em(n+1)eg(n6[s()])end y=35h={}for n=1,s()do local n=nd[s()]add(h,n)del(q,n)end y=45for n=1,s()do g[n].unlocked=false
if(s()==1)g[n].unlocked=true
end end function e8()y=0 x(1)x(n.lvl)x(n.maxhp)x(n.xp)x(n.gold)x(nT and 1or 0)x(C)nG(10,c,S)nG(25,e4,n6)nG(35,h,nd)y=45x(#g)for n in all(g)do if n.unlocked then x(1)else x(0)end end end function nG(e,n,o)y=e x(#n)for e in all(n)do x(m(o,e))end end