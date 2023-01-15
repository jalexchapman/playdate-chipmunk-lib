#include <stdio.h>
#include <stdlib.h>

#include "pd_api.h"
#include "luaglue.h"

#ifdef _WINDLL
__declspec(dllexport)
#endif
int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg)
{
	if ( event == kEventInitLua )
    {
		playdate->system->logToConsole("in kEventInitLua\n");
        registerChipmunk(playdate);
    }
	return 0;
}
