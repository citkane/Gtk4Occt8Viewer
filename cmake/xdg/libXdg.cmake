add_library(Xdg "${CMAKE_CURRENT_SOURCE_DIR}/.local/src/xdg/xdg-shell.c")
target_include_directories(
    Xdg
    PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/.local/include"
)
