HEAP_SIZE      = 8388208
STACK_SIZE     = 61800

PRODUCT = ChipmunkLibrary.pdx

SDK = ${PLAYDATE_SDK_PATH}
ifeq ($(SDK),)
	SDK = $(shell egrep '^\s*SDKRoot' ~/.Playdate/config | head -n 1 | cut -c9-)
endif

ifeq ($(SDK),)
$(error SDK path not found; set ENV value PLAYDATE_SDK_PATH)
endif

VPATH += chipdx
VPATH += chipmunk/src
VPATH += chipmunk/include
VPATH += chipmunk/include/chipmunk

# List C source files here
SRC = \
	chipdx/main.c \
	chipdx/luaglue.c \
	chipmunk/src/chipmunk.c \
	chipmunk/src/cpArbiter.c \
	chipmunk/src/cpArray.c \
	chipmunk/src/cpBBTree.c \
	chipmunk/src/cpBody.c \
	chipmunk/src/cpCollision.c \
	chipmunk/src/cpConstraint.c \
	chipmunk/src/cpDampedRotarySpring.c \
	chipmunk/src/cpDampedSpring.c \
	chipmunk/src/cpGearJoint.c \
	chipmunk/src/cpGrooveJoint.c \
	chipmunk/src/cpHashSet.c \
	chipmunk/src/cpMarch.c \
	chipmunk/src/cpPinJoint.c \
	chipmunk/src/cpPivotJoint.c \
	chipmunk/src/cpPolyline.c \
	chipmunk/src/cpPolyShape.c \
	chipmunk/src/cpRatchetJoint.c \
	chipmunk/src/cpRobust.c \
	chipmunk/src/cpRotaryLimitJoint.c \
	chipmunk/src/cpShape.c \
	chipmunk/src/cpSimpleMotor.c \
	chipmunk/src/cpSlideJoint.c \
	chipmunk/src/cpSpace.c \
	chipmunk/src/cpSpaceComponent.c \
	chipmunk/src/cpSpaceDebug.c \
	chipmunk/src/cpSpaceHash.c \
	chipmunk/src/cpSpaceQuery.c \
	chipmunk/src/cpSpaceStep.c \
	chipmunk/src/cpSpatialIndex.c \
	chipmunk/src/cpSweep1D.c
	
	

ASRC = setup.s

# List all user directories here
UINCDIR = chipdx chipmunk/include chipmunk/include/chipmunk

# List all user C define here, like -D_DEBUG=1
UDEFS = -DCP_USE_DOUBLES=0 -DCP_USE_CGTYPES=0

# Define ASM defines here
UADEFS =

# List the user directory to look for the libraries here
ULIBDIR =

# List all user libraries here
ULIBS =

#CLANGFLAGS = -fsanitize=address

include $(SDK)/C_API/buildsupport/common.mk

LDFLAGS += --specs=nosys.specs