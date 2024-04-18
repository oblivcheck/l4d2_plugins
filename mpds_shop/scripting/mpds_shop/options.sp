// 游戏默认的生命值上限，用于逻辑判断
#define	MAX_HEALTH_DEF		100
// 永久生命值的上限，临时生命值没有特别设置，这意味着最大总生命值应该是200? 
//   默认游戏设置下，过多的临时生命值，将导致倒地时的生命值接近400？只是猜测
#define	MAX_HP			150

// 帮助队友获得的奖励：pt与永久生命值
#define	DEFIB_REWARD		40
#define	DEFIB_REWARD_PT		40
#define	HEAL_REWARD		20
#define	HEAL_REWARD_PT		20
#define	REVIVE_REWARD		20
#define REVIVE_REWARD_PT	20
// 如果玩家挂边，获取他当前倒地生命值的Tick间隔
#define	HANGING_CHECK_INTERVAL	45
// 挂边时，被救助的玩家生命值低于这个值会被认为是需要紧急救助的
#define	REVIVE_HP_REWARD	100
// 如果被救助的玩家是挂边状态，但并不被认为是需要紧急救助，那么玩家应该恢复的生命值将被下面的值覆盖
#define	REVIVE_FAST_REWARD	10

// Tank是否影响点数变化，包括相关奖励与超时击杀惩罚
#define TANK_REWARD_ENABLE    0
// 扫描存活TANK的时间间隔(秒)
#define	TANK_ALIVE_TIMER_INTERVAL	5.0
// 启用Tank特殊击杀奖励(单独/近战)
#define Tank_SpecialKilled    0
// 玩家单独击杀了Tank，并且仅使用近战武器，奖励的PT
#define	TANK_SOLO_MELEE_REWARD		1000
// 击杀TANK奖励PT
#define	TANK_REWARD			0
// 仅使用近战击杀TANK额外的奖励PT
#define	TANK_ONLY_MELEE_REWARD		50
// TANK发现幸存者后，存活时间>=TANK_ALIVE_TIMER_COUNT*TANK_ALIVE_TIMER_INTERVAL
//   后开始在每一次扫描中扣除幸存者的PT
#define	TANK_ALIVE_TIMER_COUNT		24
// 每一次扣除的数量
#define	TANK_ALIVE_DEDUCT_PT		0

// 击杀特殊感染者恢复的临时生命值，
//   在玩家当前总生命值没有超过MAX_HEALTH_DEF的情况下，
//     这不会让生命值高于MAX_HEALTH_DEF
#define	BOOMER_REWARD		6.0
#define	SPITTER_REWARD		6.0
#define	SMOKER_REWARD		10.0
#define	JOCKEY_REWARD		10.0
#define	HUNTER_REWARD		12.0
#define	CHARGER_REWARD		16.0

// 若击杀特感获得的PT奖励的低于或等于该值，将不会在聊天框输出“获得了xxpt”消息
#define SI_REWARD_PT_ENABLE   0
// 击杀特感的PT奖励
#define	BOOMER_REWARD_PT		1
#define	SPITTER_REWARD_PT		1
#define	SMOKER_REWARD_PT		1
#define	JOCKEY_REWARD_PT		2
#define	HUNTER_REWARD_PT		2
#define	CHARGER_REWARD_PT		2


/***商店物品的详细属性在 "mpds_shop/items.sp" 的 “CacheShopItem()” 中进行设置***/
// 允许抽奖的次数，如果被限制了；如果玩家的pt点数在花费LDW_PRICE之后将为负数，则启用限制
//   限制会在高于(LDW_PRICE-1)时被重置，地图结束时也将重置
//     目前的版本下，所有物品的库存也将在地图结束时重置
#define	LDW_LIMIT		2
// 抽奖需要花费的点数
#define LDW_PRICE		6

// 如果是写实模式，!buy中每一项物品的价格乘以这个值
#define	REALISM_MODE_SPENT_MULT	2.5

// 是否允许使用除颤器
// 对于MPDS服务器，它可能会导致崩溃
#define	ALLOW_USE_DEFIB		0

// 未完成...
// 商店的库存剩余是团队共享还是特定玩家计算
#define SHOP_STOCK_SHARE 	0
// 团队共享库存时，项目实际库存=项目设置*SHOP_STOCK_SHARE_MULIT
#define	SHOP_STOCK_SHARE_MULIT	2

// 通过E+R快捷键打开商店后，此操作的锁定时间
#define OPENSHOPLOCKTIME   0.5

// 单个地图中加入的玩家总数不应该超过下面的值
// 存储玩家STEAMID的索引数量，防止通过重新加入服务器的方式刷新商店物品库存
#define SingleMapMaxPlayers 128
