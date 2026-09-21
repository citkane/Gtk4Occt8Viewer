cmake_minimum_required(VERSION 3.16)
project(
    example_viewer
    VERSION 0.0.0
    DESCRIPTION "Example app for Gtk4Occt8Viewer widget"
    LANGUAGES C CXX
)
set(CMAKE_C_STANDARD 20)
set(CMAKE_CXX_STANDARD 20)

find_package(PkgConfig REQUIRED)
find_package(peel REQUIRED)
peel_generate(Gtk 4.0 RECURSIVE)
# set(Gtk4Occt8Viewer_USE_STATIC ON)
find_package(Gtk4Occt8Viewer REQUIRED)
if(NOT Gtk4Occt8Viewer_FOUND)
    message(FATAL_ERROR "could not find Gtk4Occt8Viewer")
else()
    message(STATUS "Gtk4Occt8Viewer_INCLUDE_DIR=${Gtk4Occt8Viewer_INCLUDE_DIR}")
    message(STATUS "Gtk4Occt8Viewer_LIBRARY_DIR=${Gtk4Occt8Viewer_LIBRARY_DIR}")
    message(STATUS "Gtk4Occt8Viewer_LIBRARIES=${Gtk4Occt8Viewer_LIBRARIES}")
endif()
message(STATUS ${Gtk4Occt8Viewer_LIBRARIES})
add_compile_options("-Wall" "-Wextra")
add_executable(${PROJECT_NAME} ${CMAKE_CURRENT_LIST_DIR}/main.cpp)
target_link_libraries(
    ${PROJECT_NAME}
    PUBLIC ${Gtk4Occt8Viewer_LIBRARIES} peel::Gtk
)
install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
