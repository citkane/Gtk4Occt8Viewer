if((NOT WAYLAND_COMPAT AND NOT IS_MACOS) AND USE_X11)
  message(FATAL_ERROR "X11 can't be used on ${CMAKE_SYSTEM_NAME}")
endif()

file(GLOB_RECURSE PROJ_SRCS CONFIGURE_DEPENDS
     "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")

set_source_files_properties(
  "${CMAKE_CURRENT_SOURCE_DIR}/src/init/init_native_win.cpp"
  PROPERTIES COMPILE_OPTIONS "-Wno-deprecated-declarations")
