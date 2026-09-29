#include "cr_crypto.h"
#include "cr_buffer.h"
#include "cr_bz2.h"
#include "cr_cryptopp.h"
int cr_crypto_ping(void)
{
    return cr_buffer_ping() + cr_bz2_ping() + cr_pp_ping();
}
