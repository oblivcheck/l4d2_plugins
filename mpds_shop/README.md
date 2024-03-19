# MPDS Shop

## Require
```
#include <multicolors>
#include <left4dhooks>
#include <mpds_shop>
```
**Install plugin:**

[l4d2_fireworks](https://forums.alliedmods.net/showthread.php?p=1441088)

[l4dinfectedbots v2.8.8fork](https://github.com/oblivcheck/l4d2_plugins/blob/master/l4dinfectedbots)

## About
* Previously a private plugin on the server.

* Earlier versions were based on [hp_rewards](https://forums.alliedmods.net/showthread.php?p=2411161) (version 2.2)

## Changes Log
~~~
2024-02-03 (REV 1.0.3 Beta)
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

      - Many known issues exist, and we should utilize the latest version of 'l4dinfectedbots' and re-implement this functionality.

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
  - Modify some comments
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

~~~

## Settings
**No Cvars.**

**Client command**
~~~
sm_buy
  - open server shop menu.
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
~~~

// 游戏默认的生命值上限，用于逻辑判断
#define MAX_HEALTH_DEF    100
// 永久生命值的上限，临时生命值没有特别设置，这意味着最大总生命值应该是200?
//   默认游戏设置下，过多的临时生命值，将导致倒地时的生命值接近400？只是猜测
#define MAX_HP      150

// 帮助队友获得的奖励：pt与永久生命值
#define DEFIB_REWARD    40
#define DEFIB_REWARD_PT   20
#define HEAL_REWARD   20
#define HEAL_REWARD_PT    5
#define REVIVE_REWARD   20
#define REVIVE_REWARD_PT  5
// 如果玩家挂边，获取他当前倒地生命值的Tick间隔
#define HANGING_CHECK_INTERVAL  45
// 挂边时，被救助的玩家生命值低于这个值会被认为是需要紧急救助的
#define REVIVE_HP_REWARD  100
// 如果被救助的玩家是挂边状态，但并不被认为是需要紧急救助，那么玩家应该恢复的生命值将被下面的值覆盖
#define REVIVE_FAST_REWARD  10

// 扫描存活TANK的时间间隔(秒)
#define TANK_ALIVE_TIMER_INTERVAL 5.0
// 玩家单独击杀了Tank，并且仅使用近战武器，奖励的PT
#define TANK_SOLO_MELEE_REWARD    1000
// 击杀TANK奖励PT
#define TANK_REWARD     5
// 仅使用近战击杀TANK额外的奖励PT
#define TANK_ONLY_MELEE_REWARD    50
// TANK发现幸存者后，存活时间>=TANK_ALIVE_TIMER_COUNT*TANK_ALIVE_TIMER_INTERVAL
//   后开始在次扫描中扣除幸存者的PT
#define TANK_ALIVE_TIMER_COUNT    24
// 每一次扣除的数量
#define TANK_ALIVE_DEDUCT_PT    2

// 击杀特殊感染者恢复的临时生命值，
//   在玩家当前总生命值没有超过MAX_HEALTH_DEF的情况下，
//     这不会让生命值高于MAX_HEALTH_DEF
#define BOOMER_REWARD   6.0
#define SPITTER_REWARD    6.0
#define SMOKER_REWARD   10.0
#define JOCKEY_REWARD   10.0
#define HUNTER_REWARD   12.0
#define CHARGER_REWARD    16.0

/***商店物品的详细属性在 CacheShopItem() 中进行设置***/
// 允许抽奖的次数，如果被限制了；如果玩家的pt点数在花费LDW_PRICE之后将为负数，则启用限制
//   限制会在高于(LDW_PRICE-1)时被重置，地图结束时也将重置
//     目前的版本下，所有物品的库存也将在地图结束时重置
#define LDW_LIMIT   2
// 抽奖需要花费的点数
#define LDW_PRICE   6

// 如果是写实模式，!buy中每一项物品的价格乘以这个值
#define REALISM_MODE_SPENT_MULT 2.5

// 是否允许使用除颤器
// 对于MPDS服务器，它可能会导致崩溃
#define ALLOW_USE_DEFIB   0

// 未完成...
// 商店的库存剩余是团队共享还是特定玩家计算
#define SHOP_STOCK_SHARE  0
// 团队共享库存时，项目实际库存=项目设置*SHOP_STOCK_SHARE_MULIT
#define SHOP_STOCK_SHARE_MULIT  2

~~~
