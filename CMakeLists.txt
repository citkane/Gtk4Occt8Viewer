cmake_minimum_required(VERSION 3.16)
project(
    Gtk4Occt8Viewer
    VERSION 0.0.0
    DESCRIPTION "Gtk4 OCCT8 viewer widget"
    LANGUAGES C CXX
)

file(
    GLOB_RECURSE PROJ_SRCS
    CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
)
set_source_files_properties(
    "${CMAKE_CURRENT_SOURCE_DIR}/src/x11/init_x11_win.cpp"
    PROPERTIES COMPILE_OPTIONS "-Wno-deprecated-declarations"
)

set(PROJ_INCDIR ${CMAKE_CURRENT_SOURCE_DIR}/include)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME})
include(standards)
include(libraries)
include(pkgconfig)

# add_compile_options("-Wall" "-Wextra" "-fPIC")
add_compile_options("-Wall" "-Wextra")
add_library(${PROJECT_NAME} SHARED ${PROJ_SRCS})

target_include_directories(
    ${PROJECT_NAME}
    PUBLIC ${PROJ_INCDIR} ${OpenCASCADE_INCLUDE_DIR}
)
target_link_libraries(${PROJECT_NAME} PRIVATE ${PROJ_PRIVATE_LIBS})
target_link_libraries(
    ${PROJECT_NAME}
    PUBLIC ${OpenCASCADE_Visualization_LIBRARIES}
)
# target_link_options(
#     ${PROJECT_NAME}
#     PRIVATE "-Wl,--disable-new-dtags,-rpath,${OpenCASCADE_LIBRARY_DIR}"
# )

# set_target_properties(
#     TARGET
#     ${PROJECT_NAME}
#     APPEND
#     PROPERTIES
#         BUILD_RPATH "$<TARGET_FILE_DIR:${OpenCASCADE_LIBRARY_DIR}>"
#         INSTALL_RPATH "$<TARGET_FILE_DIR:${OpenCASCADE_LIBRARY_DIR}>"
# )
# target_link_libraries(${PROJECT_NAME} PRIVATE ${PROJ_PRIVATE_LIBS})
# target_link_libraries(${PROJECT_NAME} PUBLIC ${PROJ_PUBLIC_LIBS})

# add_library(${PROJECT_NAME}_shared SHARED $<TARGET_OBJECTS:${PROJECT_NAME}>)
# target_link_libraries(${PROJECT_NAME}_shared PRIVATE ${PROJ_PRIVATE_LIBS})
# target_link_libraries(${PROJECT_NAME}_shared PUBLIC ${PROJ_PUBLIC_LIBS})
# target_include_directories(${PROJECT_NAME}_shared PUBLIC ${PROJ_INCDIRS})

# add_library(${PROJECT_NAME}_static STATIC $<TARGET_OBJECTS:${PROJECT_NAME}>)
# target_link_libraries(${PROJECT_NAME}_static PRIVATE ${PROJ_PRIVATE_LIBS})
# target_link_libraries(${PROJECT_NAME}_static PUBLIC ${PROJ_PUBLIC_LIBS})
# target_include_directories(${PROJECT_NAME}_static PUBLIC ${PROJ_INCDIRS})

# set(PROJ_TARGETS ${PROJECT_NAME}_shared ${PROJECT_NAME}_static)
# set_target_properties(${PROJ_TARGETS} PROPERTIES OUTPUT_NAME ${PROJECT_NAME})

include(install)

# target_include_directories(${PROJECT_NAME} PUBLIC ${INCLUDE_DIRS})
# set(PROJ_INCDIRS ${PROJ_INCDIR})
