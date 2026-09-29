#include "cr_system.h"
#include "cr_string.h"
#if defined(__APPLE__)
#include <CoreFoundation/CoreFoundation.h>
int cr_system_ping(void)
{
    (void)CFAllocatorGetTypeID();
    return cr_string_ping();
}
#elif defined(_WIN32)
#include <windows.h>
int cr_system_ping(void)
{
    (void)GetCurrentProcessId();
    return cr_string_ping();
}
#else
int cr_system_ping(void) { return cr_string_ping(); }
#endif
