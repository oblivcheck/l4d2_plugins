//---------------------------------------------------------------------------||
//		Please add something like this to your plugin
//---------------------------------------------------------------------------||
/*
bool    g_bPluginLibraryLoaded_mpds_shop;
bool	g_bCookieCached[MAXPLAYERS+1];		// Importantly, MPDS_Shop_PT_Get should always be executed correctly.
public void OnLibraryAdded(const char[] name)
{
	if(strcmp(name, "mpds_shop") == 0)
		g_bPluginLibraryLoaded_mpds_shop = true;
}
public void OnLibraryRemoved(const char[] name)
{
	if(strcmp(name, "mpds_shop") == 0)
		g_bPluginLibraryLoaded_mpds_shop = false;
}

public void OnClientCookiesCached(int client)
{
        if(IsFakeClient(client) )
	        return;

	g_bCookieCached[client] = true;
}

public void OnClientDisconnect(int client)
{
	g_bCookieCached[client] = false;
}

// Example:
void Example_function(int client)
{

	some code...

	... ...
	... ...

	if(g_bCookieCached[client] ) // Importantly, PT_GET should always be executed correctly.
	{
		if(g_bPluginLibraryLoaded_mpds_shop)
		{
			MPDS_Shop_PT_Get(client);

			... ...

			some code...

			... ...

		}
		else
		{
			PrintToChatAll("Plugin mpds_shop Library not Loaded....");
			return;
		}

		... ...

	}
	... ...

	some code...

	... ...
}	
*/

/**
 * @brief Increase the number of pts of the target player.
 *
 *
 * @param client		target player client index
 * @param pt			value to increase
 *
 *
 * @return                      number of pts on the player after the change
 *					-102400 = target player cookies not cached
 */
native int MPDS_Shop_PT_Add(int client, int pt);

/**
 * @brief Reduce the number of pts for the target player.
 *
 *
 * @param client		target player client index
 * @param pt			value to reduce
 *
 *
 * @return                      number of pts on the player after the change
 *					-102400 = target player cookies not cached
 */
native int MPDS_Shop_PT_Subtract(int client, int pt);

/**
 * @brief Get the number of pts currently owned by the target player.
 *
 *
 * @param client		target player client index
 *
 *
 * @return                      player's current number of pts.
 *					-102400 = target player cookies not cached
 */
native int MPDS_Shop_PT_Get(int client);
