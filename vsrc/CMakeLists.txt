add_library(vsrc_lab1 STATIC)
add_library(vsrc_lab2 STATIC)
add_library(vsrc_lab3 STATIC)
add_library(vsrc_perf STATIC)

file(GLOB_RECURSE FILES CONFIGURE_DEPENDS *.v)
list(FILTER FILES EXCLUDE REGEX ".*top\\.v$")
message(${FILES})

verilate(
    vsrc_lab1 COVERAGE TRACE
    INCLUDE_DIRS "${CMAKE_BINARY_DIR}/../vsrc"
    VERILATOR_ARGS -x-assign 1 
    VERILATOR_ARGS --timing
    VERILATOR_ARGS +define+LOONG_BIN_PATH=${LOONG_LAB1_BIN_PATH}
    VERILATOR_ARGS +define+LOONG_DBIN_PATH=${LOONG_LAB1_DBIN_PATH}
    SOURCES top.v ${FILES} common.vh
    TOP_MODULE top
)

verilate(
    vsrc_lab2 COVERAGE TRACE
    INCLUDE_DIRS "${CMAKE_BINARY_DIR}/../vsrc"
    VERILATOR_ARGS -x-assign 1 
    VERILATOR_ARGS --timing
    VERILATOR_ARGS +define+LOONG_BIN_PATH=${LOONG_LAB2_BIN_PATH}
    VERILATOR_ARGS +define+LOONG_DBIN_PATH=${LOONG_LAB2_DBIN_PATH}
    SOURCES top.v ${FILES} common.vh
    TOP_MODULE top
)

verilate(
    vsrc_lab3 COVERAGE TRACE
    INCLUDE_DIRS "${CMAKE_BINARY_DIR}/../vsrc"
    VERILATOR_ARGS -x-assign 1 
    VERILATOR_ARGS --timing
    VERILATOR_ARGS +define+LOONG_BIN_PATH=${LOONG_LAB3_BIN_PATH}
    VERILATOR_ARGS +define+LOONG_DBIN_PATH=${LOONG_LAB3_DBIN_PATH}
    SOURCES top.v ${FILES} common.vh
    TOP_MODULE top
)

verilate(
    vsrc_perf COVERAGE TRACE
    INCLUDE_DIRS "${CMAKE_BINARY_DIR}/../vsrc"
    VERILATOR_ARGS -x-assign 1 
    VERILATOR_ARGS --timing
    VERILATOR_ARGS +define+LOONG_BIN_PATH=${LOONG_PERF_BIN_PATH}
    VERILATOR_ARGS +define+LOONG_DBIN_PATH=${LOONG_PERF_DBIN_PATH}
    SOURCES top.v ${FILES} common.vh
    TOP_MODULE top
)
# verilate(
#     vsrc COVERAGE TRACE
#     INCLUDE_DIRS "${CMAKE_BINARY_DIR}/../vsrc"
#     VERILATOR_ARGS -x-assign 1 
#     VERILATOR_ARGS --timing
#     SOURCES ${FILES} common.vh
#     TOP_MODULE tb
# )