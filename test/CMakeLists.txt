# set(LOONG_LAB1_BIN_PATH ${CMAKE_SOURCE_DIR}/assets/lab1.bin)
# set(LOONG_LAB2_BIN_PATH ${CMAKE_SOURCE_DIR}/assets/lab2.bin)

include(CTest)

add_executable(test_lab1 lab1.cpp)

target_link_libraries(test_lab1 PUBLIC cosim)
target_compile_definitions(test_lab1 PRIVATE -DLOONG_BIN_PATH="${LOONG_LAB1_BIN_PATH}")
target_compile_definitions(test_lab1 PRIVATE -DLOONG_DBIN_PATH="${LOONG_LAB1_DBIN_PATH}")
target_link_libraries(test_lab1 PUBLIC vsrc_lab1)

add_executable(test_lab2 lab2.cpp)

target_link_libraries(test_lab2 PUBLIC cosim)
target_compile_definitions(test_lab2 PRIVATE -DLOONG_BIN_PATH="${LOONG_LAB2_BIN_PATH}")
target_compile_definitions(test_lab2 PRIVATE -DLOONG_DBIN_PATH="${LOONG_LAB2_DBIN_PATH}")
target_link_libraries(test_lab2 PUBLIC vsrc_lab2)

target_compile_options(test_lab2 PRIVATE -fno-omit-frame-pointer)
target_compile_options(test_lab2 PRIVATE -fsanitize=address)
target_link_options(test_lab2 PRIVATE -fsanitize=address)
add_test(NAME lab1 COMMAND test_lab1)
add_test(NAME lab2 COMMAND test_lab2)
