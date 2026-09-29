#include "cr_buffer.h"
#include "cr_logger.h"
#include "cr_system.h"
int cr_buffer_ping(void) { return cr_logger_ping() + cr_system_ping(); }
