pkg_check_modules(GTK4 REQUIRED IMPORTED_TARGET gtk4)
# pkg_check_modules(OpenGL REQUIRED IMPORTED_TARGET gl)
pkg_check_modules(EGL REQUIRED IMPORTED_TARGET egl)
# pkg_check_modules(WAYLAND_EGL REQUIRED IMPORTED_TARGET wayland-egl)
find_package(peel REQUIRED)
peel_generate(Gtk 4.0 RECURSIVE)

find_package(OpenCASCADE REQUIRED)
if(NOT OpenCASCADE_FOUND)
    message(
        FATAL_ERROR
        "could not find OpenCASCADE, please set OpenCASCADE_DIR variable"
    )
else()
    set(OCCT_LIBS ${OpenCASCADE_Visualization_LIBRARIES})
    message(STATUS "Using OpenCASCADE from \"${OpenCASCADE_INSTALL_PREFIX}\"")
    message(STATUS "OpenCASCADE_INCLUDE_DIR=${OpenCASCADE_INCLUDE_DIR}")
    message(STATUS "OpenCASCADE_LIBRARY_DIR=${OpenCASCADE_LIBRARY_DIR}")
    message(STATUS "Using OpenCASCADE Libraries: ${OCCT_LIBS}")
endif()
