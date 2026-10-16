#ifndef GADGET_H
#define GADGET_H
#ifdef _WIN32
#  ifdef GADGET_BUILD
#    define GADGET_API __declspec(dllexport)
#  else
#    define GADGET_API __declspec(dllimport)
#  endif
#else
#  define GADGET_API
#endif
GADGET_API int gadget_value(void);
#endif
