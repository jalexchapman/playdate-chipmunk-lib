/*
* Adapted from https://github.com/mierau/playbox2d and the Playdate mini3d sdk sample
*/

#include <math.h>
#include "luaglue.h"
#include "chipmunk.h"


static PlaydateAPI* pd = NULL;

#define CLASSNAME_CHIPMUNK "chipmunk"
#define CLASSNAME_SPACE "chipmunk.space"
#define CLASSNAME_BODY "chipmunk.body"
#define CLASSNAME_SHAPE "chipmunk.shape"
// #define CLASSNAME_CONSTRAINT "chipmunk.constraint"

// UTILITY
static cpSpace* getSpaceArg(int n) { return pd->lua->getArgObject(n, CLASSNAME_SPACE, NULL); }
static cpBody* getBodyArg(int n) { return pd->lua->getArgObject(n, CLASSNAME_BODY, NULL); }
static cpShape* getShapeArg(int n) { return pd->lua->getArgObject(n, CLASSNAME_SHAPE, NULL); }
// static cpConstraint* getConstraintArg(int n) { return pd->lua->getArgObject(n, CLASSNAME_CONSTRAINT, NULL); }

//chipmunk (helpers)
int chipmunk_momentForCircle(lua_State* L)
{
    cpFloat m = pd->lua->getArgFloat(1);
    cpFloat r1 = pd->lua->getArgFloat(2);
    cpFloat r2 = pd->lua->getArgFloat(3);
    cpFloat xOffset = pd->lua->getArgFloat(4);
    cpFloat yOffset = pd->lua->getArgFloat(5);
    pd->lua->pushFloat((float) cpMomentForCircle(m, r1, r2, cpv(xOffset, yOffset)));
    return 1;
}

static const lua_reg chipmunkClass[] = {
    {"momentForCircle", chipmunk_momentForCircle }
};

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

int chipmunk_space_getDamping(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    float damping = cpSpaceGetDamping(space);
    pd->lua->pushFloat(damping);
    return 1;
}

int chipmunk_space_setDamping(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    float damping = pd->lua->getArgFloat(2);
    cpSpaceSetDamping(space, damping);
    return 0;
}

int chipmunk_space_getIterations(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    int iterations = cpSpaceGetIterations(space);
    pd->lua->pushFloat(iterations);
    return 1;
}

int chipmunk_space_setIterations(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    int iterations = pd->lua->getArgInt(2);
    cpSpaceSetIterations(space, iterations);
    return 0;
}

int chipmunk_space_getSleepTimeThreshold(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    float sleepTimeThreshold = cpSpaceGetSleepTimeThreshold(space);
    pd->lua->pushFloat(sleepTimeThreshold);
    return 1;
}

int chipmunk_space_setSleepTimeThreshold(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    float sleepTimeThreshold = pd->lua->getArgFloat(2);
    cpSpaceSetSleepTimeThreshold(space, sleepTimeThreshold);
    return 0;
}

int chipmunk_space_getCollisionSlop(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    float collisionSlop = cpSpaceGetCollisionSlop(space);
    pd->lua->pushFloat(collisionSlop);
    return 1;
}

int chipmunk_space_setCollisionSlop(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    float collisionSlop = pd->lua->getArgFloat(2);
    cpSpaceSetCollisionSlop(space, collisionSlop);
    return 0;
}

int chipmunk_space_getStaticBody(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    cpBody* body = cpSpaceGetStaticBody(space);
    pd->lua->pushObject(body, CLASSNAME_BODY, 0);
    return 1;
}

int chipmunk_space_step(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    float dt = pd->lua->getArgFloat(2);
    cpSpaceStep(space, dt);
    return 0;
}

int chipmunk_space_addShape(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    cpShape* shape = getShapeArg(2);
    cpSpaceAddShape(space, shape); //TODO: expose retval?
    return 0;
}

int chipmunk_space_addBody(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    cpBody* body = getBodyArg(2);
    cpSpaceAddBody(space, body); //TODO: expose retval?
    return 0;
}

int chipmunk_space_removeShape(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    cpShape* shape = getShapeArg(2);
    cpSpaceRemoveShape(space, shape);
    return 0;
}

int chipmunk_space_removeBody(lua_State* L){
    cpSpace* space = getSpaceArg(1);
    cpBody* body = getBodyArg(2);
    cpSpaceRemoveBody(space, body);
    return 0;
}

