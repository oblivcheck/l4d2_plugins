# MPDS Shop

## Require
```
#include <multicolors>
#include <left4dhooks>

#include "mpds_shop/define.sp"
#include "mpds_shop/options.sp"
#include "mpds_shop/items.sp"
#include "mpds_shop/fuc.sp"
#include "mpds_shop/inc.sp"
#include "mpds_shop/special_items.sp"
```
## Developers

[mpds.inc](https://github.com/oblivcheck/l4d2_plugins/blob/master/mpds_shop/scripting/mpds_shop/include/mpds.inc)

[inc.sp](https://github.com/oblivcheck/l4d2_plugins/blob/master/mpds_shop/scripting/mpds_shop/inc.sp)

**Installed plugin:**

[l4d2_fireworks](https://forums.alliedmods.net/showthread.php?p=1441088)

[l4dinfectedbots v2.8.8fork](https://github.com/oblivcheck/l4d2_plugins/blob/master/l4dinfectedbots)

## About
* Previously a private plugin on the server.

* Earlier versions were based on [hp_rewards](https://forums.alliedmods.net/showthread.php?p=2411161) (version 2.2)

## Changes Log
~~~
2024-03-25 (REV 1.1.1)
  - Organize the code.

2024-03-23 (REV 1.1.0)
  - Organize the code.
  - Add more plugin options.
  - Menu can now be quickly opened by simultaneously pressing the +USE and RELOAD buttons(game def = E+R).
  - Fixed: "inconsistent indentation" compile warning.
  - Item prices can now be dynamic.
  - Modify Plugin Native.
    - Will fill a string instead of returning an integer value.

2024-03-20 (REV 1.0.3 Beta)
  - Fixed: command "!ldw" occasionally fail to kill player.
  - Fixed: players can rejoin the server to refresh store item inventory.
  - Allow dynamic setting of item prices
      - Imperfect functionality.
  - Updated chat messages && Changed some plugin options.
    - Latest version on my server.
  - Add shop special items
    * Launch firework.
      - Required plugin: [l4d2_fireworks]
        - (https://forums.alliedmods.net/showthread.php?p=1441088)
    * Spawn and control a Tank.
      - Required plugin: [l4dinfectedbots]
        - Need to use my fork (based v2.8.8)
        - (https://github.com/oblivcheck/l4d2_plugins/blob/master/l4dinfectedbots)
    * Many known issues exist, and we should utilize the latest version of 'l4dinfectedbots' and re-implement this functionality.
  -  Code adjustments
    - (i < MaxClients) -> (i <= MaxClients)

2024-02-03 (REV 1.0.2 Not Release)
  - Command "!buy"
    - Rmove chat info “testing"
  - Command "ldw"
    - now has a chance to kill the player.

2024-01-31 (REV 1.0.1)
  - Fixed：For special infected, kills without reward will still send msg to the player.
  - Fixed："SHOP_STOCK_SHARE" compile warning.
  - Modify some comments.

2024-01-30 (REV 1.0.0)
  - Modify some comments.
  - Command "sm_hreset" is no longer executed when the plugin start.
  - Set HL2 random stream when executing function LDW()
  - Fixed: Item price display error in realism mode.
  - Add some new macro definitions to modify the plugin settings.
  - Add item stock type display to sub-shop menu title.
    - Unfinished feature.

2024-01-29 (REV 1.0.0 Beta 2)
  - Add some macro definitions to modify the plugin settings.
  - Organize the code.

2024-01-29 (REV 1.0.0 Beta)
  - Initial version.

* Earlier versions were based on hp_rewards(https://forums.alliedmods.net/showthread.php?p=2411161)
  * version 2.2

* My own final version: 1.2.2 (fork by 2.2)
  * 1.2.2 (fork by 2.2) -> REV 1.0.0 Beta

~~~

## Settings
**Cvars**

Noting.

**Client command**
~~~
sm_buy
  - open server shop menu.
    - or via press USE+RELOAD(E+R),
  - Note: if client index = 0 (execute via rcon or server console), 
	[sm_buy]: Print the num of pts owned by all valid clients on the server.
	[sm_buy userid value]  Increase the num of pts for the specified client.
sm_ldw
  - lottery.
~~~

**Admin command**
~~~
sm_hreset
  - Set the CookieCachde flag for all clients to true.
  - Reset shop item stock.
  - Note: if you want to reload the plugin on the fly, you need to execute this command once after the loading is complete.
~~~

**Macro definition**

[options.sp](https://github.com/oblivcheck/l4d2_plugins/blob/master/mpds_shop/scripting/mpds_shop/options.sp)

**Shop Items**

[items.sp](https://github.com/oblivcheck/l4d2_plugins/blob/master/mpds_shop/scripting/mpds_shop/items.sp)

[special_items.sp](https://github.com/oblivcheck/l4d2_plugins/blob/master/mpds_shop/scripting/mpds_shop/special_items.sp)
