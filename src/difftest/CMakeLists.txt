file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS src/*.cpp)

# add_executable(difftest ${SOURCES})
add_library(cosim ${SOURCES})

# set(LOONG_BIN_PATH ${CMAKE_SOURCE_DIR}/assets/lab2.bin)
# target_compile_definitions(difftest PRIVATE -DLOONG_BIN_PATH="${LOONG_BIN_PATH}")
# target_include_directories(difftest  PUBLIC include)
# target_link_libraries(difftest PRIVATE vsrc)
# target_link_libraries(difftest PRIVATE cemu)

target_include_directories(cosim PUBLIC include)
target_link_libraries(cosim PUBLIC cemu)

message(STATUS CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR})

# target_compile_options(difftest PRIVATE -fno-omit-frame-pointer)
# target_compile_options(difftest PRIVATE -fsanitize=address)
# target_link_options(difftest PRIVATE -fsanitize=address)