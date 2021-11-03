Developer notes-to-self to accompany PICOhaven source code, to make it easier to remember the big picture if I take a break and come back to it.

These have not been fully cleaned up so may have some obsolete notes...

# Running Game
This file is focused on development notes not play notes. See [README.md](README.md) for a game overview and where and how to play it.

# Development Workflow / Build + Run notes
- Edit the source code in picohaven###.lua (using VScode or another external editor-- it is too large for the PICO-8 built-in editor to open with its in-code comments)
- Whenever you want to run it, strip comments and whitespace with a command like:
  -  `./minify_reg.sh picohaven100e.lua minify_rules2.sed > picohaven100e_minify.lua`
- In PICO-8, load and run picohaven100.p8 (which as of this writing is a cart that just includes sprite, sfx, and game data, and includes the source in picohaven100e_minify.lua). If it's already open you can just hit Ctrl-R (after running the minify_reg command above)
- INFO at the PICO-8 commandline will show token/character usage

# Source code organization & overview

The source code itself has a table of contents for code organization and moderately detailed comments. In addition, some notes I refer back to during development:

## Sprite Flags

- 0: actor initialization during initlevel
- 1: impassible (to move and LOS)
- 2: impassible move (unless jump), allows LOS
- 3: animated scenery (default: 4 frames)
- 4: triggers immediate action (trap, door)
- 5: triggers EOT action (treasure)
- 6: edge of room (unfog up to this border)
- 7: is doorway

## Gameflow State Machine

Generally, the game uses a state machine to partition different gameplay (i.e. different update and draw behavior) into different functions, rather than one update function with many if statements or global variables that set behaviors. changestate() changes to a new state, calling its init function, which typically sets the new update and draw functions if needed.

![state diagram](picohaven_state.png)

However, there's some overhead in coding a new state, especially if its behavior is very similar to other states or only used in one place, so some changing gameplay within states is controlled by global variables (see below for the many global variables that indicate for example the phase of a boss fight, whether the message box is in 'interactive scrolling mode', and so on).

## Global Variables Summary

Global variables and data structures are used liberally to avoid burdening every function call with extensive lists of parameters, given the strict code size limitations. To mitigate the risks of this, all other variables should be explicitly declared as local, and I keep a summary of global variables here to refer back to.

**debugging** (currently removed to save tokens):
- `debugmode` (bool)
- `logmsgq` (bool)

**flow control and state related**:
- `state, prevstate, nextstate` -- prevstate/nextstate used by a few functions that run and then proceed to next state or return to previous state
- `_updstate, _drwstate` -- current update/draw routines, different depending on state
- `_updprev` -- previous _updstate function: used to store an _updstate to return to after execution a specialized _upd function it's not worth changing state for (for example for msgq review)
- `initfn[]` -- array of init functions to run when changing to [state]
- `msgq` -- queue of strings to display in msgbox (max length ~22 chars/line depending on char)

**gameplay / level related**:
- `dlvl` -- dungeon level
- `doorsleft` -- doors left to open in level, part of check for end of level
- `fog[]` -- 11x11 array with either '1' (fog of war) or 'false' (unfogged)
- `gppercoin` -- scales with difficulty
- `trapdmg`
- `mapmsg` -- message to show in map area (at beginning and end of level)
- `pretxt[], fintxt[]` -- pre- and post-level text to display (stored in unused sprite/sfx memory by a separate cart compresstxt.p8 and retrieved during runtime using decode4r(), to save ~7k characters)
- `tutorialmode` -- determines whether to display additional messages and tips
- `difficulty`
- `difficparams[]` -- sets HP and gold scaling per level, etc (and description)

**Special wincons, event triggers**:
- `lootedchests` -- # of chests looted in level (sometimes an alt wincon or trigger)
- `bossphase2` -- trigger special phase 2 of boss fight
- `wongame` -- trigger "reture" option in town



