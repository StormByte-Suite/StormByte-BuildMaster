#include "widget.h"
#include <stdio.h>
int main(void) {
	int v = widget_value();
	if (v != 42) {
		return 1;
	}
	puts("widget-ok");
	return 0;
}
