cmake_minimum_required(VERSION 3.16)
project(
    Gtk4Occt8Viewer
    VERSION 0.0.0
    DESCRIPTION "Gtk4 OCCT8 viewer widget"
    LANGUAGES C CXX
)
set(CMAKE_C_STANDARD 20)
set(CMAKE_CXX_STANDARD 20)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME})
find_package(PkgConfig REQUIRED)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(dependencies)
# include(compile_defs)
include(vars)
include(pkgconfig)

add_compile_options("-Wall" "-Wextra" "-fPIC")
set_source_files_properties(
    "${CMAKE_CURRENT_SOURCE_DIR}/src/x11/init_x11_win.cpp"
    # /home/michael/Work/tries/2026-08-30-viewer/src/x11/init_x11_win.cpp
    PROPERTIES COMPILE_OPTIONS "-Wno-deprecated-declarations"
)
add_library(${PROJECT_NAME} OBJECT ${viewer_SRC})
target_link_libraries(${PROJECT_NAME} PUBLIC ${PUBLIC_LIBS})
target_link_libraries(${PROJECT_NAME} PRIVATE ${PRIVATE_LIBS})
target_include_directories(${PROJECT_NAME} PUBLIC ${INCLUDE_DIRS})

add_library(${PROJECT_NAME}_shared SHARED $<TARGET_OBJECTS:${PROJECT_NAME}>)
add_library(${PROJECT_NAME}_static STATIC $<TARGET_OBJECTS:${PROJECT_NAME}>)

set(TARGETS ${PROJECT_NAME}_shared ${PROJECT_NAME}_static)
set_target_properties(${TARGETS} PROPERTIES OUTPUT_NAME ${PROJECT_NAME})

include(install)
