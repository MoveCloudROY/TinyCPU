#pragma once
#include "tools.h"

#include <array>
#include <cstdint>
#include <iomanip>
#include <iostream>


// 指令PC及提交后状态
struct Status {
    uint32_t                 pc;
    std::array<uint32_t, 32> gpr;
};

inline bool compare_status(const Status &pracImpl, const Status &refImpl) {
    std::stringstream pracStr, refStr;

    bool pc_equ  = (pracImpl.pc == refImpl.pc);
    bool gpr_equ = true;
    for (size_t i = 0; i < 32; ++i) {
        if (pracImpl.gpr[i] != refImpl.gpr[i]) {
            gpr_equ = false;
            break;
        }
    }
    if (pc_equ && gpr_equ)
        return true;

    if (!pc_equ) {
        pracStr << CTL_RED << "[PC] 0x" << std::hex << pracImpl.pc << CTL_RESET << '\n';
        refStr << CTL_GREEN << "[PC] 0x" << std::hex << refImpl.pc << CTL_RESET << '\n';
    } else {
        pracStr << CTL_RESET << "[PC] 0x" << std::hex << pracImpl.pc << CTL_RESET << '\n';
        refStr << CTL_RESET << "[PC] 0x" << std::hex << refImpl.pc << CTL_RESET << '\n';
    }
    for (size_t i = 0; i < 4; ++i) {
        for (size_t j = 0; j < 8; ++j) {
            auto ind = i * 8 + j;
            if (pracImpl.gpr[ind] != refImpl.gpr[ind]) {
                pracStr << CTL_RED << std::dec << "GPR[" << std::setw(2) << ind << "]: 0x" << std::hex << std::setw(8) << std::setfill('0') << pracImpl.gpr[ind] << CTL_RESET << "   ";
                refStr << CTL_GREEN << std::dec << "GPR[" << std::setw(2) << ind << "]: 0x" << std::hex << std::setw(8) << std::setfill('0') << refImpl.gpr[ind] << CTL_RESET << "   ";
            } else {
                pracStr << CTL_RESET << std::dec << "GPR[" << std::setw(2) << ind << "]: 0x" << std::hex << std::setw(8) << std::setfill('0') << pracImpl.gpr[ind] << CTL_RESET << "   ";
                refStr << CTL_RESET << std::dec << "GPR[" << std::setw(2) << ind << "]: 0x" << std::hex << std::setw(8) << std::setfill('0') << refImpl.gpr[ind] << CTL_RESET << "   ";
            }
        }
        pracStr << '\n';
        refStr << '\n';
    }
    std::cout << CTL_ORIANGE << "RefImpl  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> RefImpl" CTL_RESET "\n";
    std::cout << refStr.str();
    std::cout << CTL_ORIANGE << "=================================================" CTL_RESET "\n";
    std::cout << pracStr.str();
    std::cout << CTL_ORIANGE << "PracImpl <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PracImpl" CTL_RESET "\n";

    return false;
}