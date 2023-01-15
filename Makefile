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
VPATH += chipmunk

# List C source files here
SRC = \
	chipdx/main.c \
	chipdx/luaglue.c \
	#chipmunk/src/ everything
	

ASRC = setup.s

# List all user directories here
UINCDIR = chipdx chipmunk

# List all user C define here, like -D_DEBUG=1
UDEFS =

# Define ASM defines here
UADEFS =

# List the user directory to look for the libraries here
ULIBDIR =

# List all user libraries here
ULIBS =

#CLANGFLAGS = -fsanitize=address

include $(SDK)/C_API/buildsupport/common.mk