**animation-related**:
(the .ox/.sox approach to animation is based on the system seen in the Lazy Dev Academy Roguelike youtube videos)
- `animt` -- animation timer: set to 0 to initiate animation-only updates that increment animt, until animt=1 
- `.sox, .soy` -- the starting location (in pixels) of an object we're animating the motion of
- `.ox, .oy` -- the current during-animation display offset (in pixels) of an object we're animating the motion of. when animt=1, .ox,.oy should have decreased to zero, as the object should be displayed at its final location.
- `fram` -- increments every cycle through program
- `afram` -- animation frame, cycles from 0->3 repeatedly
- `animtd` -- increments  of animt from 0-1  during animation (lower increment = slower animations)
- `shake` -- how many pixels to shake the map area by each frame, used for specialized animations (0 = no shaking)
- `screenwipe` -- ranges from 0 (no wipe) to 63 (initiative wipe)
- `msg_td` -- scroll msg every # frames
- `act_td` -- update actor anims every # frames

**UI selection related**:
- `selx, sely, seln` -- x, y, and n positions of selection cursor within a list (seln = position in a 2D list)
- `selvalid` -- true = current selection is valid (mostly used to check valid move and attack targets for player)
- `showmapsel` -- true = show yellow selection cursor on map (typically paired with the update() function calling selxy_udpate_clamped() to update selx, sely)

**cards and deck-related**
- `pdeck` -- player deck of cards (each element a crd data stricture)
- `tpdeck` -- pdeck with virtual "rest" card appended, for choosecards()
- `longrestcrd` -- pointer to long rest card in master deck
- `crdplayed` -- globally saved link to card currently being played by player, so that we can provide an option to undo an action and restore card/deck state before it's completed
- `crdplayedpos` -- where in card list this was, to allow smooth insertion back into list in case of undo

**Card data structures**. Enemy cards may only have [0] and [1] fields:
- `card[0]` = initiative
- `card[1]` = card 'code' that describes action (e.g. `█2➡️3∧` = "attack 2 at range 3 and wound")
  - `descact[]` is a lookup table that maps █ to attack, for example
- `card[2]` = status (0 = in hand, 1 = discarded, 2 = burned)
- `card[3]` = title (e.g. "hurl sword")

**Crd "parsed individual card actions" structure**. For example, from the sample `█2➡️3∧` card above:
- `crd.act, crd.val` -- action and value, e.g. `█,2` for "attack 2" 
- `crd.mod, crd.modval` -- 2nd param and value, e.g. `➡️,3` for "range 3"
- `crd.rng` -- attack range (if any), 1 for melee
- `crd.stun, crd.wound` -- if card inflicts that condition
- `crd.burn` -- if burned after use (player only)
- `crd.aoe` -- to indicate one of various Area-of-Effect patterns is applied to the attack (only one simple pattern is implemented)
- `crd.special` -- for special player or enemy actions that don't fit the above and have custom code for handling them, e.g. "call" (summon), "rest", "howl" etc

**`actor[]` data structures**:
the below are all properties of form `actor[n].foo` e.g. `actor[n].crds`, often used with alias `a=actor[n]` to be `a.hp`, etc.
Note that `actor[1]` is initialized to = `p` (the player data structure, with similar fields)
- `spr` -- first sprite frame (and the following 3 for animation)
- `bigspr` -- player only: index of 16x16 profile sprite
- `lvl` -- player level
- `x, y` -- locations (in map tiles, 0-10)
- `hp, maxhp, xp, gold` -- (no xp, gold for enemies)
- `shld` -- shield value (0 if no shield)
- `pshld` -- persistent shield (restored each round)
- `stun, wound` -- true/false (or often, true/nil) statuses
- `crds` -- list of cards (card data structure above) to play or choose from this turn. for enemies, 1-2 entries. for player, can be 1, 2, or 4.
- `crd` -- card currently being acted on (in the "crd parsed individual card actions structure" noted above)
- `init` -- current turn initiative
- `crdi` -- index of card within a.crds[] to play next. only used for enemies, to keep track of position in a list of cards to play.
- `type` -- for enemies, links back to a row in the `enemytypes[]` data structure which includes the deck,e tc
- `actionsleft` -- for player, list of actions they can still take this turn (starts at 2, decrements)
- `noanim` -- property of actors[] that don't have frames to animate through
- `ephem` -- property of actors[] which are ephemeral visual indicators that should only exist for an animation cycle and then be deleted (attack / damage animations)

