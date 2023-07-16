#include "CpuRefImpl.h"
#include "CpuTracer.h"
#include "PerfTracer.h"
#include "Status.h"

#include "Vtop.h"
#include "Vtop___024root.h"
#include "tools.h"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <iomanip>
#include <ios>
#include <ratio>
#include <sstream>
#include <thread>
#include <chrono>
#include <iostream>
#include <queue>
#include <algorithm>
#include <functional>
#include <type_traits>
#include <csignal>

// 参考实现缓冲队列
constexpr const size_t Q_SIZE = 10;

std::queue<Status> inst_done_q;
std::queue<Status> inst_ref_q;

constexpr const uint32_t UART_DATA_ADDR = 0xbfd003f8;
constexpr const uint32_t UART_CTL_ADDR  = 0xbfd003fC;

struct CpuStatus {
    uint32_t pc;
    uint32_t targetAddr;
    uint32_t uartTxBusy;
};

int main(int argc, char **argv) {
    // freopen("trace.txt", "w", stdout);

    // 性能计数器
    difftest::PerfTracer perfTracer;
    // 初始化 CPU
    srand(time(0));
    difftest::CpuTracer<Vtop> cpu{argc, argv};

    CpuStatus lastCpuStatus{};
    CpuStatus nowCpuStatus{};
    cpu.register_beforeCallback([&]() {
        lastCpuStatus = {cpu->rootp->top__DOT__mem2wb_bus_r[0], cpu->rootp->top__DOT__U_wb__DOT__dbg_dm_addr, cpu->rootp->top__DOT____Vtogcov__ext_uart_tx_busy};
    });
    cpu.register_afterCallback([&]() {
        nowCpuStatus = {cpu->rootp->top__DOT__mem2wb_bus_r[0], cpu->rootp->top__DOT__U_wb__DOT__dbg_dm_addr, cpu->rootp->top__DOT____Vtogcov__ext_uart_tx_busy};
    });

    cpu.enable_trace("top.vcd");
    cpu.reset_all();

    // 初始化参考实现
    difftest::CpuRefImpl cpuRef{LOONG_BIN_PATH, 0, true, false};

    bool   running = true;
    size_t StayCnt = 0;


    while (running) {
        // Main thread input handling
        // std::unique_lock<std::mutex> lock(cpuRef.mtx);
        // cpuRef.cv.wait(lock); // Wait for notification from the UART input thread
        // Continue with main thread logic here


        // 获得当前 pc 和 上一个 pc 完成时的 GPR 状态
        cpu.step();

        bool waitingUartTx = lastCpuStatus.uartTxBusy && (nowCpuStatus.targetAddr == UART_CTL_ADDR);
        // print_d(CTL_LIGHTBLUE, "PracPc: 0x%08X   RefPc: 0x%08X", lastCpuStatus.pc, cpuRef.get_pc());
        /*
            串口等待处理:
                1. 检测是否进入串口发送完毕等待循环，判断当前访问地址为 UART_CTL_ADDR & uart_tx_busy
                2. 等待串口发送完毕
                3. 同步 Prac CPU和 Ref CPU
        */
        if (waitingUartTx) {
            // Ref CPU 进行取串口数据指令
            cpuRef.step();
            print_d(CTL_LIGHTBLUE, "[UART] " CTL_RESET "Start Deal -- PracPc: 0x%08X   RefPc: 0x%08X", lastCpuStatus.pc, cpuRef.get_pc());
            // 等待数据读取完成，并执行完当前指令
            while (lastCpuStatus.uartTxBusy || lastCpuStatus.pc == nowCpuStatus.pc) {
                cpu.step();

                waitingUartTx = lastCpuStatus.uartTxBusy && (nowCpuStatus.targetAddr == UART_CTL_ADDR);

                print_d(CTL_LIGHTBLUE, "[UART] " CTL_RESET "Waiting TX -- PracPc: 0x%08X   RefPc: 0x%08X", lastCpuStatus.pc, cpuRef.get_pc());
                // print_d(CTL_LIGHTBLUE, "[UART] " CTL_RESET "Waiting TX -- lastPc: 0x%08X   nowPc: 0x%08X", lastCpuStatus.pc, nowCpuStatus.pc);
            }

            cpu.step();
            waitingUartTx = lastCpuStatus.uartTxBusy && (nowCpuStatus.targetAddr == UART_CTL_ADDR);

            while (lastCpuStatus.pc != cpuRef.get_pc()) {
                cpu.step();
                waitingUartTx = lastCpuStatus.uartTxBusy && (nowCpuStatus.targetAddr == UART_CTL_ADDR);
                print_d(CTL_LIGHTBLUE, "[UART] " CTL_RESET "Sync -- PracPc: 0x%08X   RefPc: 0x%08X", lastCpuStatus.pc, cpuRef.get_pc());
            }
        }

        std::array<uint32_t, 32> gpr;
        std::copy(
            std::begin(cpu->rootp->top__DOT__U_reg_file__DOT__regfile.m_storage),
            std::end(cpu->rootp->top__DOT__U_reg_file__DOT__regfile.m_storage),
            gpr.begin()
        );

        auto lastPcStatus = Status{lastCpuStatus.pc, gpr};

        perfTracer.tick(lastPcStatus.pc != nowCpuStatus.pc);

        //考虑有效性，当 PC 发生变更，则有效
        if (lastPcStatus.pc != nowCpuStatus.pc) {
            StayCnt = 0;
            // 将上一个 pc状态压入
            inst_done_q.push(lastPcStatus);

            // 取参考实现的状态
            auto refLastPc = cpuRef.get_pc();
            cpuRef.step();
            auto cpuRefStatus = Status{refLastPc, cpuRef.get_gpr()};
            // 压入状态参考队列
            inst_ref_q.push(cpuRefStatus);

            // 状态队列维护
            if (inst_done_q.size() > Q_SIZE)
                inst_done_q.pop();
            if (inst_ref_q.size() > Q_SIZE)
                inst_ref_q.pop();
            // debug("UART - exist_tx: 0x%X", cpuRef.uart.exist_tx());
            // debug("UART - DATA: 0x%08X,   CTL: 0x%08X", cpuRef.uart.DATA, cpuRef.uart.CTL);
            // debug("UART - _OCUPPY_1: 0x%08X,   _OCUPPY_2: 0x%08X", cpuRef.uart._OCUPPY_1, cpuRef.uart._OCUPPY_2);
            // debug("UART - _OCUPPY_3: 0x%08X,   _OCUPPY_5: 0x%08X", cpuRef.uart._OCUPPY_3, cpuRef.uart._OCUPPY_5);

            // 比较状态
            if (!compare_status(lastPcStatus, cpuRefStatus)) {
                // for (int k = 0; k < 10; ++k)
                //     cpu.step();
                // 错误时，打印出历史记录
                std::cout << "\n\n" CTL_ORIANGE "Prac CPU History:" CTL_RESET "\n";
                while (!inst_done_q.empty()) {
                    debug("===============================");
                    auto s = inst_done_q.front();
                    inst_done_q.pop();
                    print_d(CTL_PUP, "[Prac CPU]");
                    print_d(CTL_PUP, "PC: 0x%08X", s.pc);
                    print_gpr(s.gpr);
                    print_d(CTL_RESET, "--------------------------------------");
                    auto s_ref = inst_ref_q.front();
                    inst_ref_q.pop();
                    print_d(CTL_PUP, "[Ref CPU]");
                    print_d(CTL_PUP, "PC: 0x%08X", s_ref.pc);
                    print_gpr(s_ref.gpr);
                }
                break;
            }
        } else {
            ++StayCnt;
        }

        running = !cpuRef.is_finished();

        if (StayCnt >= 10) {
            print_info("Pass the DiffTest!");
            perfTracer.print();
            break;
        }
    }


    // std::cout << "=====================" << std::endl;
    // std::cout << "Totally Step: " << stepCnt << std::endl;
}