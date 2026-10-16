#include "gadget.h"
#include "widget.h"
#include <stdio.h>
int main(void) {
	if (widget_value() != 42 || gadget_value() != 7) {
		return 1;
	}
	puts("widget-ok");
	return 0;
}

