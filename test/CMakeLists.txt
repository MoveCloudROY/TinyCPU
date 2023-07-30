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

add_executable(test_lab3 lab3.cpp)

target_link_libraries(test_lab3 PUBLIC cosim)
target_compile_definitions(test_lab3 PRIVATE -DLOONG_BIN_PATH="${LOONG_LAB3_BIN_PATH}")
target_compile_definitions(test_lab3 PRIVATE -DLOONG_DBIN_PATH="${LOONG_LAB3_DBIN_PATH}")
target_link_libraries(test_lab3 PUBLIC vsrc_lab3)

add_executable(test_perf perf.cpp)

target_link_libraries(test_perf PUBLIC cosim)
target_compile_definitions(test_perf PRIVATE -DLOONG_BIN_PATH="${LOONG_PERF_BIN_PATH}")
target_compile_definitions(test_perf PRIVATE -DLOONG_DBIN_PATH="${LOONG_PERF_DBIN_PATH}")
target_link_libraries(test_perf PUBLIC vsrc_perf)

target_compile_options(test_lab3 PRIVATE -fno-omit-frame-pointer)
target_compile_options(test_lab3 PRIVATE -fsanitize=address)
target_link_options(test_lab3 PRIVATE -fsanitize=address)

add_test(NAME lab1 COMMAND test_lab1)
add_test(NAME lab2 COMMAND test_lab2)
add_test(NAME lab3 COMMAND test_lab3)
add_test(NAME perf COMMAND test_perf)