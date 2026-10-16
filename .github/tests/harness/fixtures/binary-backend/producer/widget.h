#ifndef WIDGET_H
#define WIDGET_H
#ifdef _WIN32
#  ifdef WIDGET_BUILD
#    define WIDGET_API __declspec(dllexport)
#  else
#    define WIDGET_API __declspec(dllimport)
#  endif
#else
#  define WIDGET_API
#endif
WIDGET_API int widget_value(void);
#endif