static const lua_reg spaceClass[] = {
    {"new", chipmunk_space_new },
    {"__gc", chipmunk_space_delete},
//properties
    {"getGravity", chipmunk_space_getGravity},
    {"setGravity", chipmunk_space_setGravity},
    {"getDamping", chipmunk_space_getDamping},
    {"setDamping", chipmunk_space_setDamping},
    {"getIterations", chipmunk_space_getIterations},
    {"setIterations", chipmunk_space_setIterations},
    {"setSleepTimeThreshold", chipmunk_space_setSleepTimeThreshold},
    {"getSleepTimeThreshold", chipmunk_space_getSleepTimeThreshold},
    {"getCollisionSlop", chipmunk_space_getCollisionSlop},
    {"setCollisionSlop", chipmunk_space_setCollisionSlop},
//other get/set: 
// idleSpeedThreshold
// collisionBias
// collisionPersistence
// userData
//get only:
// currentTimeStep
// isLocked
    {"getStaticBody", chipmunk_space_getStaticBody},
//methods
    {"step", chipmunk_space_step},
    {"addShape", chipmunk_space_addShape},
    {"addBody", chipmunk_space_addBody},
    // {"addConstraint", chipmunk_space_addConstraint},
    {"removeShape", chipmunk_space_removeShape},
    
    
    {"removeBody", chipmunk_space_removeBody},
    // {"removeConstraint", chipmunk_space_removeConstraint},
    {NULL, NULL}
};

//SHAPE
int chipmunk_shape_delete(lua_State* L){
    cpShapeFree(getShapeArg(1));
    return 0;
    //TODO: make sure we don't have to delete contents first
}


int chipmunk_shape_getFriction(lua_State* L){
    cpShape *shape = getShapeArg(1);
    pd->lua->pushFloat(cpShapeGetFriction(shape));
    return 1;
}

int chipmunk_shape_setFriction(lua_State* L){
    cpShape *shape = getShapeArg(1);
    cpFloat friction = pd->lua->getArgFloat(2);
    cpShapeSetFriction(shape, friction);
    return 0;
}

int chipmunk_shape_newCircle(lua_State* L){
    cpBody *body = getBodyArg(1);
    cpFloat radius = pd->lua->getArgFloat(2);
    cpFloat xOffset = pd->lua->getArgFloat(3);
    cpFloat yOffset = pd->lua->getArgFloat(4);
    cpShape* shape = cpCircleShapeNew(body, radius, cpv(xOffset, yOffset));
    pd->lua->pushObject(shape, CLASSNAME_SHAPE, 0);
    return 1;
}

int chipmunk_shape_newSegment(lua_State* L){
    cpBody *body = getBodyArg(1);
    cpFloat xA = pd->lua->getArgFloat(2);
    cpFloat yA = pd->lua->getArgFloat(3);
    cpFloat xB = pd->lua->getArgFloat(4);
    cpFloat yB = pd->lua->getArgFloat(5);
    cpFloat radius = pd->lua->getArgFloat(6);
    cpShape* shape = cpSegmentShapeNew(body, cpv(xA, yA), cpv(xB, yB), radius);
    pd->lua->pushObject(shape, CLASSNAME_SHAPE, 0);
    return 1;   
}

int chipmunk_shape_getCircleRadius(lua_State* L){
    cpShape *shape = getShapeArg(1);
    pd->lua->pushFloat(cpCircleShapeGetRadius(shape));
    return 1;
}

int chipmunk_shape_getCircleOffset(lua_State* L){
    cpShape *shape = getShapeArg(1);
    cpVect offset = cpCircleShapeGetOffset(shape);
    pd->lua->pushFloat((float) offset.x);
    pd->lua->pushFloat((float) offset.y);
    return 2;
}



static const lua_reg shapeClass[] = {
    {"__gc", chipmunk_shape_delete},
    //cpBody* cpShapeGetBody(*shape)
    //void cpShapeSetBody(*shape, *body)
    //cpFloat cpShapeGetMass(*shape)
    //void cpShapeSetMass(*shape, cpFloat mass)
    //cpFloat cpShapeGetMoment(*shape)
    {"getFriction", chipmunk_shape_getFriction},
    {"setFriction", chipmunk_shape_setFriction},
    {"getCircleRadius", chipmunk_shape_getCircleRadius},
    {"getCircleOffset", chipmunk_shape_getCircleOffset},
    //cpFloat cpShapeGetFriction(*shape)
    //void cpShapeSetFriction(*shape, cpFloat)
    {"newCircle", chipmunk_shape_newCircle},
    {"newSegment", chipmunk_shape_newSegment}
    //cpCircleShapeGetOffset
    //cpCircleShapeGetRadius
    
};


