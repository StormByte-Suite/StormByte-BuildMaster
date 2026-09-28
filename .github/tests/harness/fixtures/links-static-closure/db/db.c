#include "db.h"
#include "pq.h"
int sl_db_ping(void) { return sl_pq_ping(); }
