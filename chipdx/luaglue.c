#include <math.h>
#include "luaglue.h"
#include "chipmunk.h"

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

//chipmunk_types.h?
//cpSpace
//cpShape
// cpCircleShapeNew
// cpBoxShapeNew
// cpMomentForCircle
// cpMomentForBox
//cpBody
//cpConstraint?

