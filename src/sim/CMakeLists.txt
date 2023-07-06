file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS src/*.cpp)

add_executable(sim ${SOURCES})

target_include_directories(sim  PUBLIC include)
target_link_libraries(sim PRIVATE vsrc)

message(STATUS CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR})

target_compile_options(sim PRIVATE -fno-omit-frame-pointer)
target_compile_options(sim PRIVATE -fsanitize=address)
target_link_options(sim PRIVATE -fsanitize=address)