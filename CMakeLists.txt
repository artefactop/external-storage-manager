# check http://elementaryos.org/docs/developer-guide/cmake/simple-project

cmake_minimum_required(VERSION 2.8)
cmake_policy(VERSION 2.8)
project(external-storage-manager)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

find_package(PkgConfig)
pkg_check_modules(DEPS
    REQUIRED
    glib-2.0
    gtk+-3.0
    appindicator3-0.1
    libnotify
    granite)

set(NORMAL_CFLAGS ${DEPS_CFLAGS})
set(NORMAL_LIBRARIES ${DEPS_LIBRARIES})
set(NORMAL_LINK_DIRS ${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16.0" MINIMUM)
include(ValaPrecompile)

set(DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set(PKG_DATADIR "${CMAKE_INSTALL_PREFIX}/share/external-storage-manager")
set(GETTEXT_PACKAGE "external-storage-manager")
set(RELEASE_NAME "alpha")
set(VERSION "0.1")
set(VERSION_INFO "Pre-Release")
set(ICON_DIR "${CMAKE_INSTALL_PREFIX}/share/external-storage-manager/icons/hicolor")
configure_file(${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_SOURCE_DIR}/src/config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

add_subdirectory(src)
add_subdirectory(data)
#add_subdirectory(po)
add_subdirectory(icons)

