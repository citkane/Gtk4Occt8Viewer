set(BUILD_CPP_STANDARD "C++17" CACHE STRING "Select using c++ standard.")
set_property(
    CACHE BUILD_CPP_STANDARD
    PROPERTY STRINGS "C++17" "C++20" "C++23" "C++26"
)

if("${BUILD_CPP_STANDARD}" STREQUAL "C++17")
    set(CMAKE_CXX_STANDARD 17)
elseif("${BUILD_CPP_STANDARD}" STREQUAL "C++20")
    set(CMAKE_CXX_STANDARD 20)
elseif("${BUILD_CPP_STANDARD}" STREQUAL "C++23")
    set(CMAKE_CXX_STANDARD 23)
elseif("${BUILD_CPP_STANDARD}" STREQUAL "C++26")
    set(CMAKE_CXX_STANDARD 26)
else()
    message(WARNING "C++ standard is not set or invalid. Set to C++17.")
    set(CMAKE_CXX_STANDARD 17)
endif()

set(CMAKE_CXX_STANDARD_REQUIRED ON)
