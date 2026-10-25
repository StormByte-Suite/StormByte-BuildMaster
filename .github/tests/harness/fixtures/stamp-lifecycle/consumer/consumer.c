#include <lifecycle/header.h>
int lifecycle_static(void);
int lifecycle_shared(void);
int lifecycle_value(void) {
	return lifecycle_static() + lifecycle_shared() + LIFECYCLE_HEADER;
}
