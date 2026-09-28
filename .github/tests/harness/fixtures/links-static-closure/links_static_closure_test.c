#include "db.h"
int main(void) { return sl_db_ping() == 7 ? 0 : 1; }
