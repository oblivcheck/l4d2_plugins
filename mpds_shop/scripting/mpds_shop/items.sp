// 商店物品的最大数量目前是硬编码的，需要调整下面的定义
// "mpds_shopdefine.sp": #define SHOP_ITEM_NUM 64
#define	MAXSHOPTYPE	7
// 特定类别商店的第一个项目的绝对索引
int g_iShopArrayIndexOffest[MAXSHOPTYPE]={0, -1, -1, ...};

// MethodMap... 也许以后
ArrayList SubShop_ItemDisplayName;
ArrayList SubShop_ItemName;
ArrayList SubShop_ItemPrice;
ArrayList SubShop_ItemInventory;
ArrayList SubShop_ItemWeaponAmmoMult;

void CacheShopItem()
{
	// 对于随机的物品，只关注显示名称与价格
	// 后三个值重置的默认值为-1
	// 确保始终Push每一个项目的显示名称，它被用于计算项目的总数
	SubShop_ItemDisplayName = CreateArray(32);
	SubShop_ItemName = CreateArray(32);
	// free = 免费的物品
  // lock = 锁定的物品
  // x+y = 依据玩家当前的pt数量来实时计算价格，基础值x+百分比计算y=最终价格
	// 价格
	SubShop_ItemPrice = CreateArray(32);
	// -2 = 无限
	// 这个物品当前章节对于玩家的可购买次数
	SubShop_ItemInventory = CreateArray(1);
	// -2 = 参数是无效的
	// 武器的备用弹药=武器的默认弹匣大小*设置的值
	SubShop_ItemWeaponAmmoMult = CreateArray(1);

	SubShop_ItemDisplayName.PushString("随机的物品");
	SubShop_ItemName.PushString("");	
	SubShop_ItemPrice.PushString("lock");
	SubShop_ItemInventory.Push(4);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("泵动式霰弹枪");
	SubShop_ItemName.PushString("weapon_pumpshotgun");	
	SubShop_ItemPrice.PushString("free");
	SubShop_ItemInventory.Push(4);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("铬制霰弹枪");
	SubShop_ItemName.PushString("weapon_shotgun_chrome");	
	SubShop_ItemPrice.PushString("free");
	SubShop_ItemInventory.Push(4);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("微型冲锋枪");
	SubShop_ItemName.PushString("weapon_smg");	
	SubShop_ItemPrice.PushString("free");
	SubShop_ItemInventory.Push(4);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("消音冲锋枪");
	SubShop_ItemName.PushString("weapon_smg_silenced");	
	SubShop_ItemPrice.PushString("free");
	SubShop_ItemInventory.Push(4);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("Mp5冲锋枪");
	SubShop_ItemName.PushString("weapon_smg_mp5");	
	SubShop_ItemPrice.PushString("free");
	SubShop_ItemInventory.Push(4);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("手枪");
	SubShop_ItemName.PushString("weapon_pistol");	
	SubShop_ItemPrice.PushString("free");
	SubShop_ItemInventory.Push(4);
	SubShop_ItemWeaponAmmoMult.Push(-2);

  SubShop_ItemDisplayName.PushString("");
	SubShop_ItemName.PushString("_MSS_ShopSplit");	
	SubShop_ItemPrice.PushString("");
	SubShop_ItemInventory.Push(-1);
	SubShop_ItemWeaponAmmoMult.Push(-1);

	// 二级商店
	SubShop_ItemDisplayName.PushString("随机的物品");
	SubShop_ItemName.PushString("");	
	SubShop_ItemPrice.PushString("20+0.2");
	SubShop_ItemInventory.Push(-2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("M16步枪");
	SubShop_ItemName.PushString("weapon_rifle");
	SubShop_ItemPrice.PushString("12+0.1");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(18);

	SubShop_ItemDisplayName.PushString("Ak47步枪");
	SubShop_ItemName.PushString("weapon_rifle_ak47");	
	SubShop_ItemPrice.PushString("16+0.1");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(18);

	SubShop_ItemDisplayName.PushString("军用步枪");
	SubShop_ItemName.PushString("weapon_rifle_desert");	
	SubShop_ItemPrice.PushString("14+0.1");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("Sg552步枪");
	SubShop_ItemName.PushString("weapon_rifle_sg552");	
	SubShop_ItemPrice.PushString("12+0.1");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(18);

	SubShop_ItemDisplayName.PushString("自动霰弹枪");
	SubShop_ItemName.PushString("weapon_autoshotgun");	
	SubShop_ItemPrice.PushString("16+0.1");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("战斗霰弹枪");
	SubShop_ItemName.PushString("weapon_shotgun_spas");	
	SubShop_ItemPrice.PushString("16+0.1");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("狩猎步枪");
	SubShop_ItemName.PushString("weapon_hunting_rifle");	
	SubShop_ItemPrice.PushString("5+0.1");
	SubShop_ItemInventory.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(18);

	SubShop_ItemDisplayName.PushString("军用狙击步枪");
	SubShop_ItemName.PushString("weapon_sniper_military");	
	SubShop_ItemPrice.PushString("14+0.1");
	SubShop_ItemInventory.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(18);

	SubShop_ItemDisplayName.PushString("侦察狙击步枪");
	SubShop_ItemName.PushString("weapon_sniper_scout");	
	SubShop_ItemPrice.PushString("2+0.1");
	SubShop_ItemInventory.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(27);

	SubShop_ItemDisplayName.PushString("Awp狙击步枪");
	SubShop_ItemName.PushString("weapon_sniper_awp");	
	SubShop_ItemPrice.PushString("5+0.1");
	SubShop_ItemInventory.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(18);

	SubShop_ItemDisplayName.PushString("Magnum手枪");
	SubShop_ItemName.PushString("weapon_pistol_magnum");	
	SubShop_ItemPrice.PushString("10+0.1");
	SubShop_ItemInventory.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

  SubShop_ItemDisplayName.PushString("");
	SubShop_ItemName.PushString("_MSS_ShopSplit");	
	SubShop_ItemPrice.PushString("");
	SubShop_ItemInventory.Push(-1);
	SubShop_ItemWeaponAmmoMult.Push(-1);


	// 三级商店
	SubShop_ItemDisplayName.PushString("随机的物品");
	SubShop_ItemName.PushString("");	
	SubShop_ItemPrice.PushString("80+0.25");
	SubShop_ItemInventory.Push(-2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("M60轻机枪");
	SubShop_ItemName.PushString("weapon_rifle_m60");	
	SubShop_ItemPrice.PushString("20+0.2");
	SubShop_ItemInventory.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("榴弹发射器");
	SubShop_ItemName.PushString("weapon_grenade_launcher");	
	SubShop_ItemPrice.PushString("20+0.2");
	SubShop_ItemInventory.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(12);

	SubShop_ItemDisplayName.PushString("电锯");
	SubShop_ItemName.PushString("weapon_chainsaw");	
	SubShop_ItemPrice.PushString("30+0.2");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

  SubShop_ItemDisplayName.PushString("");
	SubShop_ItemName.PushString("_MSS_ShopSplit");	
	SubShop_ItemPrice.PushString("");
	SubShop_ItemInventory.Push(-1);
	SubShop_ItemWeaponAmmoMult.Push(-1);

	// 近战武器
	SubShop_ItemDisplayName.PushString("随机的物品");
	SubShop_ItemName.PushString("");
	SubShop_ItemPrice.PushString("40+0.2");
	SubShop_ItemInventory.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("干草叉");
	SubShop_ItemName.PushString("weapon_melee+pitchfork");	
	SubShop_ItemPrice.PushString("free");
	SubShop_ItemInventory.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("消防斧");
	SubShop_ItemName.PushString("weapon_melee+fireaxe");	
	SubShop_ItemPrice.PushString("20+0.15");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("平底锅");
	SubShop_ItemName.PushString("weapon_melee+frying_pan");	
	SubShop_ItemPrice.PushString("10+0.1");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("砍刀");
	SubShop_ItemName.PushString("weapon_melee+machete");	
	SubShop_ItemPrice.PushString("20+0.15");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("棒球棍");
	SubShop_ItemName.PushString("weapon_melee+baseball_bat");	
	SubShop_ItemPrice.PushString("10+0.1");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("撬棍");
	SubShop_ItemName.PushString("weapon_melee+crowbar");	
	SubShop_ItemPrice.PushString("10+0.1");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("板球棒");
	SubShop_ItemName.PushString("weapon_melee+cricket_bat");	
	SubShop_ItemPrice.PushString("10+0.1");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("警棍");
	SubShop_ItemName.PushString("weapon_melee+tonfa");	
	SubShop_ItemPrice.PushString("15+0.12");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("武士刀");
	SubShop_ItemName.PushString("weapon_melee+katana");	
	SubShop_ItemPrice.PushString("15+0.12");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("电吉他");
	SubShop_ItemName.PushString("weapon_melee+electric_guitar");	
	SubShop_ItemPrice.PushString("15+0.12");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("小刀");
	SubShop_ItemName.PushString("weapon_melee+knife");	
	SubShop_ItemPrice.PushString("15+0.12");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("高尔夫球杆");
	SubShop_ItemName.PushString("weapon_melee+golfclub");	
	SubShop_ItemPrice.PushString("10+0.1");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("铁铲");
	SubShop_ItemName.PushString("weapon_melee+shovel");	
	SubShop_ItemPrice.PushString("15+0.1");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

  SubShop_ItemDisplayName.PushString("");
	SubShop_ItemName.PushString("_MSS_ShopSplit");	
	SubShop_ItemPrice.PushString("");
	SubShop_ItemInventory.Push(-1);
	SubShop_ItemWeaponAmmoMult.Push(-1);

  // 医疗物品
	SubShop_ItemDisplayName.PushString("随机的物品");
	SubShop_ItemName.PushString("");	
	SubShop_ItemPrice.PushString("20+0.2");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

#if ALLOW_USE_DEFIB
		SubShop_ItemDisplayName.PushString("除颤器");
		SubShop_ItemName.PushString("weapon_defibrillator");	
		SubShop_ItemPrice.PushString("10");
		SubShop_ItemInventory.Push(4);
		SubShop_ItemWeaponAmmoMult.Push(-2);
#endif
#if !ALLOW_USE_DEFIB
		SubShop_ItemDisplayName.PushString("除颤器-禁用");
		SubShop_ItemName.PushString("weapon_defibrillator");	
		SubShop_ItemPrice.PushString("lock");
		SubShop_ItemInventory.Push(4);
		SubShop_ItemWeaponAmmoMult.Push(-2);
#endif

	SubShop_ItemDisplayName.PushString("医疗包");
	SubShop_ItemName.PushString("weapon_first_aid_kit");	
	SubShop_ItemPrice.PushString("30");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("止痛药");
	SubShop_ItemName.PushString("weapon_pain_pills");	
	SubShop_ItemPrice.PushString("8");
	SubShop_ItemInventory.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("肾上腺素");
	SubShop_ItemName.PushString("weapon_adrenaline");	
	SubShop_ItemPrice.PushString("6");
	SubShop_ItemInventory.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

  SubShop_ItemDisplayName.PushString("");
	SubShop_ItemName.PushString("_MSS_ShopSplit");	
	SubShop_ItemPrice.PushString("");
	SubShop_ItemInventory.Push(-1);
	SubShop_ItemWeaponAmmoMult.Push(-1);

  // 其他物品
	SubShop_ItemDisplayName.PushString("随机的物品");
	SubShop_ItemName.PushString("");	
	SubShop_ItemPrice.PushString("10+0.1");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("燃烧瓶");
	SubShop_ItemName.PushString("weapon_molotov");	
	SubShop_ItemPrice.PushString("12");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("土质炸弹");
	SubShop_ItemName.PushString("weapon_pipe_bomb");	
	SubShop_ItemPrice.PushString("10");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("胆汁罐");
	SubShop_ItemName.PushString("weapon_vomitjar");	
	SubShop_ItemPrice.PushString("12");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("丙烷罐");
	SubShop_ItemName.PushString("weapon_propanetank");	
	SubShop_ItemPrice.PushString("2");
	SubShop_ItemInventory.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("氧气瓶");
	SubShop_ItemName.PushString("weapon_oxygentank");	
	SubShop_ItemPrice.PushString("1");
	SubShop_ItemInventory.Push(4);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("侏儒玩偶");
	SubShop_ItemName.PushString("weapon_gnome");	
	SubShop_ItemPrice.PushString("free");
	SubShop_ItemInventory.Push(8);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("高爆弹升级包");
	SubShop_ItemName.PushString("weapon_upgradepack_explosive");	
	SubShop_ItemPrice.PushString("16");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("燃烧弹升级包");
	SubShop_ItemName.PushString("weapon_upgradepack_incendiary");	
	SubShop_ItemPrice.PushString("12");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("汽油桶-待定");
	SubShop_ItemName.PushString("");	
	SubShop_ItemPrice.PushString("lock");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("烟花盒-待定");
	SubShop_ItemName.PushString("");	
	SubShop_ItemPrice.PushString("lock");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

  SubShop_ItemDisplayName.PushString("");
	SubShop_ItemName.PushString("_MSS_ShopSplit");	
	SubShop_ItemPrice.PushString("");
	SubShop_ItemInventory.Push(-1);
	SubShop_ItemWeaponAmmoMult.Push(-1);

	// 特殊效果
	SubShop_ItemDisplayName.PushString("--占位符--");
	SubShop_ItemName.PushString("");	
	SubShop_ItemPrice.PushString("lock");
	SubShop_ItemInventory.Push(0);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("烟花发射！");
	SubShop_ItemName.PushString("cmd+sm_fireworks");	
	SubShop_ItemPrice.PushString("free");
	SubShop_ItemInventory.Push(8);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("生成并控制一只Tank");
	SubShop_ItemName.PushString("other_spawntk");	
  // 45+0.15
	SubShop_ItemPrice.PushString("lock");
	SubShop_ItemInventory.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("自杀并复活(重生)-待定");
	SubShop_ItemName.PushString("other+");	
	SubShop_ItemPrice.PushString("lock");
	SubShop_ItemInventory.Push(0);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("自我救助(自救)-待定");
	SubShop_ItemName.PushString("other+");	
	SubShop_ItemPrice.PushString("lock");
	SubShop_ItemInventory.Push(0);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("快速购买-待定");
	SubShop_ItemName.PushString("other+");	
	SubShop_ItemPrice.PushString("lock");
	SubShop_ItemInventory.Push(-2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("升级镭射装置-待定");
	SubShop_ItemName.PushString("");	
	SubShop_ItemPrice.PushString("lock");
	SubShop_ItemInventory.Push(0);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("放置镭射升级盒-待定");
	SubShop_ItemName.PushString("");	
	SubShop_ItemPrice.PushString("lock");
	SubShop_ItemInventory.Push(0);
	SubShop_ItemWeaponAmmoMult.Push(-2);
}
