cmake_minimum_required(VERSION 3.16)
project(
    example_viewer
    VERSION 0.0.0
    DESCRIPTION "Example app for Gtk4Occt8Viewer widget"
    LANGUAGES C CXX
)
set(CMAKE_CXX_STANDARD 17)
include(GNUInstallDirs)

find_package(peel REQUIRED)
peel_generate(Gtk 4.0 RECURSIVE)
# set(Gtk4Occt8Viewer_USE_STATIC ON)
find_package(Gtk4Occt8Viewer REQUIRED)
if(NOT Gtk4Occt8Viewer_FOUND)
    message(FATAL_ERROR "could not find Gtk4Occt8Viewer")
endif()

add_compile_options("-Wall" "-Wextra")
add_executable(${PROJECT_NAME} ${CMAKE_CURRENT_LIST_DIR}/main.cpp)
target_link_libraries(
    ${PROJECT_NAME}
    PUBLIC Gtk4Occt8Viewer peel::Gtk PkgConfig::GTK4 PkgConfig::EGL
)

install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
# set(LIB_SHARED ${Gtk4Occt8Viewer_LIBDIR}/lib${Gtk4Occt8Viewer_LIBRARIES}.so)
# target_include_directories(${PROJECT_NAME} PUBLIC ${Gtk4Occt8Viewer_INCDIR})
# target_link_directories(${PROJECT_NAME} PRIVATE ${Gtk4Occt8Viewer_LIBRARY_DIR})
# set(PROJ_PUBLIC_LIBS)
# foreach(LIBNAME ${OpenCASCADE_Visualization_LIBRARIES})
#     list(APPEND PROJ_PUBLIC_LIBS ${OpenCASCADE_LIBRARY_DIR}/lib${LIBNAME}.so)
# endforeach()
#
# message(STATUS "OCCT Libs: ${PROJ_PUBLIC_LIBS}")
# ${OpenCASCADE_Visualization_LIBRARIES}
# ${Gtk4Occt8Viewer_LIBDIR}/lib${Gtk4Occt8Viewer_LIBRARY}.so
# "${PROJ_PUBLIC_LIBS}"
