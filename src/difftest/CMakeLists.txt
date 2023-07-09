file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS src/*.cpp)

add_executable(difftest ${SOURCES})


target_compile_definitions(difftest PRIVATE -DLOONG_BIN_PATH="${LOONG_BIN_PATH}")
target_include_directories(difftest  PUBLIC include)
target_link_libraries(difftest PRIVATE vsrc)
target_link_libraries(difftest PRIVATE cemu)

message(STATUS CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR})

target_compile_options(difftest PRIVATE -fno-omit-frame-pointer)
target_compile_options(difftest PRIVATE -fsanitize=address)
target_link_options(difftest PRIVATE -fsanitize=address)