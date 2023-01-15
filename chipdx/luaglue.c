#include "luaglue.h"
//and all the chipmunk headers!

#ifndef CP_USE_DOUBLES
	// double-precision is very slow on Playdate and not needed for the scales we'll use
	#define CP_USE_DOUBLES 0
#endif

static PlaydateAPI* pd = NULL;

void registerChipmunk(PlaydateAPI* playdate)
{
    pd = playdate;
    const char* err;

    pd->system->logToConsole("in registerChipmunk\n");

    //a whole bunch of pd->lua->registerClass() for each Chipmunk class. The fun part.
}
