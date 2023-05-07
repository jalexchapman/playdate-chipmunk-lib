#include <stdlib.h>
#include <stdarg.h>
#include "pdcalloc.h"

void * pdcalloc(size_t count, size_t size) {
	void * retval = malloc(count * size);
	memset(retval, 0, size * count);
	return retval;
}
