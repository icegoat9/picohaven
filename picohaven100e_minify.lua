function _init()
dlvl=2
initmspr()
initglobals()
initdbs()
initpersist()
initlevel()
palt(0b0000000000000010)
music(1,1000)
changestate("splash")
end
function _draw()
local s=128-2*wipe
clip(wipe,wipe,s,s)
_drwstate()
clip()
end
function _update60()
if animt<1 then
_updonlyanim()
else
shake=0  --turn off screenshake if it was on (e.g. due to "*2" mod card drawn)
for a in all(actor) do
if (a.hp<=0 and a!=p) a.x=-99
end
if btnp(❎) and not msgreview and msgreviewenabled then
msgreview,_updprev,_updstate=true,_updstate,_updscrollmsg
else
_updstate()
end
end
_updtimers()
end
function _updtimers()
fram+=1
afram=flr(fram/act_td)%4
wipe=max(0,wipe-5)
if fram % msg_td==0 and #msgq>4 and msg_yd<(#msgq-4)*6 and not msgreview then
msg_yd+=1
end
end
function _updonlyanim()
animt=min(animt+animtd,1)
for a in all(actor) do
a.ox,a.oy=a.sox*(1-animt),a.soy*(1-animt)
if animt==1 then
a.sox,a.soy=0,0
if (a.ephem) del(actor,a)
end
end
end
function changestate(_state,_wipe)
prevstate=state
state=_state
selvalid,showmapsel=false,false
selx,sely,seln=1,1,1
msgreviewenabled=false
wipe = _wipe or 63
msg_x0,msg_w=0,map_w
if (initfn[_state]) initfn[state]()
end
function _upd🅾️()
if (btnp(🅾️)) changestate(nextstate)
end
function initnewlevel()
initlevel()
if (prevstate!="splash") music(0)
mapmsg=pretxt[dlvl]
addmsg("\fc🅾️\f6:begin")
nextstate,_updstate,_drwstate="newturn",_upd🅾️,_drawlvltxt
end
function _drawlvltxt()
clsrect(0)
drawstatus()
drawmapframe()
printwrap(mapmsg,21,4,10,6)
drawheadsup()
drawmsgbox()
end
function initnewturn()
clrmsg()
addmsg("\f7----- new round -----\narrows:inspect enemies\n\fc🅾️\f6:choose action cards")
selx,sely,showmapsel=p.x,p.y,true
_updstate,_drwstate=_updnewturn,_drawmain
end
function _updnewturn()
selxy_update_clamped(10,10,0,0)
if (btnp(🅾️)) changestate("choosecards")
end
function selxy_update_clamped(xmax,ymax,xmin,ymin)
xmin,ymin = xmin or 1, ymin or 1
for i=1,4 do
if btnp(i-1) then
selx+=dirx[i]
sely+=diry[i]
break --only allow one button to be enabled at once, no "diagonal" moves
end
end
selx,sely=min(max(xmin,selx),xmax),min(max(ymin,sely),ymax)
seln=(selx-1)*ymax+sely
end
function initchoosecards()
tpdeck={}
for crd in all(pdeck) do
add(tpdeck,crd)
end
refresh(longrestcrd)
add(tpdeck,longrestcrd)
add(tpdeck,splt(";confirm;1;\nconfirm\n\n\f6confirm\nthe two\nselected\ncards"))
addmsg("select 2 cards to play\n(or rest+card to burn)\n\fc🅾️\f6:select\n\fc❎\f6:review map")
p.crds={}
_updstate,_drwstate=_updhand,_drawhand
end
function _updhand()
selxy_update_clamped(2,(#tpdeck+1)\2)
if (seln>#tpdeck) sely-=1
if btnp(🅾️) then
local selc=tpdeck[seln]
if selc[3]==0 then
if indextable(p.crds,selc) then
del(p.crds,selc)
else
if selc[2]=="rest" then
p.crds={}
end
if seln==#tpdeck then
for c in all(p.crds) do
c[3]=1
end
pdeckbld(p.crds)
changestate("precombat")
elseif #p.crds<2 then
add(p.crds,selc)
if tutorialmode then
if (#p.crds==1) addmsg("\f7initiative\f6 will be \f7"..selc[1].."\f6.\n (low init: act first)\nnow select 2nd card.")
if (#p.crds==2) addmsg("select \f7confirm\f6 if done.")
end
end
end
tpdeck[#tpdeck][3] = #p.crds==2 and 0 or 1
end
elseif btnp(❎) then
changestate("newturn")
end
end
function _drawhand()
clsrect(5)
print("\f6your deck:\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\*f \*7 \+fdlegend:",8,14)
drawcard("discard",94,108,1)
drawcard("burned",94,118,2)
local tp1,tp2=splitarr(tpdeck)
drawcardsellists({tp1,tp2},0,19,p.crds,9)
if (#p.crds<1) printmspr("\f61st card chosen\nsets \f7initiative\f6\n    for turn◆",67,4)
drawmsgbox()
end
function pdeckbld(clist)
if clist[1][2]=="rest" then
restburnmsg="\f8burned\f6 ["..clist[2][2].."]"
clist[2][3]=2
deli(clist,2)
else
add(clist,{0,hasitem("swift") and "😐3" or "😐2"})
add(clist,{0,hasitem("barbs") and "█2∧" or "█2"})
end
end
function initprecombat()
selectenemyactions()
ilist,initi=initiativelist(),1
addmsg("enemy actions drawn\n\fc🅾️\f6:continue to combat")
nextstate,_updstate,_drwstate="actloop",_upd🅾️,_drawmain
end
function selectenemyactions()
local etypes=activeenemytypes()
for et in all(etypes) do
et.crds = rnd(enemydecks[et.id])
et.init = et.crds[1][1]
end
for a in all(actor) do
if (a.type) a.crds=a.type.crds
a.init=a.crds[1][1]
a.crdi=1
end
end
function activeenemytypes()
local etypes={}
for a in all(actor) do
if (a!=p and not(indextable(etypes,a.type))) add(etypes,a.type)
end
return etypes
end
function initactloop()
_updstate=_updactloop
_drwstate=_drawmain
end
function _updactloop()
if p.hp<=0 then
loselevel()
return
end
if initi>#ilist then
changestate("cleanup",0)
return
end
actorn=ilist[initi][2]
local a=actor[actorn]
initi+=1
if (a.hp<1) return
if a==p and p.crds[1]==longrestcrd then
longrest()
p.stun=nil
elseif a.stun then
addmsg(a.name..": ▥, turn skipped")
a.stun=nil
else
if (a==p) then
changestate("actplayerpre",0)
else
changestate("actenemy",0)
end
end
end
function initactenemy()
_updstate=_updactenemy
_drwstate=_drawmain
end
function _updactenemy()
local e=actor[actorn]
if e.crdi>#e.crds then
changestate("actloop",0)
return
end
e.crd=parsecard(e.crds[e.crdi][2])
e.crdi+=1
if e.crd.act==sh("m") then
if e.crdi<=#e.crds then
local nextcrd=parsecard(e.crds[e.crdi][2])
if (nextcrd.act==sh("a")) e.crd.rng=nextcrd.rng
end
end
runcard(e)
end
function summon(a)
local smn=a.type.summon
local neighb=valid_emove_neighbors(a,true)
if #neighb>0 then
local smnxy=rnd(neighb)
initenemy(smn,smnxy.x,smnxy.y)
addmsg(a.name.." \f8calls\f6 "..enemytype[smn].name.." (\f8-2♥\f6)")
dmgactor(a,2)
end
end
function enemymoveastar(e)
mvq = trimmv(pathfind(e,p),e.crd.val,e.crd.rng)
if not mvq or #mvq<=1 then
mvq = trimmv(pathfind(e,p,false,true),e.crd.val,e.crd.rng)
end
changestate("animmovestep",0)
end
function trimmv(_mvq,mvval,rng)
if (not _mvq) return _mvq
local trimto
for i,xy in ipairs(_mvq) do
local v=validmove(xy.x,xy.y,true)
if i==1 or v and i<=(mvval+1) then
trimto=i
if (dst(xy,p)<=rng and pseudolos(xy,p)) break
end
end
return {unpack(_mvq,1,trimto)}
end
function validmove(x,y,endat,jmp,actorn,allyblocks)
if (fget(mget(x,y),1) or isfogoroffboard(x,y)) return false
if (fget(mget(x,y),2) and (endat or not jmp)) return false
local ai=actorat(x,y)
if (endat and ai>0 and actorn!=ai) return false
if ((allyblocks or actorn==1) and ai>1 and not jmp) return false
return true
end
function valid_emove_neighbors(node,endat,jmp,allyblocks)
local neighbors = {}
for i=1,4 do
local tx,ty=node.x+dirx[i], node.y+diry[i]
if validmove(tx,ty,endat,jmp,nil,allyblocks) then
add(neighbors, xylst(tx,ty))
end
end
return neighbors
end
function runattack(a,d)
local crd=a.crd
local basestun,basewound=crd.stun,crd.wound
local dmg=crd.val
if a==p then
local mod=modcard()
if mod=="*2" then
dmg*=2
shufflemod()
shake=3
elseif mod=="/2" then
dmg\=2
shufflemod()
else
if sub(mod,-1)=="▥" then
crd.stun=true
mod=sub(mod,1,#mod-1)
elseif sub(mod,-1)=="∧" then
crd.wound=true
mod=sub(mod,1,#mod-1)
end
dmg+=tonum(mod)
end
addmsg("you draw modifier \f7"..mod)
end
sfx(12)
local msg=a.name.." █ "..d.name..":"
if d==p and hasitem("shld",true) then
p.shld+=2
addmsg("\f7great shield used\f6: +★2")
end
if d.shld>0 then
msg..=dmg.."-"..d.shld.."★:"
dmg=max(0,dmg-d.shld)
end
msg..="\f8-"..dmg.."♥\f6"
if a.crd.stun then
msg..="▥"
d.stun=true
end
if a.crd.wound then
msg..="∧"
d.wound=true
end
crd.stun,crd.wound=basestun,basewound
addmsg(msg)
local aspr=144+dmg
if (dmg>9) aspr=154
queueanim(nil,d.x,d.y,a.x,a.y,aspr)
dmgactor(d,dmg)
end
function modcard()
if #pmoddeck==0 then
shufflemod()
end
local c = rnd(pmoddeck)
add(pmoddiscard,c)
del(pmoddeck,c)
return c
end
function enemyattack(e)
if dst(e,p) <= e.crd.rng and pseudolos(e,p) then
runattack(e,p)
end
end
function healactor(a,val)
local heal=min(val,a.maxhp-a.hp)
a.hp+=heal
addmsg(a.name.." healed \f8+"..heal.."♥")
a.wound=nil
end
function dmgactor(a,val)
a.hp-=val
if a.hp<=0 then
if a==p then
if hasitem("life",true) then
a.hp,a.wound=1,false
addmsg("\f7your life charm glows\n and you survive @ 1hp")
else
local crd=rnd(cardsleft())
if crd then
crd[3]=2
a.hp+=val
addmsg("you \f8burn\f6 a random card\n\f8[\f6"..crd[2].."\f8]\f6 to avoid death")
end
end
else
addmsg("\f7"..a.name.." is defeated!")
mset(a.x,a.y,36)
p.xp+=1
end
end
end
function initactplayerpre()
p.actionsleft=2
changestate("actplayer",0)
end
function initactplayer()
checktriggers(p)
if (p.actionsleft == 0) then
p.crds,p.init=nil
changestate("actloop",0)
return
end
addmsg("\fc⬆️⬇️,🅾️\f6:choose card "..3-p.actionsleft)
if (tutorialmode) addmsg(" or dflt act █2 / 😐2 ◆")
_updstate=_updactplayer
_drwstate=_drawmain
end
function _updactplayer()
selxy_update_clamped(1,#p.crds)
if btnp(🅾️) then
local crd=p.crds[sely]
crdplayed,crdplayedpos=crd,indextable(p.crds,crd)
p.crd=parsecard(crd[2])
if (hasitem("goggl") and p.crd.rng and p.crd.rng>1) p.crd.rng+=2
p.actionsleft -= 1
runcard(p)
if (p.crd.burn) crd[3]=2
del(p.crds,crd)
end
end
function runcard(a)
local crd=a.crd
if crd.act==sh("m") then
if a==p then
changestate("actplayermove",0)
else
enemymoveastar(a)
end
elseif crd.aoe==8 then
local aoepat=splt3d("x;-1;y;-1|x;0;y;-1|x;1;y;-1|x;-1;y;0|x;1;y;0|x;-1;y;1|x;0;y;1|x;1;y;1",true)
foreach(aoepat,pdeltatoabs)
foreach(aoepat,pattackxy)
changestate("actplayer",0)
elseif crd.act==sh("a") then
if a==p then
changestate("actplayerattack",0)
else
enemyattack(a)
end
else
if (crd.act==sh("h")) healactor(a,crd.val)
if crd.act==sh("s") then
a.shld+=crd.val
addmsg(a.name.." ★+"..crd.val)
elseif crd.act==sh("l") and a==p then
addmsg("looting treasure @➡️"..crd.val)
rangeloot(crd.val)
elseif crd.act=="hail▒" then
foreach(inrngxy(p,crd.rng),pattackxy)
elseif crd.act=="howl" then
addmsg(a.name.." howls.. \f8-1♥,▥")
dmgactor(p,1)
p.stun=true
elseif crd.act=="call" then
summon(a)
end
if (a==p) changestate("actplayer",0)
end
if (crd.burn) p.xp+=2
end
function pdeltatoabs(xy)
xy.x+=p.x
xy.y+=p.y
end
function pattackxy(xy)
local ai=actorat(xy.x,xy.y)
if ai>1 then
runattack(p,actor[ai])
else
queueanim(nil,xy.x,xy.y,p.x,p.y,2)
end
end
function inrngxy(a,r)
local inrng={}
for i=-r,r do
for j=-r,r do
local tx,ty=a.x+i,a.y+j
local txy=xylst(tx,ty)
if (not isfogoroffboard(tx,ty) and dst(a,txy)<=r and pseudolos(a,txy)) add(inrng,txy)
end
end
return inrng
end
function longrest()
p.actionsleft=0
addmsg("you take a \f7long rest\f6:")
foreach(pdeck,refresh)
foreach(pitems,refresh)
healactor(p,3)
addmsg(restburnmsg)
end
function loot(x,y)
if fget(mget(x,y),5) then
if mget(x,y)==36 then
p.gold+=gppercoin
addmsg("picked up "..gppercoin.."● (gold)")
elseif mget(x,y)==37 then
if dlvl==15 then
lootedchests+=1
addmsg("you find a map piece!")
else
local tr=rnd(rndtreasures[difficulty])
local tt,tv=tr[1],tr[2]
if tt=="g" then
p.gold+=tv
addmsg("you find "..tv.."●!")
elseif tt=="d" then
addmsg("chest is trapped! \f8-"..tv.."♥")
dmgactor(p,tv)
end
end
end
mset(x,y,33)
end
end
function rangeloot(r)
for xy in all(inrngxy(p,r)) do
loot(xy.x,xy.y)
end
end
function initactplayermove()
showmapsel=true
selx,sely=p.x,p.y
mvq={xylst(selx,sely)}
if (hasitem("belt")) p.crd.jmp=true
addmsg("move up to "..p.crd.val)
if (tutorialmode) addmsg(" (\fc🅾️\f6:confirm, \fc❎\f6:undo)")
_updstate=_updactplayermove
_drwstate=_drawmain
end
function _updactplayermove()
local selx0,sely0=selx,sely
selxy_update_clamped(10,10,0,0)
if selx!=selx0 or sely!=sely0 then
if #mvq>=2 and mvq[#mvq-1].x==selx and mvq[#mvq-1].y==sely then
deli(mvq,#mvq)
elseif #mvq>p.crd.val or not validmove(selx,sely,false,p.crd.jmp,1) then
selx,sely=selx0,sely0
else
add(mvq,xylst(selx,sely))
end
end
selvalid = (#mvq-1) <= p.crd.val and validmove(selx,sely,true,false,1)
if btnp(🅾️) then
if selvalid then
if (#mvq>1) sfx(11)
changestate("animmovestep",0)
else
addmsg("invalid move")
end
elseif btnp(❎) then
undoactplayer()
end
end
function undoactplayer()
p.actionsleft+=1
mvq={}
crdplayed[3]=1
add(p.crds,crdplayed,crdplayedpos)
changestate("actplayer")
end
function initanimmovestep()
a=actor[actorn]
if not mvq or #mvq<=1 then
mvq={}
if actorn==1 then
changestate("actplayer",0)
else
changestate("actenemy",0)
end
else
local x0,y0=mvq[1].x,mvq[1].y
local xf,yf=mvq[2].x,mvq[2].y
queueanim(a,xf,yf,x0,y0)
_updstate=_updanimmovestep
checktriggers(a,a.crd.jmp)
end
end
function checktriggers(a,jmp)
local ax,ay=a.x,a.y
if fget(mget(ax,ay),4) then
if mget(ax,ay)==43 and not jmp then
addmsg(a.name.." @ trap! \f8-"..trapdmg.."♥")
dmgactor(a,trapdmg)
mset(ax,ay,33)
end
if fget(mget(ax,ay),7) then
for i=1,4 do
unfogroom(ax+dirx[i],ay+diry[i])
end
initactorxys()
doorsleft-=1
mset(ax,ay,33)
end
end
end
function _updanimmovestep()
deli(mvq,1)
changestate("animmovestep",0)
end
function initactplayerattack()
showmapsel=true
selx,sely=p.x,p.y
addmsg("select attack target")
if (tutorialmode) addmsg(" (\fc🅾️\f6:confirm, \fc❎\f6:undo)")
_updstate=_updactplayerattack
_drwstate=_drawmain
end
function _updactplayerattack()
selxy_update_clamped(10,10,0,0)
local xy=xylst(selx,sely)
local d=dst(p,xy)
local crd=p.crd
selvalid = d <= crd.rng and d>0 and not isfogoroffboard(selx,sely) and pseudolos(p,xy)
if btnp(🅾️) then
if selvalid then
pattackxy(xy)
changestate("actplayer",0)
else
addmsg(" invalid target")
end
elseif btnp(❎) then
undoactplayer()
end
end
function initcleanup()
for a in all(actor) do
clearcards(a)
if (a.type) clearcards(a.type)
if a.wound and a.hp>0 then
addmsg(a.name.." ∧:\f8-1♥")
dmgactor(a,1)
end
a.shld=a.pshld
checktriggers(a)
if (a.hp<=0 and a!=p) del(actor,a)
end
loot(p.x,p.y)
local bossn=indextable(actor,"noah","name")
if dlvl==18 and eventtrigger() and not bossphase2 then
local bossa=actor[bossn]
bossphase2=true
bossa.type.id+=1
addmsg("\fcthe blue barriers\n \fcdissipate and noah\n \fchowls with rage.")
removebarriers()
summon(bossa)
end
if (#actor==1 and doorsleft==0) or (eventtrigger() and (dlvl==12 or dlvl==15)) or (dlvl==18 and not bossn) then
removebarriers()
winlevel()
elseif checkexhaust() then
loselevel()
else
if #cardsleft()<2 then
local burned=shortrestdeck()
addmsg("\fchand empty\f6: you short\nrest, redraw, and \f8burn\nrandom card: \f8[\f6"..burned.."\f8]")
end
addmsg("\fc❎\f6:'review msg' mode\n\fc🅾️\f6:next round")
msgreviewenabled=true
nextstate,_updstate="newturn",_upd🅾️
_drwstate=_drawmain
end
end
function removebarriers()
for i=0,10 do
for j=0,10 do
if (mget(i,j)==48) mset(i,j,33)
end
end
end
function eventtrigger()
if dlvl==12 or dlvl==18 then
return not indextable(actor,"rune","name")
elseif dlvl==15 then
return lootedchests==4
end
end
function shortrestdeck()
foreach(pdeck,refresh)
local crd=rnd(cardsleft())
crd[3]=2
return crd[2]
end
function cardsleft(incldiscrds)
local crds={}
for crd in all(pdeck) do
if (crd[3]==0 or (incldiscrds and crd[3]==1)) add(crds,crd)
end
return crds
end
function _updscrollmsg()
if btnp(❎) or btnp(🅾️) then
_updstate,msgreview=_updprev
elseif btn(⬆️) then
msg_yd=max(msg_yd-1,0)
elseif btn(⬇️) and #msgq>4 then
msg_yd=min(msg_yd+1,(#msgq-4)*6)
end
end
function initendlevel()
decksreset()
addmsg("\fc🅾️\f6:end of scenario")
nextstate,_updstate="pretown",_upd🅾️
end
function initpretown()
addmsg("\fc🅾️\f6:return to town")
nextstate,_drwstate="town",_drawlvltxt
_updstate=_upd🅾️
end
function winlevel()
local l=lvls[dlvl]
p.xp+=l.xp
p.gold+=l.gp
addmsg("\f7 victory!  \f6(+"..l.xp.."xp)")
if (l.gp>0) addmsg(" you are paid ●"..l.gp)
mapmsg=fintxt[dlvl]
l.unlocked=false
for u in all(split(l.unlocks)) do
if (u!="") lvls[tonum(u)].unlocked=true
end
if (dlvl==18) wongame=true
if (dlvl==14) add(pitems,slvrstl)
changestate("endlevel",0)
end
function checkexhaust()
if (p.hp<=0) return true
if (#cardsleft(true)<2) return true
if (#cardsleft(true)==2 and #cardsleft()<2) return true
end
function loselevel()
addmsg("\f8you are exhausted")
mapmsg="defeated, you hobble back to town to nurse your wounds and plan a return."
changestate("endlevel",0)
end
function clsrect(c)
rectfill(0,0,127,127,c)
end
function _drawmain()
clsrect(0)
drawstatus()
drawmapframe()
drawmap()
drawheadsup()
drawmsgbox()
end
function drawstatus()
print(sub(lvls[dlvl].name,1,15),0,0,7)
printmspr("♥"..p.hp.."/"..p.maxhp,66,0,8)
end
function drawmsgbox()
local c=msgreview and 12 or 13
rectborder(msg_x0,99,msg_x0+msg_w-1,127,5,c)
clip(max(msg_x0,wipe)+1,
max(101,wipe),
min(msg_x0+msg_w,127-2*wipe)-max(msg_x0,wipe)-2,
126-2*wipe-max(101,wipe))
textboxm(msgq,msg_x0,99-msg_yd,msg_w,29,2,5)
clip()
if (msgreview) printmspr("\fcU\n\+04X\n\+06D",msg_x0+msg_w-4,100)
end
function drawmapframe()
rectborder(0,6,91,97,0,5)
end
function drawmap()
camera(rnd(shake),rnd(shake))
for i=0,10 do
for j=0,10 do
sprn=mget(i,j)
if (fget(mget(i,j),3)) sprn+=afram
if (isfogoroffboard(i,j)) sprn=39
spr(sprn,2+8*i,8+8*j)
end
end
camera(0,0)
foreach(actor,drawactor)
if #mvq>1 then
local x0,y0=mvq[1].x,mvq[1].y
for mv in all(mvq) do
line(6+8*x0,12+8*y0,6+8*mv.x,12+8*mv.y,12)
x0,y0=mv.x,mv.y
end
circfill(6+8*x0,12+8*y0,1,12)
end
if (showmapsel) drawmapsel()
end
function drawactor(a)
local animfram = a.noanim and 0 or afram
if a.stun then
animfram=0
pal(splt("1;12;3;12;4;12;5;12;6;12;7;12;13;12",false,true))
end
spr(a.spr+animfram,2+8*a.x+a.ox,8+8*a.y+a.oy)
pal()
palt(0b0000000000000010)
if (a!=p and not a.ephem) drawactor(p)
end
function drawmapsel()
local mx,my=1+selx*8,7+sely*8
if (not selvalid) fillp(0x5a5a)
rect(mx,my,mx+9,my+9,12)
fillp()
end
function drawecards(x,y,n,sel)
local a=actor[n]
if (not sel) drawcardbase(x,y,a,sel)
local acrds=a.type.crds
if acrds and #acrds>=1 then
local strs={}
for crd in all(acrds) do
add(strs,crd[2])
end
textboxm(strs,x+10,y+10,25,15,nil,nil,1)
printmspr(a.type.init..":",x+2,y+15,7)
end
if (sel) drawcardbase(x,y,a,sel)
end
function drawcardbase(x,y,a,sel)
local str={"\+90"..a.name}
local c,h = 13,22
local hpstr = "?/"..a.maxhp
local st="\+91"
if (a.wound) st="\+01∧\+30"
if (a.shld>0) st..="★"..a.shld
if (a.stun) st..=" ▥"
if a==p then
h = 37
if (p.init) add(str,"\+13\f7"..p.init..":")
add(str,"\+03"..st)
if #pitems>0 then
add(str,"\+04items:")
st="\+04"
for it in all(pitems) do
st..=it[5]
end
add(str,st)
end
else
if sel then
hpstr=a.hp
a.type.hpdrawn=true
c=12
end
add(str,"\+90♥"..hpstr)
if (sel) add(str,st)
end
textboxm(str,x,y,33,h,nil,c)
spr(a.spr,x+2,y+2)
end
function drawpcards()
local hx,hy=hud_x0+2,hud_py+7
drawcardbase(hud_x0,hud_py,p)
if state=="precombat" or state=="actenemy" or state=="actloop" or state=="animmovestep" and actorn!=1 then
if p.crds then
for i=1,min(#p.crds,2) do
drawcard(p.crds[i],hx,hy+10*i)
end
end
elseif sub(state,1,9)=="actplayer" or state=="animmovestep" and actorn==1 then
for i,crd in ipairs(p.crds) do
local style=0
if (crd[1]==0) style=5
local cardsel=(i==sely and state=="actplayer")
drawcard(crd,hx,hy-10+10*i,style,cardsel)
fillp()
end
end
end
function drawcard(card,x,y,style,sel,lg,rawtext)
local strs=card
if not rawtext then
if lg then
strs=desccard(card)
else
if (type(card)=="table") strs=card[2]
end
end
local c1,c2,c3,cf,c4=13,1,6
local w,h,b=32,9,1
if (style==9) style=card[3]
if lg then
w,h,b=39,67,3
else
if (style==1) c1,c3,cf=0,5,true
if (style==2) c1,c2,c3,cf=0,0x82,0,true
if (style==3) c1=5
if (style==4) c1=12
if (style==5) c2=0
if (sel) c4=12
end
textboxm(strs,x,y,w,h,b,c1,c2,c3,cf,c4)
if (lg and not rawtext) then
line(x,y+18,x+w-1,y+18,c1)
circfill(x+w-2,y-1,7,c2)
circ(x+w-2,y-1,7,c1)
print(card[1],x+w-5,y-3,c3)
end
end
function desccard(card)
local crd=parsecard(card[2])
local strs={"\f7"..card[4],"",""}
if not crd.special then
addflat(strs,descact[crd.act]..crd.val)
if (crd.jmp) add(strs," jump")
if (crd.rng>1) add(strs," @ rng "..crd.rng)
if (crd.wound) add(strs," \f8wound")
if (crd.stun) add(strs," \fcstun")
if (crd.aoe) addflat(strs,"multiple\n targets")
if (crd.burn) add(strs,"\n\f8burn\f6 crd\n on use")
end
return strs
end
function drawheadsup()
local ehudn={}
for i,a in ipairs(actor) do
if a!=p and not a.ephem then
local enam=a.name
if (not indextable(ehudn,enam)) add(ehudn,enam)
local hy = hud_ey*indextable(ehudn,enam)-hud_ey
local selon = actorat(selx,sely)==i and showmapsel
if not a.type.hpdrawn then
drawecards(hud_x0,hy,i,selon)
end
end
end
for e in all(enemytype) do
e.hpdrawn=false
end
drawpcards()
end
function sh(ch)
return chr(ord(ch)+31)
end
function printmspr(str,x,y,c)
local xt,i=x,1
while i<=#str do
local ch=sub(str,i,i)
if ord(ch)==5 then
i+=1
xt+=tonum("0x"..sub(str,i,i))
i+=1
y+=tonum("0x"..sub(str,i,i))
elseif ord(ch)==12 then
i+=1
c=tonum("0x"..sub(str,i,i))
elseif ord(ch)==10 then
xt=x
y+=6
elseif minispr[ch] then
spr(minispr[ch],xt,y)
xt += 6
elseif ch==":" or ch==" " or ch=="." then
print(ch,xt-1,y,c)
xt += 3
if (ch==".") xt-=1
else
print(ch,xt,y,c)
xt += 4
if (ord(ch)>=128) xt += 4
end
i+=1
end
end
function printwrap(txt,w,x,y,c)
local txts=split(txt,"\n")
for txt in all(txts) do
while #txt>w do
local i=w+1
while sub(txt,i,i)!=" " do
i-=1
end
print(sub(txt,1,i),x,y,c)
txt=sub(txt,i+1)
y+=6
end
print(sub(txt,1,w),x,y,c)
y+=9
end
end
function textboxm(strs,x,y,w,h,b,c1,c2,c3,cf,c4)
b=b or 1
c1=c1 or 13
c2=c2 or 5
c3=c3 or 6
if (type(strs)!="table") strs={strs}
h=h or #strs*6+3
if (cf) fillp(0x5a5a)
rectborder(x,y,x+w-1,y+h-1,c2,c1)
fillp()
for i,str in ipairs(strs) do
printmspr(str,x+b+1,y+b-5+6*i,c3)
end
if (c4) rect(x-1,y-1,x+w,y+h,c4)
end
function drawcardsellists(clsts,x0,y0,sellst,style,spacing,modmode)
sellst = sellst or {}
spacing = spacing or 36
x0 = x0 or 0
lg=false
yd = style==3 and 8 or 10
for i=1,#clsts do
for j,crd in ipairs(clsts[i]) do
x=x0+8+(i-1)*spacing
y=y0+5+(j-1)*yd
local tstyle=style
if (indextable(sellst,crd)) tstyle=4
local selon = (i==selx and j==sely)
drawcard(crd,x,y,tstyle,selon)
end
end
if selx>0 and sely>0 then
local crd=clsts[selx][sely]
if (modmode) crd=descmod(crd)
drawcard(crd,85,24,0,true,true,modmode)
end
end
function drawselmenu(lst,x0,y0,c)
c=c or 6
for i,str in ipairs(lst) do
local ym = y0+(i-1)*8
printmspr(str,x0,ym,c)
if (sely==i) then
rect(x0-2,ym-2,x0+#str*4,ym+6,12)
end
end
end
function addmsg(m)
addflat(msgq,m)
end
function clrmsg()
msgq={}
msg_yd=0
end
function rectborder(x0,y0,xf,yf,cbk,cbr)
	rectfill(x0,y0,xf,yf,cbk)
	rect(x0,y0,xf,yf,cbr)
end
function pseudolos(a,d)
local pth=pathfind(a,d,true)
return pth and #pth-1==dst(a,d)
end
function parsecard(crdstr)
local ctbl={}
local chrs=split(crdstr,"")
if chrs[#chrs]==sh("b") then
ctbl.burn=true
deli(chrs,#chrs)
end
if tonum(chrs[2])==nil then
ctbl.special=true
ctbl.act=crdstr
if (crdstr=="hail▒") ctbl.val,ctbl.rng=5,3
else
ctbl.act=chrs[1]
ctbl.val=chrs[2]
if (ctbl.val==9) ctbl.val=99
if #chrs>=3 then
ctbl.mod=chrs[3]
if #chrs>=4 then
if tonum(chrs[4])==nil then
ctbl.mod2=chrs[4]
else
ctbl.modval=chrs[4]
if (#chrs>=5) ctbl.mod2=chrs[5]
end
end
end
if (ctbl.mod==sh("j")) ctbl.jmp=true
ctbl.rng=1
if (ctbl.mod==sh("r")) ctbl.rng=ctbl.modval
if (chrs[#chrs]=="H") ctbl.aoe=8
if (ctbl.mod==sh("z") or ctbl.mod2==sh("z")) ctbl.stun=true
if (ctbl.mod==sh("w") or ctbl.mod2==sh("w")) ctbl.wound=true
end
return ctbl
end
function shufflemod()
while (#pmoddiscard>0) do
add(pmoddeck,deli(pmoddiscard))
end
end
function decksreset()
for c in all(pdeck) do
c[3]=0
end
shufflemod()
end
function refresh(crd)
if (crd[3]==1) crd[3]=0
end
function clearcards(obj)
obj.crds,obj.init,obj.crd=nil
end
function splitarr(arr)
local arr1={unpack(arr,1,ceil(#arr/2))}
local arr2={unpack(arr,ceil(#arr/2)+1)}
return arr1,arr2
end
function indextable(tbl,x,prop)
for i,val in ipairs(tbl) do
if not prop then
if (val==x) return i
else
if (val[prop]==x) return i
end
end
end
function sort(a)
for i=1,#a do
local j=i
while j>1 and tonum(a[j-1][1]) > tonum(a[j][1]) do
a[j],a[j-1]=a[j-1],a[j]
j-=1
end
end
end
function xylst(x,y)
return {x=x,y=y}
end
function countlist(lst)
local counted={}
for itm in all(lst) do
counted[itm]=(counted[itm] or 0) + 1
end
return counted
end
function addflat(table, values)
if type(values)!="table" then
values=split(values,"\n")
end
for val in all(values) do
add(table,val)
end
end
function actorat(x,y)
for i,a in ipairs(actor) do
if (a.x==x and a.y==y) return i
end
return 0
end
function initiativelist()
ilist={}
for i,a in ipairs(actor) do
add(ilist,{a.init,i,a.name})
end
sort(ilist)
return ilist
end
function hasitem(itemname,useitem)
local itemi=indextable(pitems,itemname,6)
if (not itemi or pitems[itemi][3]!=0) return false
if (useitem) pitems[itemi][3]=1
return true
end
function queueanim(obj,x,y,x0,y0,mspr)
obj = obj or add(actor,{spr=mspr,noanim=true,ephem=true})
obj.x,obj.y=x,y
obj.sox,obj.soy=8*(x0-x),8*(y0-y)
obj.ox,obj.oy=obj.sox,obj.soy
animt=0
end
function dst(a, b)
return abs(a.x - b.x) + abs(a.y - b.y)
end
function initfog()
fog=splt3d("1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1")
end
function isfogoroffboard(x,y)
return (x<0 or x>10 or y<0 or y>10) or fog[x+1][y+1]
end
function unfog(x,y)
fog[x+1][y+1]=false
end
function unfogroom(x,y)
if (fget(mget(x,y),6)) return
local xf,yf,x0,y0=10,10,0,0
for n=0,10 do
if fget(mget(n,y),6) then
if n<x then
x0=n
else
xf=min(n,xf)
end
end
if fget(mget(x,n),6) then
if n<y then
y0=n
else
yf=min(n,yf)
end
end
end
for i=x0,xf do
for j=y0,yf do
unfog(i,j)
end
end
end
function splt(str,skipconv,kv)
local lst={}
local s=split(str,";",not skipconv)
if kv then
for k=1,#s,2 do
lst[s[k]]=s[k+1]
end
return lst
end
return s
end
function splt3d(str,kv)
local lst1,arr3d=split(str,"/"),{}
for i,lst2 in ipairs(lst1) do
add(arr3d,{})
local arr2d=split(lst2,"|")
for lst3 in all(arr2d) do
add(arr3d[i],splt(lst3,nil,kv))
end
end
while #arr3d==1 do
arr3d=arr3d[1]
end
return arr3d
end
function extractcartdata4r(addr)
str=""
while @addr!=255 do
str..=chr(@addr)
addr-=1
end
return str
end
function initmspr()
minispr=splt3d("█;5;😐;6;♥;7;●;8;웃;9;➡️;10;★;11;∧;12;▒;13;▥;14;⬅️;15;◆;4;H;28;☉;3;I;59;J;60;K;61;L;62;M;63;D;30;U;31;X;29",true)
descact=splt3d("█;atk ;😐;move ;♥;heal ;●;gold ;웃;jump;➡️;@ rng ;⬅️;get all\ntreasure\nwithin\nrange ➡️;★;shld ;∧;wound;▥;stun;▒;burn;H;adjacent",true)
end
function initglobals()
map_w,msg_x0,msg_yd,hud_x0,hud_ey,hud_py=92,0,0,93,27,81
act_td,afram,fram,animt,wipe=15,0,0,1,0
msg_td,animtd=4,0.05
difficparams=splt3d("txt;●easier● ;hp;-2;gp;1|txt;★normal★ ;hp;0;gp;1|txt;▥harder▥ ;hp;+2;gp;2|txt;▒brutal▒ ;hp;+5;gp;4",true)
difficulty=2
dirx,diry=split("-1,1,0,0"),split("0,0,-1,1")
msgq={}
state,prevstate,nextstate="","",""
initfn={newlevel=initnewlevel,splash=initsplash,town=inittown,
endlevel=initendlevel,newturn=initnewturn,choosecards=initchoosecards,
precombat=initprecombat,actloop=initactloop,
actenemy=initactenemy,actplayerpre=initactplayerpre,actplayer=initactplayer,
actplayermove=initactplayermove,animmovestep=initanimmovestep,
actplayerattack=initactplayerattack,cleanup=initcleanup,profile=initprofile,
upgradedeck=initupgrades,upgrademod=initupgrademod,store=initstore,pretown=initpretown}
end
function initlevel()
gppercoin,trapdmg=difficparams[difficulty].gp,4
lootedchests=0
copylvlmap(dlvl)
initfog()
actor={p}
if (hasitem("mail")) p.pshld=1
p.shld,p.stun,p.wound,p.hp=p.pshld,false,false,p.maxhp
initpxy()
unfogroom(p.x,p.y)
initactorxys()
mvq={}
decksreset()
foreach(pitems,refresh)
selx,sely,showmapselselvalid=p.x,p.y,true,false
bossphase2=false
enemytype[#enemytype].id=#enemytype
foreach(enemytype,clearcards)
tutorialmode=dlvl<7
clrmsg()
end
function copylvlmap(l)
for i=0,10 do
for j=0,10 do
mset(i,j,mget(i+lvls[l].x0,j+lvls[l].y0))
end
end
end
function initpxy()
doorsleft=0
for i=0,10 do
for j=0,10 do
if mget(i,j)==1 then
mset(i,j,33)
p.x,p.y=i,j
end
if (fget(mget(i,j),7)) doorsleft+=1
end
end
end
function initactorxys()
for i=0,10 do
for j=0,10 do
for e,et in ipairs(enemytype) do
if (et.spr==mget(i,j) and not isfogoroffboard(i,j)) then
initenemy(e,i,j)
mset(i,j,33)
end
end
end
end
end
function initenemy(n,x,y)
local etype=enemytype[n]
en={type=etype,x=x,y=y,
ox=0,oy=0,sox=0,soy=0,
maxhp=etype.maxhp+difficparams[difficulty].hp,
spr=etype.spr,
name=etype.name,
pshld=etype.pshld}
if (etype.name=="elem" and hasitem("slvst")) en.pshld=0
en.shld,en.hp=en.pshld,en.maxhp
if (en.hp>0) add(actor,en)
end
function initdbs()
lvls=splt3d("name;test level;x0;11;y0;0;unlocks;2;xp;150;gp;150|name;unnamed tomb;x0;22;y0;0;unlocks;3,4;xp;60;gp;0|name;elgin mausoleum;x0;33;y0;0;unlocks;7,8;xp;30;gp;0|name;another tomb;x0;44;y0;0;unlocks;5;xp;10;gp;0|name;another tomb ;x0;55;y0;0;unlocks;6;xp;10;gp;0|name;another tomb  ;x0;66;y0;0;unlocks;4;xp;10;gp;0|name;elgin manor road;x0;77;y0;0;unlocks;11;xp;30;gp;0|name;job: guard caravan;x0;88;y0;0;unlocks;9;xp;20;gp;30|name;job: rescue hunter;x0;99;y0;0;unlocks;;xp;20;gp;20|name;job: defeat bandits;x0;110;y0;0;unlocks;;xp;20;gp;30|name;elgin manor;x0;0;y0;11;unlocks;12,13;xp;40;gp;0|name;mage guild;x0;11;y0;11;unlocks;14,15;xp;30;gp;30|name;ruined chapel;x0;22;y0;11;unlocks;17;xp;60;gp;0|name;mountain pass;x0;33;y0;11;unlocks;;xp;20;gp;0|name;guild library;x0;44;y0;11;unlocks;16;xp;20;gp;0|name;sewers;x0;55;y0;11;unlocks;17;xp;20;gp;0|name;catacombs;x0;66;y0;11;unlocks;18;xp;40;gp;0|name;lower catacombs;x0;77;y0;11;unlocks;;xp;100;gp;0",true)
lvls[dlvl].unlocked=true
fintxt=splt(extractcartdata4r(0x1fff))
pretxt=splt(extractcartdata4r(0x42ff))
rndtreasures=splt3d("g;10|g;8|g;7|g;6|g;5/g;10|g;8|g;7|g;6|g;5|d;2/g;20|g;15|g;15|g;10|g;10|d;4/g;30|g;25|g;20|g;15|d;6")
enemytype=splt3d("id;1;name;skel;spr;116;maxhp;4;pshld;0|id;2;name;zomb;spr;112;maxhp;8;pshld;0|id;3;name;skel+;spr;88;maxhp;6;pshld;1|id;4;name;zomb+;spr;84;maxhp;12;pshld;0|id;5;name;sklar;spr;120;maxhp;3;pshld;0|id;6;name;cult;spr;100;maxhp;6;summon;1;pshld;0|id;7;name;bandt;spr;128;maxhp;6;pshld;0|id;8;name;archr;spr;132;maxhp;4;pshld;0|id;9;name;wolf;spr;96;maxhp;5;pshld;0|id;10;name;warg;spr;104;maxhp;9;pshld;1|id;11;name;drake;spr;124;maxhp;15;pshld;2|id;12;name;elem;spr;108;maxhp;15;pshld;8|id;13;name;rune;spr;92;maxhp;5;pshld;0|id;14;name;noah;spr;140;maxhp;18;summon;12;pshld;0",true)
enemydecksstr="57;😐3|;█3/60;😐1|;█4/30;😐2|;♥2/21;😐3|;█2/19;😐2|;█2,78;█6/72;😐1|;█4/56;😐1|;█2∧/67;😐1|;█5,57;😐4|;█4/60;😐2|;█5/30;😐3|;♥3/21;😐4|;█3/19;😐3|;█3,78;█8/72;😐1|;█6/56;😐2|;█3∧/67;😐1|;█5∧,21;😐1|;█2➡️3/40;█3➡️3/50;😐1|;█1➡️4∧/70;█3➡️3/37;😐1|;█1➡️3,40;😐1|;█1/30;😐1|;█2/90;call,40;😐2|;█3/55;😐1|;█4/28;😐3|;█2/21;★2|;😐2/28;★2|;♥2,24;😐1|;█2➡️4/40;█3➡️4/50;😐1|;█1➡️6∧/36;😐1|;█2➡️5,65;howl/11;😐4|;█3/22;😐5|;█2/35;😐4|;█2∧,60;howl/8;😐4|;█4∧/17;😐5|;█2∧/20;😐4|;█3∧,57;😐1|;█3/60;😐1|;█4/72;😐1|;♥2/38;█6➡️3/31;😐2|;█2,78;😐1|;█5/72;😐1|;█4/53;😐2/60;😐1|;█3➡️3,95;█1|;♥1/95;█1|;♥1,40;█3➡️4/53;█2➡️5/70;♥1|;█1➡️7/60;█1➡️6∧/43;█1➡️6▥,43;call/40;😐3|;█3➡️4/53;😐1|;█2➡️5/70;♥1|;█1➡️7/60;😐2|;█2➡️6/43;😐1|;█1➡️6▥,40;😐3|;█3➡️4/53;😐1|;█2➡️5/70;♥1|;█1➡️7/60;😐2|;█2➡️6/43;😐1|;█1➡️6▥/85;♥3"
enemydecks={}
for ed in all(split(enemydecksstr)) do
add(enemydecks,splt3d(ed))
end
p=splt3d("name;you;spr;66;bigspr;64;lvl;1;xp;0;gold;10;maxhp;10;pshld;0;ox;0;oy;0;sox;0;soy;0",true)
pdeckmaster=splt3d("15;😐2;0;\n  dash|35;😐3웃;0;\n  leap|45;█3;0;\n  chop|20;█2;0;\n   jab|42;█2➡️3;0; spare\n dagger|65;♥4▒;0; first\n  aid|60;█2;0;\n  stab|18;★2;0; braced\n stance|60;😐4;0;\nsidestep|70;█5➡️2▒;0;  hurl\n  sword|80;⬅️1;0;  loot\nlocally|45;█4;0;\n slash|31;😐5웃;0; mighty\n  leap|80;⬅️4▒;0; gather\ngreedily|41;█3H;0;\n stomp|17;█2▥;0;\nconcuss|65;█3➡️3;0;\njavelin|11;★4;0;\n  defy|34;█3∧;0;\n lance|64;█8▒;0; mighty\n swing|38;█4∧H▒;0; blade\ntornado|73;😐6웃;0; up and\n  over|46;♥3;0;bandage\n  self|34;█6;0; expert\n  blow|40;█7▥▒;0; giant\n killer|28;hail▒;0;hail of\nblades\n\n\f6█5 all\n enemies\n within\n rng ➡️3\n\n\f8burn\f6 crd\n on use|62;♥99▒;0;  rise\n again|99;rest;0;  long\n  rest\n\n\f6heal 3\n\+03refresh\n items\n\+03\f8burn\f6 the\n2nd card\n chosen")
longrestcrd=pdeckmaster[#pdeckmaster]
pdeck={}
pdecksize=11
for i=1,pdecksize do
add(pdeck,pdeckmaster[i])
end
sort(pdeck)
pmoddeck=splt("/2;-2;-1;-1;-1;-1;+0;+0;+0;+0;+0;+0;+1;+1;+1;+1;+2;*2",true)
pmoddiscard={}
pmodupgradesmaster=splt("-2;-1;-1;-1>+0;+0;+0>+1;+0>+2;+0>+2;>+2;+0>+1∧;>+1∧;>+2;+1>+2∧;>+3;+1>+2∧",true)
pmodupgrades={}
pmodupgradessize=7
for i=1,pmodupgradessize do
add(pmodupgrades,pmodupgradesmaster[i])
end
pmodupgradesdone={}
storemaster=splt3d("50;😐 swift   50●;0; swift\n boots\n\n\f6default\n 😐2 is\n now 😐3;😐;swift|60;K life\+40   60●;0;  life\n charm\n\n\f6negate a\n killing\n blow\n\n(refresh\n on long\n rest);K;life|40;웃 belt\+40   40●;0; winged\n  belt\n\n\f6😐 moves\n are all\n 웃 jumps;웃;belt|50;J barbs   50●;0; barbed\ngauntlet\n\n\f6default\n █2 also\n wounds∧;J;barbs|60;I goggl   60●;0;  keen\ngoggles\n\n\f6+2➡️ rng\n for all\n ranged\n attacks;I;goggl|30;★ shld\+40   30●;0; great\n shield\n\n\f6★2 first\n round\n attackd\n\n(refresh\n on long\n rest);★;shld|90;L mail\+40   90●;0; great\n  mail\n\n\f6permnent\n +★1;L;mail|;done;0;\n  done\n\n\f6return\nto town;;done|999;M slvst;0;slvrstl\n blade\n\n\f6blade of\nmystical\nmaterial\nthat can\npierce\nelements;M;slvst")
store={}
for item in all(storemaster) do
add(store,item)
end
slvrstl=storemaster[indextable(storemaster,"M slvst",2)]
del(store,slvrstl)
pitems={}
end
function initprofile()
selx=0
_updstate,_drwstate=_updprofile,_drawprofile
end
function _drawprofile()
rectborder(0,0,127,127,5,13)
spr(p.bigspr,5,4,2,2)
printmspr("\+f0\+50\f6warrior\+b0lvl \f6"..p.lvl.."\f6\+d0xp \f6"..p.xp.."\n\+f0\+f0\+f0\+e1♥\+90\f6"..p.maxhp.."   ●\+50"..p.gold.."\n\+0a\f6actions:\+b0mods:\+f0\+70☉items:",7,6)
line(1,24,126,24,13)
drawcardsellists({pdeck,countedlststr(pmoddeck),pitems},-2,31,nil,3,42)
end
function countedlststr(arr)
local sumdeck,lst = countlist(arr),{}
for mod,qty in pairs(sumdeck) do
add(lst,"\f5"..qty.."x \f6"..mod)
end
return lst
end
function _updprofile()
if (btnp(🅾️)) changestate(prevstate)
end
function initsplash()
_updstate,_drwstate=_updsplash,_drawsplash
splashmenu={"start new game"}
if (dget(0)==1) add(splashmenu,"continue game",1)
end
function _updsplash()
selxy_update_clamped(1,#splashmenu)
if btnp(🅾️) then
if splashmenu[sely]=="continue game" then
load_game()
changestate("town")
else
dset(0,0)
changestate("newlevel")
end
end
end
function _drawsplash()
if fram%10==0 then
cls(1)
print("\*f \*c \f5V1.0E\f6\n\n\*7 \|e\^i\^w\^tpicohaven\^-w\^-t\^-i\n\*b \fd\^iBY ICEGOAT\^-i\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\|b\fd\*2 CONTROLS:\n\|b\n\*6 \-d\fc⬅️⬆️➡️⬇️\fd, \fc🅾️\fd/\fcz\fd: \-fselect\n\*6 \-e\fc❎\fd/\fcx\fd: \-fcancel \-f/ \-fspecial",0,0)
drawselmenu(splashmenu,38,86,7)
map(113,17,32,36,8,5)
drawcard("█2➡️3",4,40)
drawcard("😐3웃",4,51)
end
end
function initupgrades()
p.maxhp+=1+p.lvl%2
p.lvl+=1
addmsg("upgrade action deck:\nchoose an upgrade\ncard and a card to\nreplace. \fc🅾️\f6:confirm")
selx,selc=2,{{},{}}
msg_x0,msg_w=44,84
upgradelists={pdeck,pdeckupgrades(p.lvl)}
_updstate,_drwstate=_updupgradedeck,_drawupgrades
end
function pdeckupgrades(lvl)
return {pdeckmaster[pdecksize+(lvl-1)*2-1],pdeckmaster[pdecksize+(lvl-1)*2]}
end
function _updupgradedeck()
selxy_update_clamped(2,#pdeck)
sely=min(sely,#upgradelists[selx])
if btnp(🅾️) then
local c=upgradelists[selx][sely]
if selc[selx]==c then
selc[selx]={}
else
selc[selx]=c
end
local c1,c2=selc[1],selc[2]
if #c1>0 and #c2>0 then
addmsg("card "..c1[2].." -> "..c2[2])
add(pdeck,c2)
del(pdeck,c1)
sort(pdeck)
changestate("upgrademod")
end
end
end
function initupgrademod()
addmodupgrade(p.lvl)
addmsg("choose an upgrade\nfor your modifier\ndeck. \fc🅾️\f6:confirm")
selx,selc=2,{}
msg_x0,msg_w=44,84
upgradelists={countedlststr(pmoddeck),pmodupgrades}
_updstate,_drwstate=_updupgrademod,_drawupgrades
end
function addmodupgrade(lvl)
add(pmodupgrades,pmodupgradesmaster[pmodupgradessize+lvl-1])
end
function _updupgrademod()
selxy_update_clamped(2,#pmodupgrades,2)
if btnp(🅾️) then
local mod=pmodupgrades[sely]
upgrademod(mod)
changestate("town")
end
end
function _drawupgrades()
clsrect(5)
printmspr("\f6deck:\+a0upgrades:",15,5)
drawcardsellists(upgradelists,0,10,selc,0,nil,state=="upgrademod")
drawmsgbox()
end
function upgrademod(mod)
local desc,rc,ac=descmod(mod)
if (rc) del(pmoddeck,rc)
if (ac) add(pmoddeck,ac)
del(pmodupgrades,mod)
add(pmodupgradesdone,mod)
end
function descmod(mod)
local strs=""
if sub(mod,1,1)!=">" then
rc=sub(mod,1,2)
strs..="\nremove\n mod "..rc
mod=sub(mod,3)
end
if #mod>0 and sub(mod,1,1)==">" then
ac=sub(mod,2)
strs..="\n\nadd\n mod "..ac
end
return strs,rc,ac
end
function inittown()
if (prevstate=="splash" or prevstate=="pretown") music(8)
save_game()
townmsg="you return to the town of picohaven. "
townlst=splt("view profile;shop for gear")
if p.xp>=p.lvl*60 and p.lvl < 9 then
townmsg..="you have gained enough xp to level up! "
add(townlst,"* level up *",1)	
end
if wongame then
add (townlst,"* retire *",1)
else
for lvl in all(lvls) do
if (lvl.unlocked) add(townlst,"go to: \f7"..lvl.name)
end
end
add(townlst,"change difficulty: "..difficparams[difficulty].txt)
_updstate,_drwstate=_updtown,_drawtown
end
function _drawtown()
cls(5)
print("\f7  what next?\|9\f0\^w\^t\*4 ⌂ ⌂\n\n\*a \-c⌂  ⌂\n\*c ⌂\n\n\n\n",0,36)
printwrap(townmsg,29,8,8,6)
line(8,43,68,43,7)
drawselmenu(townlst,8,48)
end
function _updtown()
selxy_update_clamped(1,#townlst)
if btnp(🅾️) then
local sel=townlst[sely]
if sel=="view profile" then
changestate("profile")
elseif sel=="* level up *" then
changestate("upgradedeck")
elseif sel=="* retire *" then
retire()
elseif sel=="shop for gear" then
changestate("store")
elseif sub(sel,1,5)=="go to" then
dlvl=indextable(lvls,sub(sel,10),"name")
changestate("newlevel")
elseif sub(sel,1,10)=="change dif" then
difficulty=difficulty%4+1
townlst[#townlst] = "change difficulty: "..difficparams[difficulty].txt
save_game()
end
end
end
function initstore()
addmsg("you browse the store..\n\fc🅾️\f6:select")
_updstate,_drwstate=_updstore,_drawstore
end
function _updstore()
selxy_update_clamped(1,#store)
if btnp(🅾️) then
local item=store[sely]
if item[2]=="done" then
changestate("town")
elseif p.gold<item[1] then
addmsg("not enough gold.")
else
addmsg("you bought "..item[6])
add(pitems,item)
del(store,item)
p.gold-=item[1]
end
end
end
function _drawstore()
clsrect(5)
drawcardsellists({store},5,10)
printmspr("\f7you have: ●"..p.gold,13,4)
drawmsgbox()
end
function retire()
fillp(⌂\1|0b.011)
rectfill(0,0,127,127,6)
fillp()
rectfill(8,8,119,119,5)
printwrap("with the threat of the necromancer noah defeated, you have etched your place in picohaven's history.\nyou retire and serve as an advisor to the town council and mentor to younger adventurers for the rest of your days.\nand yet-- sometimes late at night you feel eyes watching you from across a deep void.\n\fc ** until chapter two **",26,12,12,6)
_upd=noop
_draw=noop
end
function noop()
end
function pathfind(a,d,jmp,allyblocks)
local neighborfn=valid_emove_neighbors
if (jmp) neighborfn=function(node) return valid_emove_neighbors(node,false,true) end
if (allyblocks) neighborfn=function(node) return valid_emove_neighbors(node,false,false,true) end
return find_path(a,d,dst,neighborfn)
end
function find_path(start,goal,estimate,neighbors,graph)
local shortest,
best_table = {
last = start,
cost_from_start = 0,
cost_to_goal = estimate(start, goal, graph)
}, {}
best_table[node_to_id(start, graph)] = shortest
local frontier, frontier_len, goal_id, max_number = {shortest}, 1, node_to_id(goal, graph), 32767.99
while frontier_len > 0 do
local cost, index_of_min = max_number
for i = 1, frontier_len do
local temp = frontier[i].cost_from_start + frontier[i].cost_to_goal
if (temp <= cost) index_of_min,cost = i,temp
end
shortest = frontier[index_of_min]
frontier[index_of_min], shortest.dead = frontier[frontier_len], true
frontier_len -= 1
local p = shortest.last
if node_to_id(p, graph) == goal_id then
p = {goal}
while shortest.prev do
shortest = best_table[node_to_id(shortest.prev, graph)]
add(p, shortest.last,1)
end
return p
end
for n in all(neighbors(p, graph)) do
local id = node_to_id(n, graph)
local old_best, new_cost_from_start =
best_table[id],
shortest.cost_from_start + 1
if not old_best then
old_best = {
last = n,
cost_from_start = max_number,
cost_to_goal = estimate(n, goal, graph)
}
frontier_len += 1
frontier[frontier_len], best_table[id] = old_best, old_best
end
if not old_best.dead and old_best.cost_from_start > new_cost_from_start then
old_best.cost_from_start, old_best.prev = new_cost_from_start, p
end
end
end
end
function node_to_id(node)
return node.y * 128 + node.x
end
function initpersist()
cartid="icegoat_picohaven_10"
cartdata(cartid)
dindx=0
end
function dsetn(val)
dset(dindx,val)
dindx+=1
end
function dgetn()
dindx+=1
return dget(dindx-1)
end
function load_game()
dindx=0
if (dgetn()==0) return
p.lvl=dgetn()
p.maxhp=dgetn()
p.xp=dgetn()
p.gold=dgetn()
wongame = dgetn()==1
difficulty=dgetn()
dindx=10
pdeck={}
for i=1,dgetn() do
add(pdeck,pdeckmaster[dgetn()])
end
dindx=25
for i=1,dgetn() do
addmodupgrade(i+1)
upgrademod(pmodupgradesmaster[dgetn()])
end
dindx=35
pitems={}
for i=1,dgetn() do
local item=storemaster[dgetn()]
add(pitems,item)
del(store,item)
end
dindx=45
for i=1,dgetn() do
lvls[i].unlocked=false
if (dgetn()==1) lvls[i].unlocked=true
end
end
function save_game()
dindx=0
dsetn(1)
dsetn(p.lvl)
dsetn(p.maxhp)
dsetn(p.xp)
dsetn(p.gold)
dsetn(wongame and 1 or 0)
dsetn(difficulty)
save_helper(10,pdeck,pdeckmaster)
save_helper(25,pmodupgradesdone,pmodupgradesmaster)
save_helper(35,pitems,storemaster)
dindx=45
dsetn(#lvls)
for lvl in all(lvls) do
if lvl.unlocked then
dsetn(1)
else
dsetn(0)
end
end
end
function save_helper(indx,objtbl,mastertbl)
dindx=indx
dsetn(#objtbl)
for x in all(objtbl) do
dsetn(indextable(mastertbl,x))
end
end
