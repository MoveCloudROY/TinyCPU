add_library(vsrc STATIC)

file(GLOB_RECURSE FILES CONFIGURE_DEPENDS *.v)
list(FILTER FILES EXCLUDE REGEX ".*top\\.v$")
message(${FILES})

set(PATH ${CMAKE_SOURCE_DIR}/assets/fib.raw)

verilate(
    vsrc COVERAGE TRACE
    INCLUDE_DIRS "${CMAKE_BINARY_DIR}/../vsrc"
    VERILATOR_ARGS -x-assign 1 
    VERILATOR_ARGS --timing
    VERILATOR_ARGS +define+PATH=${PATH}
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