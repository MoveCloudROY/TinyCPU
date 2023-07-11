#pragma once

#include <random>
#include <bitset>
#include <iostream>
#include <string>

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
#define print_d(color ,fmt , args...) printf(color fmt CTL_RESET "\n", ##args)
#define debug(fmt, args...) printf(CTL_BLUE "[DEBUG] %s:%d:%s" CTL_RESET "  "  fmt "\n", __FILE_NAME__, __LINE__, __func__, ##args)
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