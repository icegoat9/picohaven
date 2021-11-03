--PICOhaven v1.0
--by icegoat, Oct '21

--this file is run through a script to strip comments and
-- whitespace and then included by picohaven100.p8, so these
-- comments do not appear in the released cart

--see also picohaven_source.md as reference for
-- main state machine, sprite flags, and global variables

--instructions, updates, and web-playable version:
-- https://www.lexaloffle.com/bbs/?tid=45105

--this file, related files, license, etc are in the
-- github repo: (to be added)

---- Code organization:
----- 1) core game init/update/draw
----- 2) main game state machine
----- 3) pre-combat states (new turn, choose cards, etc)
----- 4) action/combat loop
----- 4a) enemy action loop
----- 4b) player action loop
----- 5) post-combat states (cleanup, etc)
----- 6) main UI draw loops and card draw functions
----- 7) custom sprite-based font and print functions
----- 8) menu-draw and related functions
----- 9) miscellaneous helper functions
----- x) pause menu items [deprecated]
----- 10) data string -> datastructure parsing + loading
----- 11) inits and databases
----- 12) profile / character sheet
----- 13) splash screen / intro
----- 14) levelup, upgrades
----- 15) town and retirement
----- 16) debugging + testing functions
----- 17) pathfinding (A*)
----- 18) load/save

-----
----- 1) core game init/update/draw functions, including animation queue
-----

function _init()
  --debugmode=false
  --logmsgq=true
  --if (logmsgq) printh('\n*** new cart run ***','msgq.txt')
  --godmode=true

  dlvl=2  --starting dungeon #
  
  initmspr()
  initglobals()
  initdbs()
  initpersist()
  initlevel()
  --interpret pink (color 14) as transparent for sprites, black is not transparent
  palt(0b0000000000000010)
  music(1,1000)
  changestate("splash")
end

function _draw()
  --if wipe>0 a "screenwipe" is in progress, only update part of screen
  local s=128-2*wipe
  clip(wipe,wipe,s,s)
  _drwstate() --different function depending on state, set by state's init fn
  clip()
end

function _update60()
  if animt<1 then
    --if a move/attack square-to-square animation is in progress,
    -- only update that frame by frame until complete
    _updonlyanim()
  else
    --normal update routine
    shake=0  --turn off screenshake if it was on (e.g. due to "*2" mod card drawn)
    --move killed enemies off-screen (but only once any attack animations 
    -- being processed via _updonlyanim() have completed)
    -- (they will then be deleted from actor[] at end of turn)
    for a in all(actor) do
      if (a.hp<=0 and a!=p) a.x=-99
    end
    --check for entering msgreview state, potentially from many different states
    -- (as of v1.00b, only one state actually has msgreviewenabled==true, so this is unnecessarily general)
    if btnp(❎) and not msgreview and msgreviewenabled then
      msgreview,_updprev,_updstate=true,_updstate,_updscrollmsg
    else  --TODO: is this else redundant, could instead always run _updstate()?
      _updstate() --different function depending on state, set by state's init fn
    end
  end
  _updtimers()
end

--regardless-of-state animation updates:
-- update global timer tick, animation frame, screenwipe, message scrolling
function _updtimers()
  --common frame animation timer ticks
  fram+=1
  afram=flr(fram/act_td)%4
  --if screenwipe in progress, continue it
  wipe=max(0,wipe-5)
  --every msg_td # of frames, scroll msgbox 1px
  if fram % msg_td==0 and #msgq>4 and msg_yd<(#msgq-4)*6 and not msgreview then
    msg_yd+=1
  end
end

--run actor move/attack animations w/o user input until done
-- kicked off by setting common animation timer animt to 0
-- this function then gradually increases it 0->1 (=done)
function _updonlyanim()
  animt=min(animt+animtd,1)
  for a in all(actor) do
    --pixel offsets to draw each sprite at relative to its 8*x,8*y starting location
    a.ox,a.oy=a.sox*(1-animt),a.soy*(1-animt)
    if animt==1 then
      a.sox,a.soy=0,0
      --delete ephemeral 'actors' that are not really player/enemy actors (e.g. "damage number" sprites)--
      -- they were only created and added to actor[] to reuse this code to animate them
      if (a.ephem) del(actor,a)
    end
  end
end

-----
----- 2) main game state machine
-----

--the core of the state machine is to call changestate() rather
-- then directly edit the 'state' variable. this function calls
-- a relevant init() function (which updates update and draw functions)
-- and resets some key globals to standard values to avoid need
-- to reset them in every state's init function
function changestate(_state,_wipe)
  prevstate=state
  state=_state
  selvalid,showmapsel=false,false
  selx,sely,seln=1,1,1
  msgreviewenabled=false
  --screen wipe on every state change, unless passed _wipe==0
  wipe = _wipe or 63
  --reset msgbox x + width to defaults
  msg_x0,msg_w=0,map_w
  --run specific init function defined in initglobals()
  if (initfn[_state]) initfn[state]()
end

-- a simple wait-for-🅾️-to-continue loop used as update in various states
function _upd🅾️()
  ---if (showmapsel) selxy_update_clamped(10,10,0,0)
  if (btnp(🅾️)) changestate(nextstate)
end

-----
----- 3) the "pre-combat" states
-----

---- state: new level

function initnewlevel()
  initlevel()
  --play theme music, though don't restart music if it's already playing from splash screen
  if (prevstate!="splash") music(0)
  mapmsg=pretxt[dlvl]
  addmsg("\fc🅾️\f6:begin")
  nextstate,_updstate,_drwstate="newturn",_upd🅾️,_drawlvltxt
end

--display the pre- or post-level story text in the map frame
--TODO? merge into drawmain (since similar) + use a global to set whether map or text is displayed
--      but: that would become less clear, might only save ~15tok
function _drawlvltxt()
  clsrect(0)
  drawstatus()
  drawmapframe()
  printwrap(mapmsg,21,4,10,6)
  drawheadsup()
  drawmsgbox()
end

---- state: new turn

function initnewturn()
  clrmsg()
  addmsg("\f7----- new round -----\narrows:inspect enemies\n\fc🅾️\f6:choose action cards")
  selx,sely,showmapsel=p.x,p.y,true
  _updstate,_drwstate=_updnewturn,_drawmain
end

function _updnewturn()
  selxy_update_clamped(10,10,0,0)  --11x11 map
  if (btnp(🅾️)) changestate("choosecards")
end

--shared function used in many states to let player use
-- arrows to move selection box in x or y, clamped to an allowable range
function selxy_update_clamped(xmax,ymax,xmin,ymin)
  --set default xmin,ymin values of 1 if not passed to save a
  -- few tokens by omitting them in function calls (this is why they are
  -- listed last as function parameters, so they'll default to nil if omitted)
  --this approach is used widely in code to set default parameters
  xmin,ymin = xmin or 1, ymin or 1
  --loop checking which button is pressed
  for i=1,4 do
    if btnp(i-1) then
      selx+=dirx[i]
      sely+=diry[i]
      break --only allow one button to be enabled at once, no "diagonal" moves
    end
  end
  selx,sely=min(max(xmin,selx),xmax),min(max(ymin,sely),ymax)
  --item #n in an x,y grid of items
  --TODO?: also clamp seln to a max value? (not currently needed)
  seln=(selx-1)*ymax+sely
end

---- state: choose cards

function initchoosecards()
  --create a semi-local copy of pdeck (that adds the "rest"
  -- and "confirm" virtual cards that aren't in deck and shouldn't
  -- show up in character profile view of decklist)
  tpdeck={}
  for crd in all(pdeck) do
    add(tpdeck,crd)
  end
  --add "long rest" card (see init fns)
  --NOTE: hard-coded to be last entry in pdeckmaster[])
  refresh(longrestcrd)
  add(tpdeck,longrestcrd)
  --add "confirm" option, implemented as a card
  add(tpdeck,splt(";confirm;1;\nconfirm\n\n\f6confirm\nthe two\nselected\ncards"))
  addmsg("select 2 cards to play\n(or rest+card to burn)\n\fc🅾️\f6:select\n\fc❎\f6:review map")
  p.crds={}
  _updstate,_drwstate=_updhand,_drawhand 
end

