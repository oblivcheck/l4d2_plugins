#define REASON_TYPE_HELP        1 << 0    // 因为帮助队友而获得奖励
#define REASON_TYPE_SI          1 << 1    // 因为击杀特殊感染者而获得奖励

#define REASON_HELP_DEFIB               1 << 0    // 除颤队友
#define REASON_HELP_HEAL                1 << 1    // 治疗濒死的队友
#define REASON_HELP_REVIVE              1 << 2    // 帮助倒地的队友
#define REASON_HELP_HANGING             1 << 3    // 帮助挂边的队友
#define REASON_HELP_HANGING_EMER        1 << 4    // 帮助挂边的队友（队友低生命值）


/**
 * @brief change the target player's pts.
 *
 *
 * @param client		target player client index
 *
 * @param sPt       value to change, 
 *                       unsigned string is invalid,
 *                          "+16" = increased 16, "-16" = reduced 16.
 *
 * @return                      1 = success, 0 = client cookie not cached or invalid string "sPt".
 *
 */
native int MPDS_Shop_PT_Change(int client, char[] sPt);

/**
 * @brief get the target player's pts.
 *
 *
 * @param client		target player client index
 *
 * @param sPt       buffer to store the client's pts.
 *                      if client cookie not cached, string will be "COOKIENOTCACHED".
 *
 * @param maxlen		maximum length of string buffer (includes NULL terminator).
 *                      recommended buffer size is 16, excess will be truncated.
 *                          "16" is the value used internally by the plugin.
 *
 * @return                      1 = success, 0 = client cookie not Cached.
 *
 */
native int MPDS_Shop_PT_Get(int client, char[] sPt, int maxlen);

/**
 * @brief Call when a player receive HP reward.
 *
 * @param client    Get reward client index
 *
 * @param bRealhp   Reward HP Type
 *
 * @param targethp  Total health on the client side after receiving health rewards.
 *                    Note: This only calculates a single type,
 *                      type depends on bRealhp.
 *
 * @param type      Type of reward.   See "include/mpds_shop.inc"
 *
 * @param reason    The specific meaning depends on the type.
 *                    type == REASON_TYPE_HELP, 
 *                      this is the reason for receiving the reward, 
 *                      see "REASON_HELP_*".
 *                    type == REASON_TYPE_SI, this is the type of 
 *                      Special Infected 
 *                      that the client has killed (Zombie Class).
 *
 * @param 
 *    bRefThirdStrike   
 *                  Indicates whether to reset the client's Incap counter.
 *
 * @param bLimit    Indicates whether to adhere to internal limits 
 *                    defined within the plugin (MAXHP and MAX_HEALTH_DEF).
 *                  Note: Defined specific values can be found in "mpds_shop/options.sp",
 *                    If not restricted, it is completely ignored.
 *
 * @param bMsg      Indicates whether the plugin is allowed to print 
 *                    reward messages in the chat.
 *                  Note: This only affects messages directly related to HP rewards
 *                    If a reward is disadvantageous or illogical to players, 
 *                      it's best to always specify this as false.
 *
 * @param target    Client index of the player being helped 
 *                    or the Special Infected being killed, 
 *                      depending on the type.
 *
 * @return          Plugin_Changed, if any value has been modified,
 *                    Plugin_Handled, prevent the reward.
 *
 */
forward Action MSS_OnReceivingRewards(int client, bool &bRealhp, 
  float &targethp, int &type, int &reason, bool &bRefThirdStrike, 
  bool &bLimit, bool &bMsg, int target)