//BODY
//cpSpace
int chipmunk_body_new(lua_State* L){
    cpFloat mass = pd->lua->getArgFloat(1);
    cpFloat moment = pd->lua->getArgFloat(2);
    cpBody* body = cpBodyNew(mass, moment);
    pd->lua->pushObject(body, CLASSNAME_BODY, 0);
    return 1;
}

int chipmunk_body_delete(lua_State* L){
    cpBodyFree(getBodyArg(1));
    return 0;
}

int chipmunk_body_getPosition(lua_State* L){
    cpBody* body = getBodyArg(1);
    cpVect pos = cpBodyGetPosition(body);
    pd->lua->pushFloat((float) pos.x);
    pd->lua->pushFloat((float) pos.y);
    return 2;
}

int chipmunk_body_setPosition(lua_State* L){
    cpBody* body = getBodyArg(1);
    float posX = pd->lua->getArgFloat(2);
    float posY = pd->lua->getArgFloat(3);
    cpBodySetPosition(body, cpv(posX, posY));
    return 0;
}

int chipmunk_body_getAngle(lua_State* L){
    cpBody* body = getBodyArg(1);
    pd->lua->pushFloat((float) cpBodyGetAngle(body));
    return 1;
}

int chipmunk_body_setAngle(lua_State* L){
    cpBody* body = getBodyArg(1);
    cpFloat angle = pd->lua->getArgFloat(2);
    cpBodySetAngle(body, angle);
    return 0;
}

int chipmunk_body_getForce(lua_State* L){
    cpBody* body = getBodyArg(1);
    cpVect f = cpBodyGetForce(body);
    pd->lua->pushFloat((float) f.x);
    pd->lua->pushFloat((float) f.y);
    return 2;
}

int chipmunk_body_setForce(lua_State* L){
    cpBody* body = getBodyArg(1);
    float fX = pd->lua->getArgFloat(2);
    float fY = pd->lua->getArgFloat(3);
    cpBodySetPosition(body, cpv(fX, fY));
    return 0;
}

int chipmunk_body_getTorque(lua_State* L){
    cpBody* body = getBodyArg(1);
    pd->lua->pushFloat((float) cpBodyGetTorque(body));
    return 1;
}

int chipmunk_body_setTorque(lua_State* L){
    cpBody* body = getBodyArg(1);
    cpFloat torque = pd->lua->getArgFloat(2);
    cpBodySetTorque(body, torque);
    return 0;
}

static const lua_reg bodyClass[] = {
    {"__gc", chipmunk_body_delete},
    {"new", chipmunk_body_new},
    {"getPosition", chipmunk_body_getPosition},
    {"setPosition", chipmunk_body_setPosition},
    {"getAngle", chipmunk_body_getAngle},
    {"setAngle", chipmunk_body_setAngle},
    {"getForce", chipmunk_body_getForce},
    {"setForce", chipmunk_body_setForce},
    {"getTorque", chipmunk_body_getTorque},
    {"setTorque", chipmunk_body_setTorque}
};

void registerChipmunk(PlaydateAPI* playdate)
{
    pd = playdate;
    const char* err;

    if (!pd->lua->registerClass(CLASSNAME_CHIPMUNK, chipmunkClass, NULL, 0, &err)) {
        pd->system->logToConsole("chipmunk: failed to register chipmunk class. %s", err);
        return;
    }

    if (!pd->lua->registerClass(CLASSNAME_SPACE, spaceClass, NULL, 0, &err)) {
        pd->system->logToConsole("chipmunk: failed to register space class. %s", err);
        return;
    }

    if (!pd->lua->registerClass(CLASSNAME_BODY, bodyClass, NULL, 0, &err)) {
        pd->system->logToConsole("chipmunk: failed to register body class. %s", err);
        return;
    }

    if (!pd->lua->registerClass(CLASSNAME_SHAPE, shapeClass, NULL, 0, &err)) {
        pd->system->logToConsole("chipmunk: failed to register shape class. %s", err);
        return;
    }

//    if (!pd->lua->registerClass(CLASSNAME_CONSTRAINT, constraintClass, NULL, 0, &err)) {
//        pb_log("chipmunk: failed to register constraint class. %s", err);
//        return;
//    }
}