--"selecting cards from hand" update function
function _updhand()
  selxy_update_clamped(2,(#tpdeck+1)\2)
  --if tpdeck has an odd number of cards, don't let selector move
  -- to the unused (bottom of column 2) location
  --TODO:build this into selxy_update_clamped() instead?
  if (seln>#tpdeck) sely-=1

  if btnp(🅾️) then
    local selc=tpdeck[seln]
    --card[3]=status (0=in hand, 1=discarded, 2=burned), see other comments and .md docs
    if selc[3]==0 then
      --card not discarded/burned, can select
      if indextable(p.crds,selc) then
        --card was already selected: deselect
        del(p.crds,selc)
      else
        --select card
        if selc[2]=="rest" then
          --clear other selections
          p.crds={}
        end
        if seln==#tpdeck then 
          --if last entry "confirm" selected, move ahead with card selection
          -- NOTE: that "confirm" can only be selected if it is enabled
          -- (card[3]==0) which is only set if 2 cards are selected

          --set these cards to 'discarded' now even before we get to playing them
          -- (so a "burn random undiscarded card to avoid damage"
          -- trigger before player turn can't use them)
          for c in all(p.crds) do
            c[3]=1
          end
          pdeckbld(p.crds)
          changestate("precombat")
        elseif #p.crds<2 then
          --if a new card is selected (and <2 already selected)
          add(p.crds,selc)
          if tutorialmode then
            if (#p.crds==1) addmsg("\f7initiative\f6 will be \f7"..selc[1].."\f6.\n (low init: act first)\nnow select 2nd card.")
            if (#p.crds==2) addmsg("select \f7confirm\f6 if done.")
          end
        end
      end
      --enable "confirm" button if and only if 2 cards selected,
      -- otherwise set it to "discarded" mode to grey it out
      tpdeck[#tpdeck][3] = #p.crds==2 and 0 or 1
    end
  elseif btnp(❎) then
    -- review map... by jumping back to newturn state
    changestate("newturn")
  end
end

function _drawhand()
  clsrect(5)
  print("\f6your deck:\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\*f \*7 \+fdlegend:",8,14)
  --drawcard("in hand",94,99,0)
  drawcard("discard",94,108,1)
  drawcard("burned",94,118,2)
  --rect(4,15,80,93,13)
  --split deck into two columns to display
  local tp1,tp2=splitarr(tpdeck)
  drawcardsellists({tp1,tp2},0,19,p.crds,9)
  --tip on initiative setting
  if (#p.crds<1) printmspr("\f61st card chosen\nsets \f7initiative\f6\n    for turn◆",67,4)
  drawmsgbox()
end

--create list of options-for-turn to display on player
-- box in HUD, from selected cards
function pdeckbld(clist)
  --if first card is "rest", only play that and burn other
  if clist[1][2]=="rest" then
    --message will be displayed later in turn, when you play rest
    restburnmsg="\f8burned\f6 ["..clist[2][2].."]"
    clist[2][3]=2
    deli(clist,2)
  else
    --add default alternate actions 😐2/█2 to options for turn
    -- (unless certain items held that modify these)
    add(clist,{0,hasitem("swift") and "😐3" or "😐2"})
    add(clist,{0,hasitem("barbs") and "█2∧" or "█2"})
  end
end

---- state: precombat
function initprecombat()
  --draw enemy cards for turn
  selectenemyactions()
  --ilist[]: global sorted-by-initiative list of actors
  --initi: "who in ilist[] is acting next"?
  ilist,initi=initiativelist(),1
--  --OBSOLETE section: removed to save tokens
--  --as tutorial, list actor initiatives
--  str="enemy actions drawn\n"
--  if tutorialmode then
--    str="initiatives for round:\n"
--    for i,il in ipairs(ilist) do
--      str..=" "..il[3]..":\+40"..il[1]
--      if (i!=#ilist) str..=","
--      if (i%2==0 or i==#ilist) str..="\n"
--    end
--  end
--  addmsg(str.."\fc🅾️\f6:continue to combat")
  addmsg("enemy actions drawn\n\fc🅾️\f6:continue to combat")
  nextstate,_updstate,_drwstate="actloop",_upd🅾️,_drawmain
end

--draw random action card for each enemy type and set
-- relevant global variables to use this turn
function selectenemyactions()
  local etypes=activeenemytypes()
  for et in all(etypes) do
    et.crds = rnd(enemydecks[et.id])
    et.init = et.crds[1][1]
  end
  for a in all(actor) do
    --add link to crds for each individual enemy
    --TODO: rethink this and remove redundancy of both enemy type and enemy
    --      having .init and .crds, but complicated by player not 
    --      having a .type (enemy type)
    if (a.type) a.crds=a.type.crds
    a.init=a.crds[1][1]
    a.crdi=1  --index of card to play next for this enemy
  end
end

--generate list of active enemy types (link to enemytypes[] entries)
-- from list of actors (only want one entry per type even if many instances of an enemy type)
function activeenemytypes()
  local etypes={}
  for a in all(actor) do
    if (a!=p and not(indextable(etypes,a.type))) add(etypes,a.type)
  end
  return etypes
end

-----
----- 4) the "actor action" / combat states
-----

---- NOTE: see picohaven_source.md for a diagram of the
----       state machine: many interconnected actionloop states

---- general action loop state (which will step through each actor, enemy and player)

function initactloop()
  _updstate=_updactloop
  _drwstate=_drawmain   --could comment out to save 3 tokens since hasn't changed since last state (but that's risky/brittle to future state flow changes)
end

--each time _updactloop() is called, it runs once and
-- dispatches to a specific player or enemy's action function (based on value of initi)
function _updactloop()
  if p.hp<=0 then
    loselevel()
    return
  end
  if initi>#ilist then
    --all actors have acted
    changestate("cleanup",0)
    return
  end
  actorn=ilist[initi][2]  --current actor from ordered-by-initiative list
  local a=actor[actorn]
  initi+=1  --increment index to actor, for the _next_ time this  function runs
  if (a.hp<1) return  --if actor dead, silently skip its turn
  --NOTE: below tutorial note commented out to save ~20tokens
  --if (tutorialmode) addmsg("@ initiative "..ilist[initi-1][1]..": "..a.name)
  if a==p and p.crds[1]==longrestcrd then
    --special case: long rests always run (even if stunned), w/o player interaction needed
    longrest()
    p.stun=nil   --in case player stunned. TODO: move into longrest() perhaps?
  elseif a.stun then 
    --skip turn if stunned
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

-----
----- 4a) the enemy action loop states
-----

---- state: actenemy

function initactenemy()
  _updstate=_updactenemy
  _drwstate=_drawmain   --could comment out to save 3 tokens since hasn't changed since last state (but that's risky/brittle to future state flow changes)
end

--execute one enemy action from enemy card
--(will increment global actor.crdi and run this multiple times if enemy has multiple actions)
function _updactenemy()
  local e=actor[actorn]
  --if all cards played, done, advance to next actor
  if e.crdi>#e.crds then
    changestate("actloop",0)
    return
  end
  --generate current "card to play"'s data structure, set global e.crd
  e.crd=parsecard(e.crds[e.crdi][2])
  --advance index for next time
  e.crdi+=1
  if e.crd.act==sh("m") then
    --if current action is a move, and enemy will have a ranged attack as the following action,
    -- store that attack range so move can stop once it's within range
    --NOTE: crdi below now refers to the 'next' card because of the +=1 above
    if e.crdi<=#e.crds then
      local nextcrd=parsecard(e.crds[e.crdi][2])
      if (nextcrd.act==sh("a")) e.crd.rng=nextcrd.rng
    end
  end
  runcard(e)  --execute specific enemy action
end

-- actor "a" summons its summon (and loses 2 hp)
-- (written for only enemy summoning, but could be extended for player summons in future chapter of game)
function summon(a)
  local smn=a.type.summon
  local neighb=valid_emove_neighbors(a,true) --valid adjacent squares to summon into
  if #neighb>0 then
    local smnxy=rnd(neighb)
    initenemy(smn,smnxy.x,smnxy.y)
    addmsg(a.name.." \f8calls\f6 "..enemytype[smn].name.." (\f8-2♥\f6)")
    --hard-coded that summoning always inflicts 2dmg to self
    dmgactor(a,2)
  end
end

-- moderately complex process of pathfinding for enemy moves (many sub-functions called)
function enemymoveastar(e)
  --basic enemy A* move, trimmed to allowable move distance:
  mvq = trimmv(pathfind(e,p),e.crd.val,e.crd.rng)
  --if no motion would happen via the normal "can pass thorugh allies" routing,
  -- enemy could be stuck behind one of its allies-- in this case, try routing 
  -- with "allies block motion" which may produce a useful "route around" behavior
  if not mvq or #mvq<=1 then
    mvq = trimmv(pathfind(e,p,false,true),e.crd.val,e.crd.rng)
  end
  --animate move until done (then will return to actenemy for next enemy action)
  changestate("animmovestep",0)
end

--trim down an ideal unlimited-steps enemy move to a goal, 
-- by stopping once either enemy is within
-- range (with LOS) or enemy has used up move rating for turn
function trimmv(_mvq,mvval,rng)
  if (not _mvq) return _mvq
  local trimto
  for i,xy in ipairs(_mvq) do
    local v=validmove(xy.x,xy.y,true)
    if i==1 or v and i<=(mvval+1) then  --equivalent to 'i==1 or (v and ...)'
      trimto=i
      --if xy is within range (1 unless ranged attack) and has LOS, trim here, skip rest of for loops
      if (dst(xy,p)<=rng and pseudolos(xy,p)) break
    end
  end
  return {unpack(_mvq,1,trimto)}
end

-- --WIP more complex pathfinding algorithm (on hold for lack of tokens,
-- --    and current draft is buggy)
-- --Plan A* moves to all four cells adjacent to player, determine which of these
-- -- moves is 'best' (if none are adjacent or in range of a ranged attack, which
-- -- partial move ends with the shortest path to the player in a future turn?)
--function enemymoveastaradvanced(e)
--  --bug: this routing allows enemy to move _through_ player to an open spot on other side
--  --minor bug: enemies don't always route around
--  --This is ~50 tokens more than a simpler single A* call
--  local potential_goals=valid_emove_neighbors(p,true)
--  bestdst,mvq=99,{}
--  for goal in all(potential_goals) do
--    local m=find_path(e,goal,dst,valid_emove_neighbors)
--    m=trimmv(m,e.crd.val,e.crd.rng)
--    if m then --if non-nil path returned
--      --how many steps would it take from this path's
--      -- endpoint to reach player in future?
--      local d=#find_path(m[#m],p,dst,valid_emove_neighbors)
--      if d<bestdst then
--        bestdst,mvq=d,m
--      end
--    end
--  end
--  changestate("animmovestep",0)
--end

-- general "valid move?" function for all actors
function validmove(x,y,endat,jmp,actorn,allyblocks)
  --endat: if true, validate ending at this
  --       spot (otherwise checking pass-through)
  --jmp: jumping (can pass over some obstacles and enemies if not ending at this location)
  --allyblocks: do enemies' allies block their movement?
  --            (by default enemies can pass through though not end moves on allies)
  --actorn: axtor[] index of moving actor (1: player)

  --unjumpable obstacles (walls, fog)
  if (fget(mget(x,y),1) or isfogoroffboard(x,y)) return false
  --obstacle w/o jump (or even w/ jump can't end at)
  if (fget(mget(x,y),2) and (endat or not jmp)) return false
  --can't walk through actors, except enemies through their allies
  -- or jumping past them
  local ai=actorat(x,y)
  --can't end on actor (except, actors can end of self i.e. 0 move)
  if (endat and ai>0 and actorn!=ai) return false
  --by default, enemies can pass through allies
  -- (unless we pass the 'ally blocks moves' flag,
  --  used to break out of some routing deadlocks)
  if ((allyblocks or actorn==1) and ai>1 and not jmp) return false
  return true
end

-- return list of "valid-move adjacent neighbors to (node.x,node.y)"
-- used in A* pathfind(), for example
function valid_emove_neighbors(node,endat,jmp,allyblocks)
  --see parameter descriptions in validmove()
  local neighbors = {}
  for i=1,4 do
    local tx,ty=node.x+dirx[i], node.y+diry[i]
    if validmove(tx,ty,endat,jmp,nil,allyblocks) then
      add(neighbors, xylst(tx,ty))
    end
  end
  return neighbors
end

----wrapper to above allowing jmp, to pass to A* pathfind
----Note: moved to inline anonymous function since only used once in program
--function valid_emove_neighbors_jmp(node)
--  return valid_emove_neighbors(node,false,true)
--end

----wrapper allowing enemies to move through allies, for A* calls
----Note: moved to inline anonymous function since only used once in program
--function valid_emove_neighbors_allyblocks(node)
--  return valid_emove_neighbors(node,false,false,true)
--end

--execute attack described in attacker's card a.crd, against defender d
function runattack(a,d)
  --a = attacker, d = defender (in actor[] list)
  local crd=a.crd
  --save values before modifier card drawn
  local basestun,basewound=crd.stun,crd.wound
  local dmg=crd.val
  --draw attack mod card (currently player-only)
  if a==p then
    local mod=modcard()
    if mod=="*2" then
      dmg*=2
      shufflemod()
      --do something for emphasis (larger mod sprite with sspr? slow down
      -- dmg animation? screen shake? all of the above?) 
      --tried many, commented out most. for now, just screen shake
      shake=3 --screenshake of 3 pixels
--      animtd=0.03  --slow down animation (todo: reset elsewhere)
--      msg_td=99 --slow down msgbox (todo: reset elsewhere)
--      addmsg("")  --add blank line
--      queueanim(nil,d.x,d.y-1,a.x,a.y-1,156) --draw a 'x2' cursor
    elseif mod=="/2" then
      dmg\=2
      shufflemod()
    else
      --check for mod card conditions
      if sub(mod,-1)=="▥" then
        crd.stun=true
        mod=sub(mod,1,#mod-1)
      elseif sub(mod,-1)=="∧" then
        crd.wound=true
        mod=sub(mod,1,#mod-1)
      end
      --modify damage via mod
      dmg+=tonum(mod)
    end
    addmsg("you draw modifier \f7"..mod)
  end
  -- below runs for all actors
  sfx(12)
  -- do damage and effects
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
  --reset card .stun and .wound-- only relevant if a
  -- multi-target attack AND .stun/.wound were applied
  -- by a modifier card (so should not necessarily be
  -- applied ot all targets)
  crd.stun,crd.wound=basestun,basewound
  addmsg(msg)
  --prepare attack animation
  local aspr=144+dmg
  if (dmg>9) aspr=154
  queueanim(nil,d.x,d.y,a.x,a.y,aspr)
  dmgactor(d,dmg)
end

--draw player attack modifier card
-- (and maintain a discard pile and dwindling deck)
function modcard()
  if #pmoddeck==0 then
    shufflemod()
  end
  local c = rnd(pmoddeck)
  add(pmoddiscard,c)
  del(pmoddeck,c)
  return c
end

--try to have enemy attack
function enemyattack(e)
  if dst(e,p) <= e.crd.rng and pseudolos(e,p) then
    runattack(e,p)
--  else
--    addmsg(e.name.." cannot attack") --debug, removed to reduce message spam + tokens
  end
end

function healactor(a,val)
  local heal=min(val,a.maxhp-a.hp)
  a.hp+=heal
  addmsg(a.name.." healed \f8+"..heal.."♥")
  a.wound=nil
end

--damage actor and check death, etc
function dmgactor(a,val)
  a.hp-=val
  if a.hp<=0 then
    if a==p then
      if hasitem("life",true) then
        a.hp,a.wound=1,false
        addmsg("\f7your life charm glows\n and you survive @ 1hp")
      else
        -- burn random card in hand to negate dmg
        local crd=rnd(cardsleft())
        if crd then
          crd[3]=2
          a.hp+=val
          addmsg("you \f8burn\f6 a random card\n\f8[\f6"..crd[2].."\f8]\f6 to avoid death")
        end
        --TODO? if no cards in hard, burn 2 from discard pile?
        --      (niche rare option, defer for now)
      end
    else
      --sfx(5)
      --TODO: move this to separate function?
      addmsg("\f7"..a.name.." is defeated!")
      --drop coin, but won't be visible until check in _update60() removes
      -- enemy sprite from play area
      --if (tutorialmode) addmsg(" and drops a coin (●)")
      mset(a.x,a.y,36)  
      p.xp+=1
    end
  end
end

-----
----- 4b) player actions
-----

--first time entering actplayer for turn
function initactplayerpre()
  p.actionsleft=2
  changestate("actplayer",0)
end

--each time entering actplayer (typically runs twice/turn,
-- for 1st + 2nd actions fof turn, but also runs after 'undo', etc)
function initactplayer()
  --checks for ended-on-trap-with-jump-on-prev-move,
  -- since that wouldn't be caught during animmovestep
  checktriggers(p)
  if (p.actionsleft == 0) then
    p.crds,p.init=nil  --assignment with misssing values sets p.init to default of nil
    changestate("actloop",0)
    return
  end
  addmsg("\fc⬆️⬇️,🅾️\f6:choose card "..3-p.actionsleft)
  if (tutorialmode) addmsg(" or dflt act █2 / 😐2 ◆")
  _updstate=_updactplayer
  _drwstate=_drawmain   --could comment out to save 3 tokens since hasn't changed since last state (but that's risky/brittle to future state flow changes)
end

--loops in this routine until card selected and 🅾️, then runs that card
-- (and then the called function typically changes state to actplayer 
--  when done, to rerun initactplayer above before running this again)
function _updactplayer()
  selxy_update_clamped(1,#p.crds) --let them select one of p.crds
  if btnp(🅾️) then
    --crd = the card table (initiative, string, status)
    --note: if card in players deck, this is a reference to an entry in pdeck
    --      so edits to crd (e.g. changing crd[3] to discard or burn it) also edit the original in pdeck for future turns
    local crd=p.crds[sely]
    --global copy to restore if needed for an undo
    crdplayed,crdplayedpos=crd,indextable(p.crds,crd)
    --parse just the action string into data structure
    p.crd=parsecard(crd[2])
    --special-case modification of range if has googles item
    -- (TODO? more clear if done in parsecard?)
    if (hasitem("goggl") and p.crd.rng and p.crd.rng>1) p.crd.rng+=2
    p.actionsleft -= 1
    runcard(p)
    --note: card was already set to 'discarded' (crd[3]=1) back
    -- when cards were chosen from hand
    if (p.crd.burn) crd[3]=2  --burn card instead
    del(p.crds,crd) --delete from list of cards shown in UI
  end
end

--execute the card that has been parsed into a.crd
-- (where a is a reference to an entry in actor[])
-- (called by _updactplayer() or _updactenemy()
function runcard(a)
  local crd=a.crd
  --if (godmode and a==p) crd.val,crd.rng=9,9 --obsolete 'god mode'
  if crd.act==sh("m") then  --a move action
    if a==p then
      changestate("actplayermove",0)
    else
      enemymoveastar(a)
    end
  elseif crd.aoe==8 then  --specific player AoE attack 'all adjacent' where no UI interaction to select targets is needed
    --TODO? generalize for multiple different AoE attacks (aoepat[#]?)
    --      but AoE attacks w/ selectable targets/directions would need to
    --      happen in an interactive attack mode like "actplayerattack"
    --TODO? maybe merge w/ handling of HAIL special AoE attack?
    --list of the 8 (x,y) offsets relative to player hit by this 
    -- 'all surrounding enemeies' AoE, hard-coded as string for minimal tokens
    local aoepat=splt3d("x;-1;y;-1|x;0;y;-1|x;1;y;-1|x;-1;y;0|x;1;y;0|x;-1;y;1|x;0;y;1|x;1;y;1",true)
    foreach(aoepat,pdeltatoabs) --modifies aoepat in place
    foreach(aoepat,pattackxy) --run attack for each AoE square
    changestate("actplayer",0)
  elseif crd.act==sh("a") then  --standard attack
    if a==p then
      changestate("actplayerattack",0)  --UI for target selection
    else
      enemyattack(a)  --run enemy attack for actor a
    end
  else  --other simpler actions without UI/selection
    --Note: currently each action is a ssumed to only do one thing,
    --      e.g. move, attack, heal, or so on.
    --TODO: implement code to allow player heal/shield actions 
    --      attached to a move/attack? not worth tokens for chapter 1
    if (crd.act==sh("h")) healactor(a,crd.val)
    if crd.act==sh("s") then
      a.shld+=crd.val
      addmsg(a.name.." ★+"..crd.val)
    elseif crd.act==sh("l") and a==p then
      addmsg("looting treasure @➡️"..crd.val)
      rangeloot(crd.val)
    elseif crd.act=="hail▒" then  --special player attack
      foreach(inrngxy(p,crd.rng),pattackxy)
    elseif crd.act=="howl" then --special enemy attack
      addmsg(a.name.." howls.. \f8-1♥,▥")
      dmgactor(p,1)
      p.stun=true
    elseif crd.act=="call" then
      summon(a)
    end
    if (a==p) changestate("actplayer",0)
  end
  if (crd.burn) p.xp+=2 --using burned cards adds xp
end

--one-off function (could inline where called in foreach() above,
-- to save a few tokens since used in only one place) 
-- to take an {x,y} delta relative to the player
-- and transform it to absolute positions
function pdeltatoabs(xy)
  xy.x+=p.x
  xy.y+=p.y
end

--have player attack a square (occupied or not)
--can be called directly for single attack or passed to foreach() for multi attacks
function pattackxy(xy)
  local ai=actorat(xy.x,xy.y)
  if ai>1 then
    runattack(p,actor[ai])
  else
    --no enemy in target square, queue empty attack animation
    queueanim(nil,xy.x,xy.y,p.x,p.y,2)  
  end
end

--return all {x=x,y=y} cells within range r of actor a
-- (and on map, within LOS, not fogged, etc)
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
  --refresh discarded and items
  foreach(pdeck,refresh)
  foreach(pitems,refresh)
  healactor(p,3)
  --note: burning of the card selected along with 'rest' was done
  -- earlier in pdeckbld(), so that p.crds doesn't show that card before p's turn)
  -- now display the burn message configured back in pdeckbld()
  addmsg(restburnmsg)
end

--loot treasure (for player) at x,y
--TODO: reduce code?
function loot(x,y)
  if fget(mget(x,y),5) then
    if mget(x,y)==36 then --coin
--      sfx(1)  --loot sfx removed to save tokens and because didn't seem to add much
      p.gold+=gppercoin
      addmsg("picked up "..gppercoin.."● (gold)")
    elseif mget(x,y)==37 then --chest
      if dlvl==15 then
        lootedchests+=1
--        sfx(2)
        addmsg("you find a map piece!")
      else  --random chest treasure, options depend on difficulty level
        local tr=rnd(rndtreasures[difficulty])
        local tt,tv=tr[1],tr[2]
        if tt=="g" then
          p.gold+=tv
--          sfx(2)
          addmsg("you find "..tv.."●!")
        elseif tt=="d" then
--          sfx(3)
          addmsg("chest is trapped! \f8-"..tv.."♥")
          dmgactor(p,tv)
        end
      end
    end
    mset(x,y,33)
  end
end

--loot all treasures within rng r of player (no enemies currently loot)
-- note: inrngxy() checks unfogged, in LOS, etc so you won't
--       loot through walls
function rangeloot(r)
  for xy in all(inrngxy(p,r)) do
    loot(xy.x,xy.y)
  end
end

---- state actplayermove (interactive player move action)

function initactplayermove()
  showmapsel=true --show selection box on map
  selx,sely=p.x,p.y
  mvq={xylst(selx,sely)}  --initialize move queue with current player location
  --TODO: find 12 tokens to add back in the '(jump)' message,
  --      removed to fill other last-minute token needs
  --local msg="move up to "..p.crd.val
  if (hasitem("belt")) p.crd.jmp=true
  --if (p.crd.jmp) msg..=" (jump)"
  --addmsg(msg)
  addmsg("move up to "..p.crd.val)
  if (tutorialmode) addmsg(" (\fc🅾️\f6:confirm, \fc❎\f6:undo)")
  _updstate=_updactplayermove
  _drwstate=_drawmain   --could comment out to save 3 tokens since hasn't changed since last state (but that's risky/brittle to future state flow changes)
end

--player interactively builds step-by-step move queue
-- (not only destination: path matters due to traps or other triggers)
function _updactplayermove()
  local selx0,sely0=selx,sely
  selxy_update_clamped(10,10,0,0)
  --if player moved the cursor, try to move:
  if selx!=selx0 or sely!=sely0 then
    --NOTE: commented out lines tried to streamline code,
    --      but can't compare equality on two lists easily?
    --local selxy=xylst(selx,sely)
    --if #mvq>=2 and mvq[#mvq-1]==selxy then
    if #mvq>=2 and mvq[#mvq-1].x==selx and mvq[#mvq-1].y==sely then
      --if player moved back to previous location, trim move queue
      deli(mvq,#mvq)
    elseif #mvq>p.crd.val or not validmove(selx,sely,false,p.crd.jmp,1) then
      --if move not valid (obstacle/actor unless jumping,
      -- or beyond player move range), cancel that move
      selx,sely=selx0,sely0
    else
      --valid move step, add to move queue
      --note: still might not be valid location to _end_ a move on,
      --      e.g. obstacle, but that's checked when 🅾️ pressed
      add(mvq,xylst(selx,sely)) --or pass in selxy if set above (not currently implemented)
    end
  end
  -- it's only valid to _end_ move here if it's a passable hex within range
  -- (global selvalid also affects how selection cursor is drawn, dashed or solid)
  selvalid = (#mvq-1) <= p.crd.val and validmove(selx,sely,true,false,1)
  if btnp(🅾️) then
    if selvalid then
      if (#mvq>1) sfx(11)
      --kick off move and animation
      --NOTE: animmovestep will also update p.x,p.y to move along the
      --      move queue as a side effect, not intuitive
      changestate("animmovestep",0)
    else
      addmsg("invalid move")
    end
  elseif btnp(❎) then
    undoactplayer()
  end
end

--try to restore state and undo card selection
-- (for move and attack actions not completed)
--note: added late in development, tight on tokens
function undoactplayer()
  p.actionsleft+=1
  mvq={}
  crdplayed[3]=1  --burned -> discarded (if it was a burn card we started to play)
  add(p.crds,crdplayed,crdplayedpos)
  changestate("actplayer")
end

--TODO? modify p.x,p.y separately vs
--      as a side effect of this
function initanimmovestep()
  --determine actor from global
  --TODO: extend this in future chapters to handle "push/pull" actions, 
  --      where active actor != the actor moving
  a=actor[actorn]
  if not mvq or #mvq<=1 then
    --we're done with animation, run next player/enemy action
    mvq={}
    if actorn==1 then
      changestate("actplayer",0)
    else
      changestate("actenemy",0)
    end
  else
    --queue up a one-step animation (will do this multiple times
    -- until each step in mvq has been animnated and taken)
    local x0,y0=mvq[1].x,mvq[1].y
    local xf,yf=mvq[2].x,mvq[2].y
    --deli(mvq,1) --done in updanimmovestep() instead
    queueanim(a,xf,yf,x0,y0)
    _updstate=_updanimmovestep
    --check for any immediate triggers
    -- for space moved into (trap, door)
    checktriggers(a,a.crd.jmp)
  end
end

--check for any triggers on location actor a is on
-- (intended to be run both during move and at end of move)
--jmp = is actor jumping? (don't pass it for end of move check)
--NOTE: flag 5 (treasure) is not checked here, because it's currently
--      handled by an end-of-turn call to loot() to loot only the square
--      player ends turn on (could consider different gameplay)
function checktriggers(a,jmp)
  local ax,ay=a.x,a.y
  if fget(mget(ax,ay),4) then --sprite with trigger
    if mget(ax,ay)==43 and not jmp then
      --stepped on trap
      addmsg(a.name.." @ trap! \f8-"..trapdmg.."♥")
      dmgactor(a,trapdmg)
      mset(ax,ay,33)
    end
    --if on door, open next room
    if fget(mget(ax,ay),7) then
--      sfx(0)
      for i=1,4 do
        unfogroom(ax+dirx[i],ay+diry[i])
      end
      --init any new enemies revealed
      initactorxys()
      doorsleft-=1
      mset(ax,ay,33)
    end
  end
end

--NOTE: program flow is not the most intuitive here.
--the gloval state is set to animmovestep in tandem with an animation
--      being kicked off (animt=0), so this upd() function will not
--      actually be called during the animation, until the animation is done
--      and updstate() is called. so this is run once at the end of each animated
--      step, to trim the movequeue and then rerun initanimmovestep()
function _updanimmovestep()
  deli(mvq,1)
  --changing state to self, as a way to rerun initanimmovestep() and take the next step
  changestate("animmovestep",0)
end

---- actplayerattack state (attack target selection UI)

function initactplayerattack()
  showmapsel=true
  selx,sely=p.x,p.y
  addmsg("select attack target")
  if (tutorialmode) addmsg(" (\fc🅾️\f6:confirm, \fc❎\f6:undo)")
  _updstate=_updactplayerattack
  _drwstate=_drawmain   --could comment out to save 3 tokens since hasn't changed since last state (but that's risky/brittle to future state flow changes)
end

function _updactplayerattack()
  selxy_update_clamped(10,10,0,0)
  --variables set based on current target cursor
  local xy=xylst(selx,sely)
  local d=dst(p,xy)
  local crd=p.crd
  --selection is valid target if (and only if) following conditions are true:
  -- (in range, not self, not fogged, has LOS if ranged)
  -- this global then affects how selection cursor is drawn and whether action can be selected below
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

-----
----- 5) post-combat turn states
-----

---- state: cleanup (aka end of turn)

function initcleanup()
  ---addmsg("end of turn...")
  for a in all(actor) do
    -- clean up actor hands
    clearcards(a)
    --TODO: remove this if cards are not stored at the "type" level?
    --      (currently enemies store cards redundantly in actor and actor.type)
    if (a.type) clearcards(a.type)
    --process wound condition
    if a.wound and a.hp>0 then
      addmsg(a.name.." ∧:\f8-1♥")
      dmgactor(a,1)
    end
    --remove certain one-turn buffs
    a.shld=a.pshld
    --check space triggers (e.g. end move on trap, door)
    --note: trap, door already checked during move actions,
    --      though, so currently I think this doesn't catch any 
    --      triggers not already triggered?
    checktriggers(a)
    --cleanup dead enemies (except player)
    if (a.hp<=0 and a!=p) del(actor,a)
  end
  --check if ended turn on treasure
  loot(p.x,p.y)  
  --boss level specific tracking (returns nil if no boss)
  local bossn=indextable(actor,"noah","name")
  --check if boss level runestones destroyed
  if dlvl==18 and eventtrigger() and not bossphase2 then
    --TODO(BUG): this will crash if bossn==nil (if somehow
    --           boss was killed/removed before runestones destroyed:
    --           seems ~impossible in gameplay since below functions would 
    --           win level once boss killed, but should have a check for future work)
    local bossa=actor[bossn]
    bossphase2=true
    --change boss's action deck to new set  of actions
    bossa.type.id+=1
    addmsg("\fcthe blue barriers\n \fcdissipate and noah\n \fchowls with rage.")
    --remove barrier and spawn an elemental
    removebarriers()
    summon(bossa)
  end
  --check if all enemies defeated or a special win con is met
  -- including if boss is killed in last level
  --TODO: find way to not hard code level #s in future
  if (#actor==1 and doorsleft==0) or (eventtrigger() and (dlvl==12 or dlvl==15)) or (dlvl==18 and not bossn) then
    --TODO? only relevant on one level, move this into to winlevel()?
    removebarriers()  --remove any rune barriers
    winlevel()
  elseif checkexhaust() then
    --check if player out of hp or cards
    loselevel()
  else
    --if hand doesn't have 2+ cards left, must short rest
    --  note: checked in checkexhaust() above to ensure discard
    --        pile had enough cards to short rest
    if #cardsleft()<2 then
      local burned=shortrestdeck()
      addmsg("\fchand empty\f6: you short\nrest, redraw, and \f8burn\nrandom card: \f8[\f6"..burned.."\f8]")
    end
    addmsg("\fc❎\f6:'review msg' mode\n\fc🅾️\f6:next round")
    msgreviewenabled=true
    nextstate,_updstate="newturn",_upd🅾️
    _drwstate=_drawmain   --could comment out to save 3 tokens since hasn't changed since last state (but that's risky/brittle to future state flow changes)
  end
end

--remove any rune barries drawn on map
function removebarriers()
  for i=0,10 do
    for j=0,10 do
      if (mget(i,j)==48) mset(i,j,33)
    end
  end
end

--check if level-specific conditions/triggers met
function eventtrigger()
  if dlvl==12 or dlvl==18 then
    return not indextable(actor,"rune","name")
  elseif dlvl==15 then
    return lootedchests==4
  end
end

function shortrestdeck()
  --refresh discarded
  foreach(pdeck,refresh)
  --burn random card in hand (since all discards back in hand)
  local crd=rnd(cardsleft())
  crd[3]=2
  --return card burned
  return crd[2]
end

--return list of cards in hand (not discarded or burned)
-- (if incldiscards==true, also include non-burned discards)
--note: returns the list of cards not the number of cards,
--      so often called as #cardsleft()<##
function cardsleft(incldiscrds)
  local crds={}
  for crd in all(pdeck) do
    if (crd[3]==0 or (incldiscrds and crd[3]==1)) add(crds,crd)
  end
  return crds
end

---- state: scrollmsg (review message queue)

function _updscrollmsg()
  if btnp(❎) or btnp(🅾️) then
    _updstate,msgreview=_updprev
  elseif btn(⬆️) then
    msg_yd=max(msg_yd-1,0)
  elseif btn(⬇️) and #msgq>4 then
    msg_yd=min(msg_yd+1,(#msgq-4)*6)
  end
end

---- state: end level

function initendlevel()
  decksreset()
  addmsg("\fc🅾️\f6:end of scenario")
  --wait for player to continue before displaying post-level
  -- text (since that will overwrite view of map)
  nextstate,_updstate="pretown",_upd🅾️
end

--still end of level, draw post-level text
function initpretown()
  addmsg("\fc🅾️\f6:return to town")
  nextstate,_drwstate="town",_drawlvltxt
  --could comment below out to save 3 tokens since we know _updstate was already set
  -- to this in initendlevel() last state (but that's risky/brittle to future state flow changes)
  _updstate=_upd🅾️
end

--end of level helpers

function winlevel()
  local l=lvls[dlvl]
  p.xp+=l.xp
  p.gold+=l.gp
  addmsg("\f7 victory!  \f6(+"..l.xp.."xp)")
  if (l.gp>0) addmsg(" you are paid ●"..l.gp)
  mapmsg=fintxt[dlvl]
  l.unlocked=false  --lock level to avoid replay
  --unlock new levels
  for u in all(split(l.unlocks)) do
    if (u!="") lvls[tonum(u)].unlocked=true
  end
  if (dlvl==18) wongame=true
  --TODO? generalize this special-case achievement rather than hard-code?
  if (dlvl==14) add(pitems,slvrstl)
  --NOTE: tried a different approach a one point, no longer here:
  --      instead set a global leveldone=true here and then
  --      initcleanup() checked that and changed state to end level, but that was a few more tokens
  changestate("endlevel",0)
end

function checkexhaust()
  if (p.hp<=0) return true
  --if < 2 cards in deck (including discards)
  if (#cardsleft(true)<2) return true
  --if 2 cards in deck but < 2 cards in hand (so a short/long rest would fail)
  if (#cardsleft(true)==2 and #cardsleft()<2) return true
  --return false  --redundant since default return is nil which evals to false?
end

function loselevel()
--  sfx(4)
  addmsg("\f8you are exhausted")
  mapmsg="defeated, you hobble back to town to nurse your wounds and plan a return."
  changestate("endlevel",0)
end

-----
----- 6) main UI draw loops and support functions
-----

--like cls(c) but respects clip(), for wipes/fades
function clsrect(c)
  rectfill(0,0,127,127,c)
end

-- main draw UX (map, msgs, enemy+player HUD (heads-up displays))
function _drawmain()
  clsrect(0)
  drawstatus()
  drawmapframe()
  drawmap()
  drawheadsup()
  -- draw msgs last, since they set a clip()
  drawmsgbox()
end

function drawstatus()
  print(sub(lvls[dlvl].name,1,15),0,0,7)
  printmspr("♥"..p.hp.."/"..p.maxhp,66,0,8)
  --DEBUG tool for checking cards in hand, etc during dev
--  printmspr(#cardsleft()..","..#cardsleft(true).."/"..#pdeck.." mod "..#pmoddeck.."/"..#pmoddeck+#pmoddiscard,0,0,8)
end

function drawmsgbox()
  local c=msgreview and 12 or 13
  rectborder(msg_x0,99,msg_x0+msg_w-1,127,5,c)
  --clip based on overlap of screenwipe and msgbox
  clip(max(msg_x0,wipe)+1,
      max(101,wipe),
      min(msg_x0+msg_w,127-2*wipe)-max(msg_x0,wipe)-2,
      126-2*wipe-max(101,wipe))
--- DEBUG: visualize clipping rectangle
--  rect(max(msg_x0,wipe)+1,
--           max(101,wipe),
--           max(msg_x0,wipe)+1-1 + min(msg_x0+msg_w,127-2*wipe)-max(msg_x0,wipe)-2,
--           max(101,wipe)-1 + 126-2*wipe-max(101,wipe),14)
  --draw messages (a long list that will run off screen, typically,
  --  but clipped to only update within message box area)
  textboxm(msgq,msg_x0,99-msg_yd,msg_w,29,2,5)
  clip()
  --UI for message scrolling
  if (msgreview) printmspr("\fcU\n\+04X\n\+06D",msg_x0+msg_w-4,100)
end

function drawmapframe()
  rectborder(0,6,91,97,0,5)
end

--main play area map drawing
function drawmap()
  --screenshake map in some cases (e.g. draw "2x" mod)
  camera(rnd(shake),rnd(shake))
  --draw sprites (not using simpler map(), to handle
  -- animated tiles, fog, etc)
  for i=0,10 do
    for j=0,10 do
      sprn=mget(i,j)
      --animated environment
      if (fget(mget(i,j),3)) sprn+=afram
      if (isfogoroffboard(i,j)) sprn=39
      --NOTE: 2,8=map_x0+2,y0+2
      spr(sprn,2+8*i,8+8*j)
    end
  end
  camera(0,0)
  --draw actors (player + enemies + ephemeral animations)
  --note: despite looping through actor[] in order,
  --      drawactor includes a hack to always draw player on top of enemies (e.g. if jumping)
  foreach(actor,drawactor)
  --draw path along move queue if one exists
  --NOTE: initially only existed for debugging but I liked the look,
  --      so left it in (could remove if tokens needed) 
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
  --Show stunned actors as blue and frozen (~19tok)
  -- (may be commented out to save tokens)
  if a.stun then
    animfram=0
    pal(splt("1;12;3;12;4;12;5;12;6;12;7;12;13;12",false,true))
  end
  spr(a.spr+animfram,2+8*a.x+a.ox,8+8*a.y+a.oy)
  pal()
  palt(0b0000000000000010)

  --NOTE/TODO: hack to redraw player sprite on top of all
  --      enemies, but leave player under attack animations
  if (a!=p and not a.ephem) drawactor(p) 
end

function drawmapsel()
  local mx,my=1+selx*8,7+sely*8
  if (not selvalid) fillp(0x5a5a)  --dashed border
  rect(mx,my,mx+9,my+9,12)
  fillp()
end

-- draw: enemy cards --

--draw enemy cards for actor #n
--typically, base with just maxhp, and then any action cards covering it
--if enemy is "selected" (for inspection by player)
-- instead show HP, conditions like stun/wound, etc
function drawecards(x,y,n,sel)
  local a=actor[n]
  if (not sel) drawcardbase(x,y,a,sel)
  --show ability card
  --using a.type.crds instead of a.crds, in case a new enemy instance 
  -- was revealed (e.g. by opening a door), it will have no a.crds since
  -- it didn't exist at beginning of combat, but if it has allies
  -- of the same type, a.type.crds will contain their cards
  local acrds=a.type.crds
  if acrds and #acrds>=1 then
    local strs={}
    for crd in all(acrds) do
      add(strs,crd[2])
    end
    --draw enemy's action cards
    textboxm(strs,x+10,y+10,25,15,nil,nil,1)
    --linking to a.type. instead of a. in case new instance of an enemy revealed (woudn't have initiative yet)
    printmspr(a.type.init..":",x+2,y+15,7)
  end
  --if enemy is selected for inspection, draw base on top of action cards instead
  if (sel) drawcardbase(x,y,a,sel)
end

--draw actor a's base card (player or enemy)
-- base card is frame, sprite, name, hp, conditions
function drawcardbase(x,y,a,sel)
  local str={"\+90"..a.name}
  --todo: add enemy level in future if we have enemy levels?
  local c,h = 13,22 --color, box height
  local hpstr = "?/"..a.maxhp
  --build 'actor status' string
  local st="\+91"
  if (a.wound) st="\+01∧\+30"
  if (a.shld>0) st..="★"..a.shld
  if (a.stun) st..=" ▥"
  --special player vs. enemy tweaks in display
  if a==p then
    h = 37
    if (p.init) add(str,"\+13\f7"..p.init..":")
    add(str,"\+03"..st)
    --add item icons
    --TODO/BUG: if >4 or 5 icons, will run off screen,
    --          add code to wrap to next line? left out
    --          to save tokens since a rare case
    if #pitems>0 then
      add(str,"\+04items:")
      st="\+04"
      for it in all(pitems) do
--        --commented out to save tokens
--        --'dark' icon for used items
--        st..=it[3]==0 and it[5] or it[6] 
        st..=it[5]
      end
      add(str,st)
    end
  else --enemy-specific display
    if sel then
      --TODO? combine assignments into one line to save 2 tokens?
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

--draw player cards (and base)
function drawpcards()
  local hx,hy=hud_x0+2,hud_py+7
  drawcardbase(hud_x0,hud_py,p)
  --in most combat-related states except when player is actively
  -- choosing a card to play, show the two cards player chose
  -- from hand (or one if it's "rest")
  --TODO? find alternate to checking global actorn in if
  if state=="precombat" or state=="actenemy" or state=="actloop" or state=="animmovestep" and actorn!=1 then
    if p.crds then
      for i=1,min(#p.crds,2) do
        drawcard(p.crds[i],hx,hy+10*i)
      end
    end
  elseif sub(state,1,9)=="actplayer" or state=="animmovestep" and actorn==1 then
    --but if during player turn, show all player options
    -- (up to 4 including default move/attack options)
    for i,crd in ipairs(p.crds) do
    --shade default mv/atk cards (which have 0 initiative)
      local style=0
      if (crd[1]==0) style=5
      local cardsel=(i==sely and state=="actplayer")
      drawcard(crd,hx,hy-10+10*i,style,cardsel)
      --TODO: is this unnecessary and wecould save 3 tokens, 
      --      since textboxm() already resets fillp() if used?
      fillp()
    end
  end
end

--draw a card with various styles and options
function drawcard(card,x,y,style,sel,lg,rawtext)
  -- by default, draws small one-line version,
  --   but if lg==true, draws large card on right

  --style sets frame/texture:
  --  nil/0: default box
  --  1: faded (discarded, used)
  --  2: burned
  --  3: no border
  --  4: multi-item selection
  --  9: read style from card[3]

  -- sel: is card selected? (draws outer border)

  --if rawtext, assume card is a string or list of strings
  --  rather than a card data structure
  --  (and this acts mostly a wrapper for textboxm())
  local strs=card
  if not rawtext then
    if lg then
      strs=desccard(card)
    else
      --TODO? add back in microspacing?
      --TODO? only display first 7 chars? (for items in prof)
      if (type(card)=="table") strs=card[2]
    end
  end
  local c1,c2,c3,cf,c4=13,1,6 --default colors
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
    --divider line on card
    line(x,y+18,x+w-1,y+18,c1)
    --print initiative in circle
    circfill(x+w-2,y-1,7,c2)
    circ(x+w-2,y-1,7,c1)
    print(card[1],x+w-5,y-3,c3)
  end
end

--return a list of formatted strings descibing a card
-- based on its actions/values/modifiers
-- (for the lg card preview box in drawcard())
function desccard(card)
  local crd=parsecard(card[2])
  local strs={"\f7"..card[4],"",""}
  --NOTE: special cards ("hail", etc) have decsriptions in their
  --      card[4] data in the database, rather than being generated here
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

--overall hud (right panel with enemy+player info and cards)
function drawheadsup()

  --draw enemy cards
  -- assign enemy types to HUD slots
  -- ehudn can hold up to three enemy types, as name strings
  -- TODO: don't need to run this every draw loop...
  --       perhaps should be in an update fn instead?
  local ehudn={}
  for i,a in ipairs(actor) do
    if a!=p and not a.ephem then
      local enam=a.name
      --add name of an enemy type to ehudn if there
      -- isn't already a row for it
      if (not indextable(ehudn,enam)) add(ehudn,enam)
      local hy = hud_ey*indextable(ehudn,enam)-hud_ey
      local selon = actorat(selx,sely)==i and showmapsel
      --normally, each instance of an enemy will redraw the same
      -- enemy base/cards in the same location as we itereate through enemies
      -- (redundant but simple)
      --but, .hpdrawn indicates the HP for a specific selected enemy
      --  was drawn in the HUD, so other enemies' generic overviews
      --  should not be drawn over that
      if not a.type.hpdrawn then
        --draw cards for actor[i]
        drawecards(hud_x0,hy,i,selon)
      end
    end
  end
  for e in all(enemytype) do
    e.hpdrawn=false
  end
  --draw player cards
  drawpcards()
end

-----
----- 7) custom sprite-based font and print functions
-----

--maps character "j" -> "shift-j" (웃), etc
function sh(ch)
  return chr(ord(ch)+31)
end

--semi-custom font
-- prints a string but subs 5x5 spr for some chars,
-- also adds proportional (tighter) spacing on [.: ], etc
-- also allows cursor positioning via control characters
--TODO: explore using custom font (new feature in PICO8 0.2.2) instead in future version
--TODO: add a way to print a sprite "muted/faded" (all in one color)
--      for the 'discarded card' style shown in hand
function printmspr(str,x,y,c)
  local xt,i=x,1  --xt=x pos on screen, i=char index in str
  while i<=#str do
    local ch=sub(str,i,i)
    if ord(ch)==5 then
      --control char to shift cursor x,y pixels
      --NOTE/TODO: accidentally different behavior from P8SCII
      --           this behavior is more useful in this program but
      --           it's confusing to look like P8SCII
      i+=1
      xt+=tonum("0x"..sub(str,i,i))
      i+=1
      y+=tonum("0x"..sub(str,i,i))
    elseif ord(ch)==12 then
      --change color
      i+=1
      c=tonum("0x"..sub(str,i,i))
    elseif ord(ch)==10 then
      --newline
      xt=x
      y+=6
    elseif minispr[ch] then
      --if ch represents a mini sprite, display that
      -- sprite instead of printing ch to screen
      spr(minispr[ch],xt,y)
      xt += 6
    elseif ch==":" or ch==" " or ch=="." then
      --tighter spacing around some characters
      print(ch,xt-1,y,c)
      xt += 3
      if (ch==".") xt-=1  --could remove?
    else
      --if nothing special, just print this character
      print(ch,xt,y,c)
      xt += 4
      if (ord(ch)>=128) xt += 4
    end
    i+=1  --advance to next index in str
  end
end

----function (not worth tokens unless used >11 places) 
---- to replace sub(str,i,i)
--function sub1(str,index)
--  return sub(str,index,index)
--end

-- simple print text wrapped to width<=w, break on spaces
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
      y+=6  --or could be 7 for more interline space...
    end
    print(sub(txt,1,w),x,y,c)
    y+=9
  end
end

-- accept a list of strings or a single string
-- print it (including minisprites) with a given border
-- TODO? could save a few tokens with single-line assignments
function textboxm(strs,x,y,w,h,b,c1,c2,c3,cf,c4)
  b=b or 1
  c1=c1 or 13 --border
  c2=c2 or 5  --bkgnd
  c3=c3 or 6  --txt
  if (type(strs)!="table") strs={strs}
  h=h or #strs*6+3
---  w=w or maxstrlen(strs)*4+3+3 --fit width to data?
  if (cf) fillp(0x5a5a)  --50% fill pattern
  rectborder(x,y,x+w-1,y+h-1,c2,c1)
  fillp()
  for i,str in ipairs(strs) do
    printmspr(str,x+b+1,y+b-5+6*i,c3)
  end
  --c4 = draw extra outer border (show selection, etc)
  if (c4) rect(x-1,y-1,x+w,y+h,c4)
end

----
---- 8) menu-draw and related functions
----

--draw multiple columns of cards / items using drawcard(),
-- with 0 to many of them highlighted as selected
-- and (typically) the currently selected one previewed large on the right
--used in many different places (hand, upgrades, profile, etc)
--TODO? trim some tokens w/ multiple assignments per line?
function drawcardsellists(clsts,x0,y0,sellst,style,spacing,modmode)
  --clsts = {list of lists of cards (one per column)}
  --sellst = list containing selected cards (for highlights)
  --style either sets style, or if ==9 it means "read style from card"
  --modmode = hacky: called from drawupgrademod() which needs diff behavior
  --note: can also be passed lists of strings not cards
  sellst = sellst or {}
  spacing = spacing or 36
  x0 = x0 or 0
  lg=false
  --y spacing is by default 10, or tighter-packed 8 if style==3
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
  --preview one card large (disabled if selx or y <=0)
  if selx>0 and sely>0 then
    local crd=clsts[selx][sely]
    --TODO? generalize this mod-specific code? but works fine for now, minimal tokens
    if (modmode) crd=descmod(crd)
    drawcard(crd,85,24,0,true,true,modmode)
  end
end

--alternative to more complex drawcardsellists():
-- draw a generic simple menu from a text lst
--TODO?: merge this with drawcardsellists() to save tokens?
--       (would have to add this "auto width box" and color parameters to that)
function drawselmenu(lst,x0,y0,c)
  c=c or 6
  for i,str in ipairs(lst) do
    local ym = y0+(i-1)*8
    printmspr(str,x0,ym,c)
    if (sely==i) then
      --selection rectangle auto-sized to content
      --NOTE: does not account for double-width characters correctly
      rect(x0-2,ym-2,x0+#str*4,ym+6,12)
    end
  end
end

-----
----- 9) miscellaneous helper functions
-----

---- 9a) message queue helper functions:

-- add string or list of strings to message queue
function addmsg(m)
  addflat(msgq,m)
  ----DEBUG tool: log all messages to a file
  --if (type(m)=="table") m=m[1]
  --if (logmsgq) printh(m, 'msgq.txt') --debug
end

function clrmsg()
  msgq={}
  --clear y offset for first new msg
  msg_yd=0
end

---- 9b) misc drawing functions

--filled rectangle with contrasting border
function rectborder(x0,y0,xf,yf,cbk,cbr)
	rectfill(x0,y0,xf,yf,cbk)
	rect(x0,y0,xf,yf,cbr)
end


---- 9c) LOS (line of sight)

--primitive sort-of-LOS based on path length
-- (not accurate in all cases but token-efficient by reusing pathfind)
--if "jump path" from a to d != manhattan distance, there's not LOS
function pseudolos(a,d)
--  print(#pathfind(a,d,true)-1) --debugging
--  print(#pathfind(a,d,true).." dst:"..dst(a,d)) --debugging
  local pth=pathfind(a,d,true)
  return pth and #pth-1==dst(a,d)
end

----another LOS test (not verified), ~53tok + calling tokens
--function los(a,d)
--  for i=0.1,1,0.1 do
--    if (fget(mget(flr(a.x+i*(d.x-a.x)+0.5),flr(a.y+i*(d.y-a.y)+0.5)),1)) return false
--  end
--  return true
--end

---- 9d) card parsing

-- parse a short single-card string into action, value, etc
--  e.g. "2MJ" -> crd.act="M", crd.val=2, crd.jmp=true, etc 
--       (but replace M, J  above with sh(m),  sh(j) chars)
--TODO? possible to simplify code to reduce tokens?
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
    if (ctbl.val==9) ctbl.val=99  --for the 'heal99' card
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
    --preprocess some common properties
    if (ctbl.mod==sh("j")) ctbl.jmp=true
    ctbl.rng=1
    if (ctbl.mod==sh("r")) ctbl.rng=ctbl.modval
    if (chrs[#chrs]=="H") ctbl.aoe=8
    ---if (ctbl.mod==sh("p")) ctbl.push=ctbl.modval --not implemented
    if (ctbl.mod==sh("z") or ctbl.mod2==sh("z")) ctbl.stun=true
    if (ctbl.mod==sh("w") or ctbl.mod2==sh("w")) ctbl.wound=true
  end
  return ctbl
end


---- 9e) deck and card helper functions

--generalized 'reshuffle discards' function
-- commented out to save 9 tokens since only
-- ever used to shuffle modifier deck at least in this chapter
-- (enemy actions not currently discarded/shuffled)

--function shuffle(deck,discard)
--  while (#discard>0) do
--    add(deck,deli(discard))
--  end
--end

--function shufflemod()
--  shuffle(pmoddeck,pmoddiscard)
--end

--special-cased "shuffle modifier discards back into deck"
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

--return discarded card or item to hand
-- abstracted to function that can be called via foreach()
-- to save some tokens, see for example use in longrest()
function refresh(crd)
  if (crd[3]==1) crd[3]=0
end

function clearcards(obj)
  obj.crds,obj.init,obj.crd=nil
end


----  9f) array and table helper functions (general-purpose)

function splitarr(arr)
  --split array into two ~half-length arrays
  local arr1={unpack(arr,1,ceil(#arr/2))}
  local arr2={unpack(arr,ceil(#arr/2)+1)}
  return arr1,arr2
end

--find x in tbl[], return index (or nil if not in table)
--if prop is not nil, find x in tbl[][prop] instead
function indextable(tbl,x,prop)
  for i,val in ipairs(tbl) do
    if not prop then
      if (val==x) return i
    else
      if (val[prop]==x) return i
    end
  end
  --implicit "return nil"
end

function sort(a)
  --sort by column 1
  --TODO: remove the tonum() hack and ensure player and enemy deck initiatives are numbers in data structs
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

--count occurances of items in list
--e.g. {a,b,a,a,c} -> {{"a",3},{"b",1},{"c",1}}
function countlist(lst)
  local counted={}
  for itm in all(lst) do
    counted[itm]=(counted[itm] or 0) + 1
  end
  return counted
end

--similar to add(), except if values is a table,
-- or a \n-separated multiline string,
-- add each of its members one by one
function addflat(table, values)
  if type(values)!="table" then
    --split multiline string into table, or
    -- convert singleline string to 1-element table
    values=split(values,"\n")
  end
  for val in all(values) do
    add(table,val)
  end
end
--function addflat_original(table, values)
--  if type(values)=="table" then
--    for val in all(values) do
--      add(table,val)
--    end
--  else
--    add(table,values)
--  end
--end

---- 9g) more data structure helper functions (data-specific)

function actorat(x,y)
  --return index into actor[] of the actor at loc
  for i,a in ipairs(actor) do
    if (a.x==x and a.y==y) return i
  end
  return 0
end

function initiativelist()
  --create list of order of enemy and player
  -- initiatives (list of actor[#] indexes)
  ilist={}
  for i,a in ipairs(actor) do
    --first element of first card = initiative
    add(ilist,{a.init,i,a.name})
  end
  sort(ilist)
  return ilist
end

--wrapper for common item case, 11tok
-- more cplx version: 38tok
function hasitem(itemname,useitem)
  local itemi=indextable(pitems,itemname,6)
  if (not itemi or pitems[itemi][3]!=0) return false
  --for items that can only be used once:
  if (useitem) pitems[itemi][3]=1
  return true
end

---- 9h) animation helper functions

--queue animation of obj move from x0,y0->x,y
--note: also modifies obj.x and obj.y values to equal destination! (which may be unexpected)
--TODO? move to another tab of code
function queueanim(obj,x,y,x0,y0,mspr)
  obj = obj or add(actor,{spr=mspr,noanim=true,ephem=true})
  obj.x,obj.y=x,y
  obj.sox,obj.soy=8*(x0-x),8*(y0-y)
  obj.ox,obj.oy=obj.sox,obj.soy
  animt=0
end

---- 9i) math helper functions

function dst(a, b)
  return abs(a.x - b.x) + abs(a.y - b.y)
end

---- 9j) fog

--init 11x11 map array as "fogged"
function initfog()
  --minimal-token hard-coded "init all to fog" array
  -- (but, character-inefficient)
  fog=splt3d("1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1|1;1;1;1;1;1;1;1;1;1;1")
end

--TODO? shift all maps to start at (1,1) on mapboard, 
--  to remove need for the +1s in these fns? (save ~8tok)
function isfogoroffboard(x,y)
  return (x<0 or x>10 or y<0 or y>10) or fog[x+1][y+1]
end

function unfog(x,y)
  fog[x+1][y+1]=false
end

--set all tiles in same room as (x,y) to unfogged, called
-- on door open, for example
function unfogroom(x,y)
  --naive rectangular algorithm, depends on careful map design and
  -- placement of "unfog limiting obstacles"
  --TODO? extend for non-rectangular rooms?
  if (fget(mget(x,y),6)) return
  local xf,yf,x0,y0=10,10,0,0  --TODO? could shave off both ,0s to save 2tok if level design is careful, but introduces risk of crash bug
  --find closest "walls" in each direction
  --originally had separate for loops to determine x limits and then y limits.
  -- this single loop is more token efficient but harder to read
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


-----
----- x) pause menu items
-----

-- DEPRECATED: had options to adjust difficulty,
--  message speed, etc, but trimmed tokens (and moved
--  difficulty selection to town menu)

--menu item for difficulty
--function difficultymenu(b)
--  if (b==1) difficulty-=1
--  if (b==2) difficulty+=1
--  --4 -> #difficparams?
--  difficulty=max(1,min(4,difficulty))
--  menuitem(5,difficparams[difficulty].txt,difficultymenu)
--end

----menu item for message speed
--function msgspeed(b)
--  if b&2>0 then
--    msg_td,animtd=2,0.08
--    menuitem(1, "< speed: fast", msgspeed)
--  elseif b&1>0 then
--    msg_td,animtd=4,0.05
--    menuitem(1, "speed: slow >", msgspeed)
--  end
--end

-----
----- 10) data string -> datastructure parsing + loading
-----

--split a data string separated by ; (workhorse function)
-- skipconv = don't convert to #
-- kv = parse as key/value set (e.g. x;1;y;2-> {x=1,y=2})
--TODO: invert skipconv true/false logic to match split()?
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

--split on / and | and ; into an up-to-3D array
-- if kv==true, further split into k/v pairs
-- e.g. splt3d("a;3;b;ab|a;4;b;cd",true) -> 
--            {{a=3,b="ab"},{a=4,b="cd"}}
function splt3d(str,kv)
  local lst1,arr3d=split(str,"/"),{}
  for i,lst2 in ipairs(lst1) do
    add(arr3d,{})
    local arr2d=split(lst2,"|")
    for lst3 in all(arr2d) do
      add(arr3d[i],splt(lst3,nil,kv))
    end
  end
  --remove any unused data layers
  while #arr3d==1 do
    arr3d=arr3d[1]
  end
  return arr3d
end

--read game data stored elsewhere in cart
-- decode a string from cart (typically from spr/sfx mem,
-- to be then run through split/etc to extract table data)
--reads backwards from specified address until chr \255
-- (so typically would be passed address of end of spr/sfx mem)
--see separate storedatatocart4r.p8 cart for usage+storing this data in first place
--only uses 25 tokens
function extractcartdata4r(addr)
  str=""
  while @addr!=255 do
    str..=chr(@addr)
    addr-=1
  end
  return str
end 


-----
----- 11) inits and databases
-----

--mini 5x5 sprites as icons for our 'custom font'
--TODO: explore pico8 0.2.2+ custom fonts
function initmspr()
  --[a]ttack, [m]ove, [h]eart, [g]old, [j]ump, [r]ange, [s]hield, [w]ound
  --[b]urn, [z]stun, [l]oot, [p]ush, [i]tem
  --[A]..[H] for AoE sprites #21-28 (only H used to date...)
  --[I]..[M] for item sprites (not used: [N]..[O] for 'used item' sprites)
  --[U],[D], [X] for simplified arrows (7x5) and ❎ (7x7)
  minispr=splt3d("█;5;😐;6;♥;7;●;8;웃;9;➡️;10;★;11;∧;12;▒;13;▥;14;⬅️;15;◆;4;H;28;☉;3;I;59;J;60;K;61;L;62;M;63;D;30;U;31;X;29",true)
  --,🅾️=30,❎=31}
  descact=splt3d("█;atk ;😐;move ;♥;heal ;●;gold ;웃;jump;➡️;@ rng ;⬅️;get all\ntreasure\nwithin\nrange ➡️;★;shld ;∧;wound;▥;stun;▒;burn;H;adjacent",true)
end

function initglobals()
  --TODO: pare more of these down
  map_w,msg_x0,msg_yd,hud_x0,hud_ey,hud_py=92,0,0,93,27,81
  --animation consts
  act_td,afram,fram,animt,wipe=15,0,0,1,0
  msg_td,animtd=4,0.05
  --game configurations
  difficparams=splt3d("txt;●easier● ;hp;-2;gp;1|txt;★normal★ ;hp;0;gp;1|txt;▥harder▥ ;hp;+2;gp;2|txt;▒brutal▒ ;hp;+5;gp;4",true)
  difficulty=2      -- 1=easier, 2=normal, 3=hard, 4=brutal
  -----(deprecated) initialize Pause Menu items
  --difficultymenu(0) -- create pause menu item
  --msgspeed(1)  --sets msg_td,animtd
  dirx,diry=split("-1,1,0,0"),split("0,0,-1,1")
  msgq={}
  --state inits
  state,prevstate,nextstate="","",""
  --init() function to call for each state
  initfn={newlevel=initnewlevel,splash=initsplash,town=inittown,
          endlevel=initendlevel,newturn=initnewturn,choosecards=initchoosecards,
          precombat=initprecombat,actloop=initactloop,
          actenemy=initactenemy,actplayerpre=initactplayerpre,actplayer=initactplayer,
          actplayermove=initactplayermove,animmovestep=initanimmovestep,
          actplayerattack=initactplayerattack,cleanup=initcleanup,profile=initprofile,
          upgradedeck=initupgrades,upgrademod=initupgrademod,store=initstore,pretown=initpretown}
end

--initialize a new level
function initlevel()
  --scaling gold and (TODO) traps with difficulty mode
  gppercoin,trapdmg=difficparams[difficulty].gp,4
  --gppercoin,trapdmg=1,4  --global consts
  lootedchests=0  --for alt wincon 'loot N chests'
  copylvlmap(dlvl)
  initfog()
  --init actors, add player as first actor
  actor={p}
  --if (godmode) p.maxhp=99
  if (hasitem("mail")) p.pshld=1 --persistent shield
  p.shld,p.stun,p.wound,p.hp=p.pshld,false,false,p.maxhp
  initpxy()
  unfogroom(p.x,p.y)
  initactorxys()
  --move queue-- list of steps taken by actor to dest
  mvq={}
  --refresh decks
  decksreset()
  foreach(pitems,refresh)
  --selection info
  selx,sely,showmapselselvalid=p.x,p.y,true,false  --could omit last ,false to save token?
  --hard-coded reset to boss level status if you fail boss level
  -- after reaching a mid-boss-level phase, and retry it
  -- usually does nothing. TODO? handle elsewhere? attach to boss code?
  bossphase2=false
  enemytype[#enemytype].id=#enemytype
  --reset cards and initiative
  foreach(enemytype,clearcards)
  tutorialmode=dlvl<7 --in tutorial mode extra strings are shown
  clrmsg()
end

--copy map for level l to the (0,0)->(10,10) region of map,
-- so all other game functions don't need to track a level-based
-- map offset and can just refer to that
function copylvlmap(l)
  for i=0,10 do
    for j=0,10 do
      mset(i,j,mget(i+lvls[l].x0,j+lvls[l].y0))
    end
  end
end

--locate player on map and set x,y variables
--also initiative # of doors in this map
--TODO? could hard-code this info in each level design DB,
-- saving ~40 tokens but taking effort to keep in sync
function initpxy()
  doorsleft=0
  for i=0,10 do
    for j=0,10 do
      if mget(i,j)==1 then  --found player start
        mset(i,j,33)
        p.x,p.y=i,j
      end
      if (fget(mget(i,j),7)) doorsleft+=1
    end
  end
end

--initiative all actors in unfogged parts of map
--NOTE: removed fget check for flag 0 and moved isfogoroffboard() check 
--      into et.spr line: saved ~9 tokens at cost of more 
--      processing by running each time in loop (could reinstate if needed but seems fine)
function initactorxys()
  for i=0,10 do
    for j=0,10 do
--      if fget(mget(i,j),0) and not isfogoroffboard(i,j) then
        for e,et in ipairs(enemytype) do
          if (et.spr==mget(i,j) and not isfogoroffboard(i,j)) then
            initenemy(e,i,j)
            mset(i,j,33)
          end
        end
--      end
    end
  end
end

--create instance of enemytype[n] at x,y
function initenemy(n,x,y)
  local etype=enemytype[n]
  en={type=etype,x=x,y=y,
      ox=0,oy=0,sox=0,soy=0,
--      maxhp=etype.maxhp,  --simpler pre-difficulty-setting method
      maxhp=etype.maxhp+difficparams[difficulty].hp,
      spr=etype.spr,
      name=etype.name,
      pshld=etype.pshld}
  --special case modify an enemy if quest item found
  if (etype.name=="elem" and hasitem("slvst")) en.pshld=0
  en.shld,en.hp=en.pshld,en.maxhp
  if (en.hp>0) add(actor,en)  --if difficulty level means enemy hp<1, don't create
end

--initiatize major databases of level, enemy, player information
--
--much of this created in an external spreadsheet for easier editing, 
-- which then joins the values into these nested or key-value arrays
function initdbs()
  --- init level dbs (long string)
  lvls=splt3d("name;test level;x0;11;y0;0;unlocks;2;xp;150;gp;150|name;unnamed tomb;x0;22;y0;0;unlocks;3,4;xp;60;gp;0|name;elgin mausoleum;x0;33;y0;0;unlocks;7,8;xp;30;gp;0|name;another tomb;x0;44;y0;0;unlocks;5;xp;10;gp;0|name;another tomb ;x0;55;y0;0;unlocks;6;xp;10;gp;0|name;another tomb  ;x0;66;y0;0;unlocks;4;xp;10;gp;0|name;elgin manor road;x0;77;y0;0;unlocks;11;xp;30;gp;0|name;job: guard caravan;x0;88;y0;0;unlocks;9;xp;20;gp;30|name;job: rescue hunter;x0;99;y0;0;unlocks;;xp;20;gp;20|name;job: defeat bandits;x0;110;y0;0;unlocks;;xp;20;gp;30|name;elgin manor;x0;0;y0;11;unlocks;12,13;xp;40;gp;0|name;mage guild;x0;11;y0;11;unlocks;14,15;xp;30;gp;30|name;ruined chapel;x0;22;y0;11;unlocks;17;xp;60;gp;0|name;mountain pass;x0;33;y0;11;unlocks;;xp;20;gp;0|name;guild library;x0;44;y0;11;unlocks;16;xp;20;gp;0|name;sewers;x0;55;y0;11;unlocks;17;xp;20;gp;0|name;catacombs;x0;66;y0;11;unlocks;18;xp;40;gp;0|name;lower catacombs;x0;77;y0;11;unlocks;;xp;100;gp;0",true)
  --unlock starting level
  lvls[dlvl].unlocked=true
  --extract some wordy level text stored in extra spr/sfx mem
  -- (stored using separate storedatatocart4r.p8 cart)
  fintxt=splt(extractcartdata4r(0x1fff))
  pretxt=splt(extractcartdata4r(0x42ff))
  --random treasure options, by level (1=easy,2=normal,4=brutal)
  rndtreasures=splt3d("g;10|g;8|g;7|g;6|g;5/g;10|g;8|g;7|g;6|g;5|d;2/g;20|g;15|g;15|g;10|g;10|d;4/g;30|g;25|g;20|g;15|d;6")

  --- init enemy dbs
  --enemy types: data string compiled from separate spreadsheet
  enemytype=splt3d("id;1;name;skel;spr;116;maxhp;4;pshld;0|id;2;name;zomb;spr;112;maxhp;8;pshld;0|id;3;name;skel+;spr;88;maxhp;6;pshld;1|id;4;name;zomb+;spr;84;maxhp;12;pshld;0|id;5;name;sklar;spr;120;maxhp;3;pshld;0|id;6;name;cult;spr;100;maxhp;6;summon;1;pshld;0|id;7;name;bandt;spr;128;maxhp;6;pshld;0|id;8;name;archr;spr;132;maxhp;4;pshld;0|id;9;name;wolf;spr;96;maxhp;5;pshld;0|id;10;name;warg;spr;104;maxhp;9;pshld;1|id;11;name;drake;spr;124;maxhp;15;pshld;2|id;12;name;elem;spr;108;maxhp;15;pshld;8|id;13;name;rune;spr;92;maxhp;5;pshld;0|id;14;name;noah;spr;140;maxhp;18;summon;12;pshld;0",true)
  --enemy action decks (options) from separate spreadsheet
  enemydecksstr="57;😐3|;█3/60;😐1|;█4/30;😐2|;♥2/21;😐3|;█2/19;😐2|;█2,78;█6/72;😐1|;█4/56;😐1|;█2∧/67;😐1|;█5,57;😐4|;█4/60;😐2|;█5/30;😐3|;♥3/21;😐4|;█3/19;😐3|;█3,78;█8/72;😐1|;█6/56;😐2|;█3∧/67;😐1|;█5∧,21;😐1|;█2➡️3/40;█3➡️3/50;😐1|;█1➡️4∧/70;█3➡️3/37;😐1|;█1➡️3,40;😐1|;█1/30;😐1|;█2/90;call,40;😐2|;█3/55;😐1|;█4/28;😐3|;█2/21;★2|;😐2/28;★2|;♥2,24;😐1|;█2➡️4/40;█3➡️4/50;😐1|;█1➡️6∧/36;😐1|;█2➡️5,65;howl/11;😐4|;█3/22;😐5|;█2/35;😐4|;█2∧,60;howl/8;😐4|;█4∧/17;😐5|;█2∧/20;😐4|;█3∧,57;😐1|;█3/60;😐1|;█4/72;😐1|;♥2/38;█6➡️3/31;😐2|;█2,78;😐1|;█5/72;😐1|;█4/53;😐2/60;😐1|;█3➡️3,95;█1|;♥1/95;█1|;♥1,40;█3➡️4/53;█2➡️5/70;♥1|;█1➡️7/60;█1➡️6∧/43;█1➡️6▥,43;call/40;😐3|;█3➡️4/53;😐1|;█2➡️5/70;♥1|;█1➡️7/60;😐2|;█2➡️6/43;😐1|;█1➡️6▥,40;😐3|;█3➡️4/53;😐1|;█2➡️5/70;♥1|;█1➡️7/60;😐2|;█2➡️6/43;😐1|;█1➡️6▥/85;♥3"
  enemydecks={}
  --for 4d nested data, further split:
  --TODO? move below into splt3d() as a more general splitting? Maybe w/o "," sep?
  for ed in all(split(enemydecksstr)) do
    add(enemydecks,splt3d(ed))
  end

  --- init player dbs (and upgrades)
  --player info
  p=splt3d("name;you;spr;66;bigspr;64;lvl;1;xp;0;gold;10;maxhp;10;pshld;0;ox;0;oy;0;sox;0;soy;0",true)
  --all potential player cards, combining the starting N plus 2 upgrades/level
  --[0]=initiative, [1]=actionstring, [2]=status, [3]=card name
  -- string created in separate spreadsheet
  pdeckmaster=splt3d("15;😐2;0;\n  dash|35;😐3웃;0;\n  leap|45;█3;0;\n  chop|20;█2;0;\n   jab|42;█2➡️3;0; spare\n dagger|65;♥4▒;0; first\n  aid|60;█2;0;\n  stab|18;★2;0; braced\n stance|60;😐4;0;\nsidestep|70;█5➡️2▒;0;  hurl\n  sword|80;⬅️1;0;  loot\nlocally|45;█4;0;\n slash|31;😐5웃;0; mighty\n  leap|80;⬅️4▒;0; gather\ngreedily|41;█3H;0;\n stomp|17;█2▥;0;\nconcuss|65;█3➡️3;0;\njavelin|11;★4;0;\n  defy|34;█3∧;0;\n lance|64;█8▒;0; mighty\n swing|38;█4∧H▒;0; blade\ntornado|73;😐6웃;0; up and\n  over|46;♥3;0;bandage\n  self|34;█6;0; expert\n  blow|40;█7▥▒;0; giant\n killer|28;hail▒;0;hail of\nblades\n\n\f6█5 all\n enemies\n within\n rng ➡️3\n\n\f8burn\f6 crd\n on use|62;♥99▒;0;  rise\n again|99;rest;0;  long\n  rest\n\n\f6heal 3\n\+03refresh\n items\n\+03\f8burn\f6 the\n2nd card\n chosen")
  --hard-coded 'long rest' card
  longrestcrd=pdeckmaster[#pdeckmaster]
  --init initial player deck
  pdeck={}
  pdecksize=11
  for i=1,pdecksize do
    add(pdeck,pdeckmaster[i])
  end
  sort(pdeck) --sort by initiative for easier viewing
  --player modifier deck (original)
  pmoddeck=splt("/2;-2;-1;-1;-1;-1;+0;+0;+0;+0;+0;+0;+1;+1;+1;+1;+2;*2",true)
  --pmoddeck=splt("+0;*2;*2;*2",true) --DEBUG *2 mod
  pmoddiscard={}
  --all potential mod upgrades, combining the starting set
  --(first pmodupgradessize items) and then add one more per lvl
  pmodupgradesmaster=splt("-2;-1;-1;-1>+0;+0;+0>+1;+0>+2;+0>+2;>+2;+0>+1∧;>+1∧;>+2;+1>+2∧;>+3;+1>+2∧",true)
  pmodupgrades={}
  pmodupgradessize=7
  for i=1,pmodupgradessize do
    add(pmodupgrades,pmodupgradesmaster[i])
  end
  pmodupgradesdone={}

  ---init equipment dbs (also from spreadsheet)
  storemaster=splt3d("50;😐 swift   50●;0; swift\n boots\n\n\f6default\n 😐2 is\n now 😐3;😐;swift|60;K life\+40   60●;0;  life\n charm\n\n\f6negate a\n killing\n blow\n\n(refresh\n on long\n rest);K;life|40;웃 belt\+40   40●;0; winged\n  belt\n\n\f6😐 moves\n are all\n 웃 jumps;웃;belt|50;J barbs   50●;0; barbed\ngauntlet\n\n\f6default\n █2 also\n wounds∧;J;barbs|60;I goggl   60●;0;  keen\ngoggles\n\n\f6+2➡️ rng\n for all\n ranged\n attacks;I;goggl|30;★ shld\+40   30●;0; great\n shield\n\n\f6★2 first\n round\n attackd\n\n(refresh\n on long\n rest);★;shld|90;L mail\+40   90●;0; great\n  mail\n\n\f6permnent\n +★1;L;mail|;done;0;\n  done\n\n\f6return\nto town;;done|999;M slvst;0;slvrstl\n blade\n\n\f6blade of\nmystical\nmaterial\nthat can\npierce\nelements;M;slvst")
  store={}
  for item in all(storemaster) do
    add(store,item)
  end
  --extract silversteel quest item
  -- TODO? could hard-code silversteel index to save 3 tokens
  slvrstl=storemaster[indextable(storemaster,"M slvst",2)]
  del(store,slvrstl)
  pitems={}
end

-----
----- 12) profile / character sheet
-----

---- state: view profile

function initprofile()
  selx=0  --ensure cursor is off-screen when drawn
  _updstate,_drwstate=_updprofile,_drawprofile
end

--TODO: refactor how items are displayed
--      (currently has hack to display item list near right 
--       of screen so "cost" in name is drawn off-screen)
function _drawprofile()
  rectborder(0,0,127,127,5,13)
  spr(p.bigspr,5,4,2,2)
  --lots of printing embedded in one long string to save tokens
  printmspr("\+f0\+50\f6warrior\+b0lvl \f6"..p.lvl.."\f6\+d0xp \f6"..p.xp.."\n\+f0\+f0\+f0\+e1♥\+90\f6"..p.maxhp.."   ●\+50"..p.gold.."\n\+0a\f6actions:\+b0mods:\+f0\+70☉items:",7,6)
  line(1,24,126,24,13)
  drawcardsellists({pdeck,countedlststr(pmoddeck),pitems},-2,31,nil,3,42)
--  print("🅾️:exit",84,118,1)
end

--summarize # of each item in a list, into list of strings.
--e.g. {1,2,1,1,3} -> {"3x 1","1x 2","1x 3"}
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

-----
----- 13) splash screen / intro
-----

function initsplash()
  _updstate,_drwstate=_updsplash,_drawsplash  
  splashmenu={"start new game"}
  --selx,sely=1,1 --not needed as set in changestate()
  if (dget(0)==0) add(splashmenu,"continue game",1)
end

function _updsplash()
  selxy_update_clamped(1,#splashmenu)
  if btnp(🅾️) then
    if splashmenu[sely]=="continue game" then
      load_game()
      changestate("town")
    else
      dset(0,0)  --overwrite existing saved game
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
--    rect(63,0,64,127,15) --debug centering

---- animate stars (commented out to save tokens)
--    for i=1,20 do
--      pset(rnd(128),rnd(128),5)
--    end
  end
end

-----
----- 14) levelup, upgrades
-----

-- upgrade action deck --

function initupgrades()
  p.maxhp+=1+p.lvl%2  --alternating +2hp, +1,+2,+1 with each level
  p.lvl+=1
  addmsg("upgrade action deck:\nchoose an upgrade\ncard and a card to\nreplace. \fc🅾️\f6:confirm")
  selx,selc=2,{{},{}} --sely already set=1 in standard changestate()
  msg_x0,msg_w=44,84
  --list of existing deck and the 2 available upgrades
  upgradelists={pdeck,pdeckupgrades(p.lvl)}
  _updstate,_drwstate=_updupgradedeck,_drawupgrades
end

--return the array of two cards available for level LVL upgrade
function pdeckupgrades(lvl)
  return {pdeckmaster[pdecksize+(lvl-1)*2-1],pdeckmaster[pdecksize+(lvl-1)*2]}
end

--player selects a card in existing deck and an upgrade
-- card to replace it (no confirmation step: once two are
-- selected the upgrade is performed)
function _updupgradedeck()
  selxy_update_clamped(2,#pdeck)
  sely=min(sely,#upgradelists[selx])
  if btnp(🅾️) then
    local c=upgradelists[selx][sely]
    if selc[selx]==c then
      --if chose existing selection, deselect
      selc[selx]={}
    else
      --assign selection from this column
      selc[selx]=c
    end
    local c1,c2=selc[1],selc[2]
    if #c1>0 and #c2>0 then
      --one card from each column selected...
      addmsg("card "..c1[2].." -> "..c2[2])
      add(pdeck,c2)
      del(pdeck,c1)
      sort(pdeck) --re-sort by initiative, in place
      --selc={{},{}}
      changestate("upgrademod")
    end
  end
end

-- upgrade mod deck
function initupgrademod()
  --add one more upgrade option each level
  addmodupgrade(p.lvl)
  addmsg("choose an upgrade\nfor your modifier\ndeck. \fc🅾️\f6:confirm")
  selx,selc=2,{}  --sely already set=1 in changestate
  msg_x0,msg_w=44,84
  upgradelists={countedlststr(pmoddeck),pmodupgrades}
  _updstate,_drwstate=_updupgrademod,_drawupgrades
end

--each new level adds one new mod card upgrade option
--(pool size should stay constant since you use one with
-- each levelup)
--this can also be called in a loop by save_game() to restore
-- the state of this upgrade deck
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

--shared draw function for "upgradedeck" and "upgrademod" states since
-- they are similar. uses global upgradelists
function _drawupgrades()
  clsrect(5)
  printmspr("\f6deck:\+a0upgrades:",15,5)
  drawcardsellists(upgradelists,0,10,selc,0,nil,state=="upgrademod")
  drawmsgbox()
end

-- process a mod like "-1<+0" to edit the player mod
--  deck and remove from upgrade deck
function upgrademod(mod)
  local desc,rc,ac=descmod(mod)
  if (rc) del(pmoddeck,rc)
  if (ac) add(pmoddeck,ac)
  del(pmodupgrades,mod)
  add(pmodupgradesdone,mod)
end

--text description of what a mod upgrade will
-- do, to show player
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

-----
----- 15) town and retirement
----- 

function inittown()
  if (prevstate=="splash" or prevstate=="pretown") music(8)
  --TODO: add animation of a spinning save/disk icon?
  save_game()
  --selx,sely=1,1 --not needed as reset in changestate()
  townmsg="you return to the town of picohaven. "
  --create list of town actions
  townlst=splt("view profile;shop for gear")
  if p.xp>=p.lvl*60 and p.lvl < 9 then
    townmsg..="you have gained enough xp to level up! "
    add(townlst,"* level up *",1)	
  end
  if wongame then
    add (townlst,"* retire *",1)
  else
    --create list of accessible levels
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
      --this state will also levelup p.lvl, p.maxhp
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

--store
function initstore()
  addmsg("you browse the store..\n\fc🅾️\f6:select")
  --selx,sely=1,1 --not needed as reset in changestate()
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

--TODO: different way to show prices?
--      (current HACK embeds them in item names...)
function _drawstore()
  clsrect(5)
  drawcardsellists({store},5,10)
--  printmspr("\f6store:\+f0\+f0\+20you have:\+10"..p.gold.."●\n\+f0\+f0\+f0\+f0\+97●\+20cost◆",17,4)
  printmspr("\f7you have: ●"..p.gold,13,4)
  drawmsgbox()
end

--fully end-of-game
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

-----
----- 16) debugging + testing functions
-----     [comment out near release if tokens needed]
-----

----table debug, 58tok
---- often called as print(dump(tblofinterest))
--function dump(o)
--  if type(o) == 'table' then
--    local s = '{ '
--    for k,v in pairs(o) do
--        if (type(k) ~= 'number') k = tostr(k)
--        s = s .. '['..k..'] = ' .. dump(v) .. ','
--    end
--    return s .. '} '
--  else
--    return tostring(o)
--  end
--end

-----
----- 17) pathfinding (A*)
-----

--return move queue from [a]ttacker to [d]efender
--if jmp, allow jump (move through obstacles), currently
--  only used for a hacky LOS test but would be needed for
--  jumping/flying enemies if they existed
function pathfind(a,d,jmp,allyblocks)
-- TODO? remove start,goal and pass a,d directly into 
--      find_path, since a and d have .x/.y properties?
--  local start=xylst(a.x,a.y)
--  local goal=xylst(d.x,d.y)

  --set which "allowable neighbors" function to use in A* path_find()
  local neighborfn=valid_emove_neighbors
  --  if (jmp) neighborfn=valid_emove_neighbors_jmp
  --  if (allyblocks) neighborfn=valid_emove_neighbors_allyblocks
  if (jmp) neighborfn=function(node) return valid_emove_neighbors(node,false,true) end
  if (allyblocks) neighborfn=function(node) return valid_emove_neighbors(node,false,false,true) end

  return find_path(a,d,dst,neighborfn)
--  return find_path(start,goal,dst,neighborfn)
end

--- pathfinder (by @casualeffects, with some small mods)
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
    add(p, shortest.last,1)  --insert @ beginning of path
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


-----
----- 18) load/save
-----

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
  --player stats
  p.lvl=dgetn()
  p.maxhp=dgetn()
  p.xp=dgetn()
  p.gold=dgetn()
  wongame = dgetn()==1
  difficulty=dgetn()
  --load player action cards
  dindx=10
  pdeck={}
  for i=1,dgetn() do
    add(pdeck,pdeckmaster[dgetn()])
  end
  --player mod cards
  --load list of mod upgrades applied in past
  -- then apply one by one as if leveling up
  dindx=25
  for i=1,dgetn() do
    addmodupgrade(i+1)
    upgrademod(pmodupgradesmaster[dgetn()])
  end
  --items, including the event item slvrstl
  dindx=35
  pitems={}
  for i=1,dgetn() do
    local item=storemaster[dgetn()]
    add(pitems,item)
    del(store,item)
  end
  --load list of unlocked levels
  dindx=45
  for i=1,dgetn() do
    lvls[i].unlocked=false
    if (dgetn()==1) lvls[i].unlocked=true
  end
end

function save_game()
--  printh("saving game...","log.txt")
  dindx=0
  dsetn(1)  --indicate there is a saved game
  --player stats
  dsetn(p.lvl)
  dsetn(p.maxhp)
  dsetn(p.xp)
  dsetn(p.gold)
  --set to 1 if true, 0 if false
  dsetn(wongame and 1 or 0)
  dsetn(difficulty)
  --player action cards
  save_helper(10,pdeck,pdeckmaster)
  --player mod cards -- save deltas from original
  save_helper(25,pmodupgradesdone,pmodupgradesmaster)
  --player equip
  save_helper(35,pitems,storemaster)
  --levels unlocked (# of levels noted)
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

--noticed common code, extracted it here to save tokens
function save_helper(indx,objtbl,mastertbl)
  dindx=indx
  dsetn(#objtbl)
  for x in all(objtbl) do
    dsetn(indextable(mastertbl,x))
  end
end
 