find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK4 REQUIRED IMPORTED_TARGET gtk4)
pkg_check_modules(EGL REQUIRED IMPORTED_TARGET egl)
find_package(peel REQUIRED)
peel_generate(Gtk 4.0 RECURSIVE)

find_package(OpenCASCADE REQUIRED)
if(NOT OpenCASCADE_FOUND)
    message(
        FATAL_ERROR
        "could not find OpenCASCADE, please set OpenCASCADE_DIR variable"
    )
else()
    message(STATUS "Using OpenCASCADE from \"${OpenCASCADE_INSTALL_PREFIX}\"")
    message(STATUS "OpenCASCADE_INCLUDE_DIR=${OpenCASCADE_INCLUDE_DIR}")
    message(STATUS "OpenCASCADE_LIBRARY_DIR=${OpenCASCADE_LIBRARY_DIR}")
    message(STATUS "OCCT Libraries: ${OpenCASCADE_Visualization_LIBRARIES}")
endif()

set(PROJ_PRIVATE_LIBS PkgConfig::EGL PkgConfig::GTK4 peel::Gtk)
set(PROJ_PUBLIC_LIBS)
foreach(LIBNAME ${OpenCASCADE_Visualization_LIBRARIES})
    list(APPEND PROJ_PUBLIC_LIBS ${OpenCASCADE_LIBRARY_DIR}/lib${LIBNAME}.so)
endforeach()
message(STATUS ${PROJ_PUBLIC_LIBS})