**enemytype[] data structure**:
- `enemytype.crds, .crd, .init` -- redundant with above? tbd
- `.hpdrawn` -- a temporary value used during drawheadsup() to track whether an instance of this enemytype has been drawn with its details (due to being selected on map), to avoid drawing other instances of the same enemytype over it

**Town and upgrades related** (misc):
- `townmsg` -- message to show in town
- `townlst[]` -- list of in-town menu options (dynamically generated)
- `upgradelists` -- global used by two different upgrade routines (deck and mod) to pass list of lists to draw function (to share same draw function)
- `pmodupgradesmaster` -- mod upgrades available, combining the starting set (the first `pmodupgradessize`) and 1 more per levelup
- `pdeckmaster[]` -- all potential player deck cards (of the `card[]` data structure above), combining the starting pdeck (the first `pdecksize` entries) and future upgrade options (2 upgrade cards per level)

**Turn sequencing** (tracking active actor, action, etc):
- `ilist[], initi` -- list of `{initiative, actor#}` pairs for all actors this turn, sorted in initiative order. `initi` is the index of the row within this list currently acting
- `actorn` -- index for actor[] of the active actor (during turn execution, read from sorted-by-initiative list of actors in ilist)
- See also actor.crds, .crdi, .init, and similar above in the actor data structure notes

**Other** (to organize):
- `mvq` -- list (queue) of adjacent squares the current actor is moving through, starting at current position, in format `{{x=x0,y=y0},{x=x1,y=y1},...}`. Used to move and animate an actor through a path, checking for triggers (traps, doors, etc) at each step
- `dirx[], diry[]` -- save tokens for common x/y +-1 offsets
- `restburnmsg` -- message describing which card was burned for a "long rest" (chosen during choosecards() but not displayed until player action)
- `godmode` -- sets player hp/attacks/move/range to large #s behind the scenes (inflated atk/mv/rng not shown in cards). *disabled to save tokens*
- `avatars, avatar` -- selection of name, small sprite, and large sprite (for profile) for player to provide a few options: DEPRECATED to save tokens

**Major game content DBs loaded from strings** (some also listed in sections above):
- `lvls[]` -- all non-map data for each level. generated by writing out level info an external spreadsheet which compiles them into one long string to be split.
- `pretxt[], fintxt[]` -- pre- and post-level text to display (stored in unused sprite/sfx memory by a separate cart compresstxt.p8 and retrieved during runtime using decode4r(), to save ~7k characters)
- `enemytype[]` -- 
- `enemydecks[]` -- list of cards per enemy, indexed using `enemytype.name` or `actor.name` as key
- `pdeckmaster[]` -- all potential player deck cards (of the `card[]` data structure above), combining the starting pdeck (the first `pdecksize` entries) and future upgrade options (2 upgrade cards per level)
- `pmoddeck` -- initial modifier deck
- `pmodupgradesmaster` -- mod upgrades available, combining the starting set (the first `pmodupgradessize`) and 1 more per levelup
- `rndtreasures` -- selections for each chest, ranging from [g]old to [d]amage to [x]p
- `storemaster[], store[], pitems[]` -- similarly: master list of all items in game, items currently in store, and items owned by player
- `slvrstl` -- pointer to special item in storemaster[] (not available in store)-- silversteel blade found in one level

**Persistent data (save/load)**:
- `dgetseti` -- auto-incrementing index allowing dget()/dset() to not specify index on each call

**UI layout related** (many of them constants, to avoid hard-coding a lot of numbers and make tweaks simpler):
- `msg_x0` -- x offset added to message box (0 for normal location)
- `msg_w` -- width of message box
- `msg_yd` -- pixel-level scrolling offset of msgbox
- `map_w` -- width of map including border (also typically of message box)
- `hud_x0` -- x0 of HUD column
- `hud_py` -- actor box on HUD: y pos
- `hud_ey` -- enemy HUD y pos and spacing (at 0, hud_ey, hud_ey*2, etc) 
- `ehudn[]` -- formerly a global, turned into local in drawheadsup() and recalculated every cycle
- `gc_fg, gc_bg, gc_bg2, gc_sel` -- (DEPRECATED, hard-coded once selected, to save tokens) four global colors used (especially gc_bg = background color for e.g. profile and card selection screens, and gc_sel = selection box color)
- `minispr` -- maps special characters to sprites to display instead (in printmspr()), e.g. Shift-A special character = "attack" option, also see `sh()` and the Sprite "font" notes below:

