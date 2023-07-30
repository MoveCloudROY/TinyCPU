cmake_minimum_required(VERSION 3.0.0)

project(sim)

set(LOONG_LAB1_BIN_PATH ${CMAKE_SOURCE_DIR}/assets/lab1.bin)
set(LOONG_LAB1_DBIN_PATH ${CMAKE_SOURCE_DIR}/assets/lab1.dbin)

set(LOONG_LAB2_BIN_PATH ${CMAKE_SOURCE_DIR}/assets/lab2.bin)
set(LOONG_LAB2_DBIN_PATH ${CMAKE_SOURCE_DIR}/assets/lab2.dbin)

set(LOONG_LAB3_BIN_PATH ${CMAKE_SOURCE_DIR}/assets/lab3_verilator.bin)
set(LOONG_LAB3_DBIN_PATH ${CMAKE_SOURCE_DIR}/assets/lab3.dbin)

set(LOONG_PERF_BIN_PATH ${CMAKE_SOURCE_DIR}/assets/perf_verilator.bin)
set(LOONG_PERF_DBIN_PATH ${CMAKE_SOURCE_DIR}/assets/perf.dbin)

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

enable_testing()
add_subdirectory(test)
