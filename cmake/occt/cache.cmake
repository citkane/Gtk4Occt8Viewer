set(CMAKE_C_COMPILER_LAUNCHER "ccache" CACHE STRING "use ccache")
set(CMAKE_CXX_COMPILER_LAUNCHER "ccache" CACHE STRING "use ccache")
set(CMAKE_BUILD_TYPE "Release" CACHE STRING "build release")
set(BUILD_CPP_STANDARD "C++26" CACHE STRING "use C++26 standard")
set(BUILD_USE_PCH ON CACHE BOOL "build with pre-compiled headers" FORCE)
set(BUILD_USE_VCPKG OFF CACHE BOOL "turn off VCPKG" FORCE)
set(USE_TBB ON CACHE BOOL "use TBB memory management" FORCE)
set(USE_MMGR_TYPE "TBB" CACHE STRING "use TBB memory management" FORCE)
set(USE_XLIB OFF CACHE BOOL "Do not Use x11" FORCE)
set(USE_OPENGL ON CACHE BOOL "use OpenGL" FORCE)
set(USE_GLES2 OFF CACHE BOOL "do not use OpenGL ES" FORCE)
set(HAVE_EGL OFF CACHE BOOL "do not use OpenGL ES" FORCE)
set(USE_FREEIMAGE ON CACHE BOOL "use FreeImage" FORCE)
set(USE_FREETYPE ON CACHE BOOL "use FreeType" FORCE)
set(USE_RAPIDJSON ON CACHE BOOL "use RapidJSON" FORCE)
set(USE_DRACO ON CACHE BOOL "use Draco" FORCE)
set(USE_EIGEN ON CACHE BOOL "use Eigen" FORCE)
# set(BUILD_MODULE_Visualization
#     ON
#     CACHE BOOL
#     "build visualisation modules"
#     FORCE
# )
# set(BUILD_MODULE_ApplicationFramework
#     ON
#     CACHE BOOL
#     "build application framework modules"
#     FORCE
# )
# set(BUILD_MODULE_DRAW OFF CACHE BOOL "do not build DRAW module" FORCE)
