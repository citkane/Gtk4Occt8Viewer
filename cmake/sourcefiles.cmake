if((NOT IS_NIX AND NOT IS_MACOS) AND USE_X11)
  message(FATAL_ERROR "X11 can't be used on ${CMAKE_SYSTEM_NAME}")
endif()

set(INIT_X11_WIN "${CMAKE_CURRENT_SOURCE_DIR}/src/init/init_x11_win.cpp")
set(INIT_EGL_CTX "${CMAKE_CURRENT_SOURCE_DIR}/src/init/init_egl_ctx.cpp")
set(INIT_WIN_WIN "${CMAKE_CURRENT_SOURCE_DIR}/src/init/init_windows_win.cpp")

file(GLOB PROJ_SRCS CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")

if(USE_GLES)
  list(APPEND PROJ_SRCS "${INIT_EGL_CTX}")
elseif(IS_WIN)
  list(APPEND PROJ_SRCS "${INIT_WIN_WIN}")
elseif(IS_NIX)
  list(APPEND PROJ_SRCS "${INIT_X11_WIN}")
  list(APPEND PROJ_SRCS "${INIT_EGL_CTX}")
elseif(USE_X11)
  list(APPEND PROJ_SRCS "${INIT_X11_WIN}")
else()
  list(APPEND PROJ_SRCS "${INIT_EGL_CTX}")
endif()

if(IS_NIX OR USE_X11)
  set_source_files_properties(
    "${INIT_X11_WIN}" PROPERTIES COMPILE_OPTIONS "-Wno-deprecated-declarations")
endif()
