/* Installed headers only: compiling before hn-logger/hn-system install fails. */
#include "hn_logger.h"
#include "hn_system.h"
#include "hn_buffer.h"

int hn_buffer(void) {
	return hn_logger() + hn_system() + 1;
}
