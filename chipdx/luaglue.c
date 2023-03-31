/*
* Adapted from https://github.com/mierau/playbox2d and the Playdate mini3d sdk sample
*/

#include <math.h>
#include "luaglue.h"
#include "../chipmunk/include/chipmunk/chipmunk.h"

#ifndef CP_USE_DOUBLES
	// double-precision is very slow on Playdate and not needed for the scales we'll use
	#define CP_USE_DOUBLES 0
#endif

static PlaydateAPI* pd = NULL;

#define CLASSNAME_SPACE "chipmunk.space"
#define CLASSNAME_BODY "chipmunk.body"
#define CLASSNAME_SHAPE "chipmunk.shape"
// #define CLASSNAME_CONSTRAINT "chipmunk.constraint"


// UTILITY
static cpSpace* getSpaceArg(int n) { return pd->lua->getArgObject(n, CLASSNAME_SPACE, NULL); }
static cpBody* getBodyArg(int n) { return pd->lua->getArgObject(n, CLASSNAME_BODY, NULL); }
static cpShape* getShapeArg(int n) { return pd->lua->getArgObject(n, CLASSNAME_SHAPE, NULL); }
// static cpConstraint* getConstraintArg(int n) { return pd->lua->getArgObject(n, CLASSNAME_CONSTRAINT, NULL); }


//cpSpace
int chipmunk_space_new(lua_State* L){
    cpSpace* space = cpSpaceNew();
    pd->lua->pushObject(space, CLASSNAME_SPACE, 0);
    return 1;
}

int chipmunk_space_delete(lua_State* L){
    cpSpaceFree(getSpaceArg(1));
    return 0;
    //TODO: make sure we don't have to delete contents first
}

int chipmunk_space_step(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    float dt = pd->lua->getArgFloat(2);
    cpSpaceStep(space, dt);
    return 0;
}

int chipmunk_space_getGravity(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    cpVect gravity = cpSpaceGetGravity(space);
    pd->lua->pushFloat((float) gravity.x);
    pd->lua->pushFloat((float) gravity.y);

    return 2;
}

int chipmunk_space_setGravity(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    float gravity_x = pd->lua->getArgFloat(2);
    float gravity_y = pd->lua->getArgFloat(3);
    cpSpaceSetGravity(space, cpv(gravity_x, gravity_y));
    return 0;
}

static const lua_reg spaceClass[] = {
    {"new", chipmunk_space_new },
    {"__gc", chipmunk_space_delete},
//properties
    {"getGravity", chipmunk_space_getGravity},
    {"setGravity", chipmunk_space_setGravity},
//other get/set: 
//iterations
//damping
// idleSpeedThreshold
// sleepTimeThreshold
// collisionSlop
// collisionBias
// collisionPersistence
// userData
//get only:
// currentTimeStep
// isLocked
// staticBody
//methods
    {"step", chipmunk_space_step},
    // {"addShape", chipmunk_space_addShape},
    // {"addBody", chipmunk_space_addBody},
    // {"addConstraint", chipmunk_space_addConstraint},
    // {"removeShape", chipmunk_space_removeShape},
    // {"removeBody", chipmunk_space_removeBody},
    // {"removeConstraint", chipmunk_space_removeConstraint},
    {NULL, NULL}
};

void registerChipmunk(PlaydateAPI* playdate)
{
    pd = playdate;
    const char* err;

    pd->system->logToConsole("in registerChipmunk\n");

    if (!pd->lua->registerClass(CLASSNAME_SPACE, spaceClass, NULL, 0, &err)) {
        pd->system->logToConsole("chipmunk: failed to register space class. %s", err);
        return;
    }

    // if (!pd->lua->registerClass(CLASSNAME_BODY, bodyClass, NULL, 0, &err)) {
    //     pb_log("chipmunk: failed to register body class. %s", err);
    //     return;
    // }

    // if (!pd->lua->registerClass(CLASSNAME_SHAPE, shapeClass, NULL, 0, &err)) {
    //     pb_log("chipmunk: failed to register shape class. %s", err);
    //     return;
    // }

//    if (!pd->lua->registerClass(CLASSNAME_CONSTRAINT, constraintClass, NULL, 0, &err)) {
//        pb_log("chipmunk: failed to register constraint class. %s", err);
//        return;
//    }
}
