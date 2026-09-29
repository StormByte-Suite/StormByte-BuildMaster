#include "hn_crypto.h"

/* logger 1 + system 2 + buffer 1 + crypto 1 */
int main(void) {
	return hn_crypto() == 5 ? 0 : 1;
}
