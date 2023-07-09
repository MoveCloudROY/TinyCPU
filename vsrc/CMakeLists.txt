add_library(vsrc STATIC)

file(GLOB_RECURSE FILES CONFIGURE_DEPENDS *.v)
list(FILTER FILES EXCLUDE REGEX ".*top\\.v$")
message(${FILES})

verilate(
    vsrc COVERAGE TRACE
    INCLUDE_DIRS "${CMAKE_BINARY_DIR}/../vsrc"
    VERILATOR_ARGS -x-assign 1 
    VERILATOR_ARGS --timing
    VERILATOR_ARGS +define+LOONG_BIN_PATH=${LOONG_BIN_PATH}
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