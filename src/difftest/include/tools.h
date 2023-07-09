#pragma once

#include <random>
#include <bitset>
#include <iostream>
#include <string>


// clang-format off
#define print_err(fmt, args...) printf("[error] \033[31;1m" fmt "\033[0m\n", ##args)
#define print_info(fmt, args...) printf("[info] \033[33;1m" fmt "\033[0m\n", ##args)
#define debug(fmt, args...) printf("\033[32;1m" "[DEBUG] %s:%d:%s" "\033[0m  "  fmt "\n", __FILE_NAME__, __LINE__, __func__, ##args)
// clang-format on

#define U8H(x) (int8_t)((int8_t)((x) >> 4) & 0x0F)
#define U8L(x) (int8_t)((int8_t)(x)&0x0F)
#define BIT(x, n) bitset<(n)>((x)).to_string().c_str()
#define SET_BIT(x, n) (bitset<n>(x))


inline void highlightDifferences(const std::string &str1, const std::string &str2) {
    std::string output;

    // Find the length of the longest common prefix
    size_t prefixLength = 0;
    while (prefixLength < str1.length() && prefixLength < str2.length() && str1[prefixLength] == str2[prefixLength]) {
        prefixLength++;
    }

    // Find the length of the longest common suffix
    size_t suffixLength = 0;
    while (suffixLength < (str1.length() - prefixLength) && suffixLength < (str2.length() - prefixLength) &&
           str1[str1.length() - suffixLength - 1] == str2[str2.length() - suffixLength - 1]) {
        suffixLength++;
    }

    // Append the common prefix
    output += str1.substr(0, prefixLength);

    // Append the differing part with highlighting
    if (prefixLength < str1.length() - suffixLength) {
        output += "\033[1;31m"; // Set color to red
        output += str1.substr(prefixLength, str1.length() - prefixLength - suffixLength);
        output += "\033[0m"; // Reset color
    }
    if (prefixLength < str2.length() - suffixLength) {
        output += "\033[1;32m"; // Set color to green
        output += str2.substr(prefixLength, str2.length() - prefixLength - suffixLength);
        output += "\033[0m"; // Reset color
    }

    // Append the common suffix
    output += str1.substr(str1.length() - suffixLength);

    // Print the highlighted output
    std::cout << output << std::endl;
}
