cmake_minimum_required(VERSION 3.0.0)

project(sim)

set(LOONG_BIN_PATH ${CMAKE_SOURCE_DIR}/assets/lab2.bin)

set(CMAKE_BUILD_TYPE Debug)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

message(CMAKE_BINARY_DIR = ${CMAKE_BINARY_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/../bin )

find_package(verilator HINTS $ENV{VERILATOR_ROOT})
message(VERILATOR_ROOT = ${VERILATOR_ROOT})

if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

add_subdirectory(3rdparty)
add_subdirectory(src)
add_subdirectory(vsrc)
