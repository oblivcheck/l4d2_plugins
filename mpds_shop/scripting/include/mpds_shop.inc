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
