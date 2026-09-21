option(USE_XWAYLAND "Force xWayland" OFF)

if("$ENV{XDG_SESSION_TYPE}" STREQUAL "wayland" OR DEFINED ENV{WAYLAND_DISPLAY})
    message(STATUS "Found Wayland")
    add_compile_definitions(HAVE_WAYLAND)
    if(
        USE_XWAYLAND
        OR GDK_BACKEND STREQUAL "x11"
        OR "$ENV{GDK_BACKEND}" STREQUAL "x11"
    )
        message(STATUS "Forcing x11 on Wayland")
        add_compile_definitions(USE_X11)
    else()
        add_compile_definitions(USE_WAYLAND)
    endif()
endif()

if("$ENV{XDG_SESSION_TYPE}" STREQUAL "x11")
    message(STATUS "Found x11")
    add_compile_definitions(USE_X11)
endif()