## Sprite "font"
Various characters outside the standard alphanumeric \[a-z0-9\] encode specific sprites, see `minispr[]`. Example sprites:
![example sprites](minispr_examples.png)

Letters written in 'puny font' (appear as CAPS in text editor, CHR(65) to CHR(90)):
- [A]..[H] for AoE sprites #21-28 (only H used to date, for AoE pattern #8, '8 adjacent cells include diagonals'...)
- [I]..[M] for item sprites (created but not currently used: [N]..[O] for 'used item' sprites)
- [U],[D], [X] for simplified arrows (7x5) and ❎ (7x7)

Shift+letter (i.e. replacement for the extended double-width characters, CHR(128) to CHR(153)):
- [a]ttack, [m]ove, [h]eart, [g]old, [j]ump, [r]ange, 
- [s]hield, [w]ound, [b]urn, [z]stun, [l]oot, [p]ush, [i]tem
For example, "웃" is what PICO-8 displays if you press shift-j, this is CHR(127) and is used to symbolize "jump" or to print the "jump sprite", whose number is stored in minispr["웃"]

## enemy and player cards-to-play data structures
- p.crds (array of 4 playable full cards, init and all)
- p.crd: parsed data struct (.act,.val,.stun, etc) for card currently being played
- p.init
- a.crds or a.type.crds: list of enemy cards (redundant)
- a.crd: data struct for card currently being played
- a.init or a.type.init (redundant)

---

# Token / resource usage

During development I regularly ran into resource limits (tokens, characters, compressed size). Keeping some notes here about resource usage (more in notebook)

## token inventory 2021-08-25 (out of ~7900):
*=areas to look at for savings?
-  350 (first tab: state machine and some inits)
-  870 (precombat states)
-  1700 (act states)
-  *500 (postcomb states)
-  *1200 (main ui draw)
-  *500 (custom text/box/sprite)
-  300 (misc deck/arr helpers)
-  140 (math helpers)
-  *900 (inits, dbs) -- also 9kchar, 20% compressed size
-  250 (profile)
-  70 (splash)
-  *500 (levelup, upgrades)
-  170 (town)
-  60 (debug, test)
-  360 (A*)

## token inventory of v1.0e release, 2021-Oct

Total resource usage: 
- 8163 / 8192 tokens
- 41356 / 65535 characters (after stripping comments and whitespace)
- 15159 / 15616 compressed characters (97% of compressed size, after stripping comments and whitespace)

Token usage, sorted by code organization section (out of the 8163 tokens / *15159 compressed chars*)
If there are two numbers (a / *b*), a is token usage and b is compressed char usage-- only listed for large contributors
-  1159 / *2066*: 6) main UI draw loops and card draw functions
-  1073 / *2041*: 4b) player action loop (some of this is also in enemy action loop)
-  865 / *1496*: 9) miscellaneous helper functions
-  790 / *1674*: 4a) enemy action loop (includes some common functions used in 4b)
-  628 / *3538*: 11) inits and databases (substantial strings of data)
-  580 / *1596*: 3) pre-combat states (new turn, choose cards, etc)
-  517 / *1368*: 5) post-combat states (cleanup, etc)
-  377: 7) custom sprite-based font and print functions
-  359: 14) levelup, upgrades
-  355 / *1283*: 15) town and retirement
-  275: 18) load/save
-  271: 17) pathfinding (A*)
-  211 / / *646*: 1) core game init/update/draw
-  200: 8) menu-draw and related functions
-  129: 10) data string -> datastructure parsing + loading
-  117: 12) profile / character sheet
-  102 / ?: 4) action/combat loop
-  99: 13) splash screen / intro
-  56 / ?: 2) main game state machine
-  0 : x) pause menu items (deprecated)
-  0: 16) debugging + testing functions
