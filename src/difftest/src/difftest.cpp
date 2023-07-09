#include "CpuRefImpl.h"
#include "CpuTracer.h"
#include "Vtop.h"
#include "Vtop___024root.h"
#include "tools.h"

#include <array>
#include <cstddef>
#include <cstdint>
#include <iomanip>
#include <ios>
#include <sstream>
#include <thread>
#include <chrono>
#include <iostream>
#include <queue>
#include <algorithm>
#include <functional>
#include <type_traits>

// 指令PC及提交后状态
struct Status {
    uint32_t                 pc;
    std::array<uint32_t, 32> gpr;
};

// 参考实现缓冲队列
std::vector<Status> inst_done_q;

std::vector<Status> inst_ref_q;

constexpr const size_t Q_SIZE = 6;

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

bool compare_status(const Status &pracImpl, const Status &refImpl) {
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
#define CTL_RED "\033[31;1m"
#define CTL_GREEN "\033[32;1m"
#define CTL_ORIANGE "\033[33;1m"
#define CTL_BLUE "\033[34;1m"
#define CTL_PUP "\033[35;1m"
#define CTL_LIGHTBLUE "\033[36;1m"
#define CTL_RESET "\033[0m"
    if (!pc_equ) {
        pracStr << CTL_RED << "[PC]" << pracImpl.pc << CTL_RESET << '\n';
        refStr << CTL_GREEN << "[PC]" << refImpl.pc << CTL_RESET << '\n';
    } else {
        pracStr << CTL_RESET << "[PC]" << pracImpl.pc << CTL_RESET << '\n';
        refStr << CTL_RESET << "[PC]" << refImpl.pc << CTL_RESET << '\n';
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


int main(int argc, char **argv) {

    // 初始化 CPU
    srand(time(0));
    CpuTracer<Vtop> cpu{argc, argv};
    cpu.enable_trace("top.vcd");
    cpu.reset_all();

    // 初始化参考实现
    difftest::CpuRefImpl cpuRef{LOONG_BIN_PATH, 0, true, false};

    bool     running = true;
    uint32_t lastPc  = 0;
    // size_t stepCnt = 0;
    while (running) {
        // ++stepCnt;
        // print_info("step: %lu", stepCnt);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));

        // // 保存 6 条指令
        // if (inst_wait_q.size() <= Q_SIZE) {
        //     auto npc = cpuRef.get_pc() - 0x1c000000;
        //     cpuRef.step();
        //     inst_wait_q.push_back({npc, cpuRef.get_gpr()});
        //     // debug("now_pc = %u", npc);
        //     // print_gpr(inst_wait_q.rbegin()->gpr);
        // }

        // 获得当前 pc 和 上一个 pc 完成时的 GPR 状态
        cpu.step();
        uint32_t now_pc = cpu->rootp->top__DOT__mem2wb_bus_r[0];
        debug("now_pc = %u", now_pc);
        std::array<uint32_t, 32> gpr;
        std::copy(
            std::begin(cpu->rootp->top__DOT__U_reg_file__DOT__regfile.m_storage),
            std::end(cpu->rootp->top__DOT__U_reg_file__DOT__regfile.m_storage),
            gpr.begin()
        );
        print_gpr(gpr);

        auto lastPcStatus = Status{lastPc, gpr};

        //考虑有效性，当 PC 发生变更，则有效
        if (lastPcStatus.pc != now_pc) {
            // 将上一个 pc状态压入
            inst_done_q.push_back(lastPcStatus);

            // 取参考实现的状态
            auto ref_npc = cpuRef.get_pc() - 0x1c000000;
            cpuRef.step();
            auto cpuRefStatus = Status{ref_npc, cpuRef.get_gpr()};
            // 压入状态参考队列
            inst_ref_q.push_back(cpuRefStatus);


            if (!compare_status(lastPcStatus, cpuRefStatus)) {
                break;
            }
        }
        lastPc = now_pc;


        running = !cpuRef.is_finished();
    }
    // std::cout << "=====================" << std::endl;
    // std::cout << "Totally Step: " << stepCnt << std::endl;
}