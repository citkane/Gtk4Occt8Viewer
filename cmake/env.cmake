if(WIN32 OR MINGW)
  set(IS_WIN ON)
  add_compile_definitions(IS_WIN=1)
else()
  set(IS_WIN OFF)
  add_compile_definitions(IS_WIN=0)
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  set(IS_MACOS ON)
  add_compile_definitions(IS_MACOS=1)
else()
  set(IS_MACOS OFF)
  add_compile_definitions(IS_MACOS=0)
endif()

option(USE_GLES2 "Compile with GLES support" OFF)
if(USE_GLES2)
  set(USE_GLES2 ON)
  add_compile_definitions(USE_GLES2=1)
else()
  set(USE_GLES2 OFF)
  add_compile_definitions(USE_GLES2=0)
endif()

if(UNIX
   AND NOT USE_GLES2
   AND NOT APPLE
   AND NOT ANDROID)
  set(WAYLAND_COMPAT ON)
  set(MIN_MESA_V 25.2)
  add_compile_definitions(WAYLAND_COMPAT=1 MIN_MESA_V=${MIN_MESA_V})
else()
  set(WAYLAND_COMPAT OFF)
  add_compile_definitions(WAYLAND_COMPAT=0)
endif()

option(USE_MACX11 "Compile with X11 support on MacOS" OFF)
if(USE_MACX11)
  set(USE_MACX11 ON)
  add_compile_definitions(USE_MACX11=1)
else()
  set(USE_MACX11 OFF)
  add_compile_definitions(USE_MACX11=0)
endif()

set(OpenCASCADE_DIR
    ""
    CACHE PATH "Path to Open CASCADE cmake conf dir.")
