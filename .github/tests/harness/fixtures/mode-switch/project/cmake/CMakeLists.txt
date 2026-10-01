cmake_minimum_required(VERSION 3.20)
project(ms-cmake C)
include(GNUInstallDirs)

set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

# Type follows BUILD_SHARED_LIBS from BuildMaster.
add_library(mscmake ms.c)
install(TARGETS mscmake
	ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
	LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
	RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
