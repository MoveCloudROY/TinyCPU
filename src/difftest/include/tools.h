#pragma once

#include <random>
#include <bitset>
#include <iostream>
#include <string>
#include <fstream>

#define CTL_RED "\033[31;1m"
#define CTL_GREEN "\033[32;1m"
#define CTL_ORIANGE "\033[33;1m"
#define CTL_BLUE "\033[34;1m"
#define CTL_PUP "\033[35;1m"
#define CTL_LIGHTBLUE "\033[36;1m"
#define CTL_RESET "\033[0m"

// clang-format off
#define print_err(fmt, args...) printf(CTL_RED "[error] "  fmt CTL_RESET "\n", ##args)
#define print_info(fmt, args...) printf(CTL_GREEN "[info] " fmt CTL_RESET "\n", ##args)
#define print_d(color, fmt , args...) printf(color fmt CTL_RESET "\n", ##args)
#define debug(fmt, args...) printf(CTL_BLUE "[DEBUG] %s:%d:%s" CTL_RESET "  "  fmt "\n", __FILE_NAME__, __LINE__, __func__, ##args)


#define uprint(terminal, fmt, args...) fprintf(terminal, fmt, ##args)
#define uprint_err(terminal, fmt, args...) fprintf(terminal, CTL_RED "[error] "  fmt CTL_RESET "\n", ##args)
#define uprint_info(terminal, fmt, args...) fprintf(terminal, CTL_GREEN "[info] " fmt CTL_RESET "\n", ##args)
#define uprint_d(terminal, color, fmt, args...) fprintf(terminal, color fmt CTL_RESET "\n", ##args)
// clang-format on

#define U8H(x) (int8_t)((int8_t)((x) >> 4) & 0x0F)
#define U8L(x) (int8_t)((int8_t)(x)&0x0F)
#define BIT(x, n) bitset<(n)>((x)).to_string().c_str()
#define SET_BIT(x, n) (bitset<n>(x))


template <typename T>
void print_gpr(T arr) {
    for (int i = 0; i < 8; ++i) {
        for (int j = 0; j < 4; ++j) {
            auto index = i * 4 + j;
            std::printf("GPR[%2d]: 0x%08X   ", index, arr[index]);
        }
        std::printf("\n");
    }
}

inline bool ramdom_init_ext(const char *path) {
    // Open the file in binary mode
    std::ofstream binaryFile(path, std::ios::binary | std::ios::out);

    if (!binaryFile.is_open()) {
        debug("Error opening the file.");
        return 0;
    }

    // Define the number of bytes to fill with zeros
    const int sizeToFill = 0x10c;

    // Create a vector of zeros with the size we want to fill
    std::vector<char> extdata(sizeToFill, 0);
    for (int i = 0x100; i < 0x10c; ++i) {
        extdata[i] = rand();
    }
    extdata[0x104] = 0xFF;
    extdata[0x105] = 0x0F;
    extdata[0x106] = 0;
    extdata[0x107] = 0;

    extdata[0x108] = 0;
    extdata[0x109] = 0;
    extdata[0x10a] = 0;
    extdata[0x10b] = 0;


    // Write the zeros to the file
    binaryFile.write(extdata.data(), sizeToFill);

    // Close the file
    binaryFile.close();
    return 1;
}