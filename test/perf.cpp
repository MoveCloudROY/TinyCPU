#include <utility>
#include <vector>
#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include "doctest.h"

#include "CpuRefImpl.h"
#include "CpuTracer.h"
#include "Tools.h"
#include "ThreadRaii.h"
#include "Structs.h"

#include "Vtop.h"
#include "Vtop___024root.h"
#include "defines.h"

#include <array>
#include <bits/chrono.h>
#include <cassert>
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
#include <fstream>
#include <termios.h>
#include <signal.h>

constexpr size_t TRACE_DEEP = 5;

#define UTEST_SIMPLE 0x00003000
#define UTEST_STREAM 0x00003008
#define UTEST_MATRIX 0x00003030
#define UTEST_CRYPTONIGHT 0x000030b4


#define UTEST_SELECT UTEST_MATRIX


namespace {
std::function<void(int)> shutdown_handler;

void signal_handler(int signal) {
    shutdown_handler(signal);
}
} // namespace


int test_main(int argc, char **argv) {

    /*=========================================================================*/
    //                               初始化开始
    /*=========================================================================*/

    srand(time(0));
    // 初始化 ExtRam
    // ramdom_init_ext(LOONG_DBIN_PATH);


    // freopen("trace.txt", "w", stdout);

    // 初始化 CPU
    srand(time(0));
    difftest::CpuTracer<Vtop, CpuStatus> cpu{argc, argv, TRACE_DEEP};

    // CPU 监控状态回调
    auto updateFunc = [&]() -> CpuStatus {
        return {
            cpu->rootp->top__DOT__mem2wb_bus_r[0],
            cpu->rootp->top__DOT__U_wb__DOT__dbg_dm_addr,
            cpu->rootp->top__DOT__U_wb__DOT__rf_wdata_o,
            cpu->rootp->top__DOT____Vtogcov__ext_uart_tx_busy,
            cpu->rootp->top__DOT____Vtogcov__ext_uart_avai,
            cpu->rootp->top__DOT____Vtogcov__ext_uart_rx_ready};
    };
    // 注册回调
    cpu.register_beforeCallback(updateFunc);
    cpu.register_afterCallback(updateFunc);
    cpu.register_getGprCallback([&]() {
        std::array<uint32_t, 32> gpr;
        std::copy(
            std::begin(cpu->rootp->top__DOT__U_reg_file__DOT__regfile.m_storage),
            std::end(cpu->rootp->top__DOT__U_reg_file__DOT__regfile.m_storage),
            gpr.begin()
        );
        return gpr;
    });

    cpu.enable_trace("top.vcd");
    cpu.reset_all();

    bool sendFlag = false;
    char sendChar = ' ';
    // 初始化参考实现
    difftest::CpuRefImpl cpuRef{
        LOONG_BIN_PATH,
        LOONG_DBIN_PATH,
        0,
        0,
        true,
        false,
        TRACE_DEEP

    };

    shutdown_handler = [&](int signal) {
        if (cpuRef.isRecording) {
            cpuRef.stop_record();
            cpu.stop_record();
            auto f = fopen("history.ansi", "w");
            forward_compare(cpu, cpuRef, 0, f);
            fclose(f);
            // exit(0);
        }
        exit(0);
    };
    signal(SIGINT, signal_handler);

    // 串口输入模拟线程
    ThreadRaii uart_input_thread{[&]() {
        termios tmp;
        tcgetattr(STDIN_FILENO, &tmp);
        tmp.c_lflag &= (~ICANON & ~ECHO);
        tcsetattr(STDIN_FILENO, TCSANOW, &tmp);
        while (true) {
            char c = getchar();
            print_dbg("[UART] rx: %c", c);
            if (c == 10)
                c = 13; // convert lf to cr

            sendChar = c;
            sendFlag = true;
        }
    }};

    bool   running = true;
    size_t StayCnt = 0;


    auto startTime = std::chrono::high_resolution_clock::now();


    /*=========================================================================*/
    //                               初始化结束
    /*=========================================================================*/

    uint8_t RefUartTxCh  = 0;
    uint8_t PracUartTxCh = 0;
    bool    is_testing   = false;
    while (running) {
        // Prac CPU 步进
        cpu.step();

        serial_scanf(cpu, cpuRef);

        //考虑有效性，当 PC 发生变更，则有效
        if (cpu.lastStatus.pc != cpu.nowStatus.pc) {

            // print_dbg("[Main] PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());

            StayCnt = 0;

            // 参考实现步进
            cpuRef.step();

            // 比较状态
            // if (cpu.lastStatus.pc == 0x00002168) {

            //     compare_extram(cpu, cpuRef);
            //     return 1;
            // }
            if (!compare_status(cpu.recentStatus, cpuRef.recentStatus, cpu)) {
                print_history(cpu, cpuRef);
                // compare_extram(cpu, cpuRef);
                return 1;
                break;
            }
        } else {
            ++StayCnt;
        }


        while (cpuRef.uart.exist_tx()) {
            char c = cpuRef.uart.getc();
            if (c != '\r') {
                RefUartTxCh = c;
                print_d(CTL_LIGHTBLUE, "[REF.UART.TX] " CTL_RESET "Receiving CPU Send: 0x%02X(Ascii: %c)", c, c);
                fflush(stdout);
            }
        }

        while (cpu.exist_tx()) {
            char c = cpu.get_tx_c();
            if (c != '\r') {
                PracUartTxCh = c;
                print_d(CTL_LIGHTBLUE, "[Prac.UART.TX] " CTL_RESET "Receiving CPU Send: 0x%02X(Ascii: %c)", c, c);
                fflush(stdout);
            }
        }

        if (RefUartTxCh == '.' && PracUartTxCh == '.') {

            /*
                80003000 <UTEST_SIMPLE>:
                80003008 <UTEST_STREAM>:
                80003030 <UTEST_MATRIX>:
                800030b4 <UTEST_CRYPTONIGHT>:
            */
            serial_print(cpu, cpuRef, 'G');
            serial_print(cpu, cpuRef, static_cast<uint32_t>(UTEST_SELECT));

            RefUartTxCh  = 0;
            PracUartTxCh = 0;

        } else if (RefUartTxCh == 0x06) {
            print_d(CTL_LIGHTBLUE, "[RunG] " CTL_RESET "Start RunG");
            if (PracUartTxCh != 0x06) {
                print_err("At PracPc = 0x%08X  RefPc = 0x%08X: ", cpu.nowStatus.pc, cpuRef.get_pc());
                print_err("Start mark should be 0x06");
                exit(0);
            }
            RefUartTxCh  = 0;
            PracUartTxCh = 0;

            is_testing = true;
            cpuRef.start_record();
            cpu.start_record();

        } else if (RefUartTxCh == 0x07) {
            if (PracUartTxCh != 0x07) {
                print_err("At PracPc = 0x%08X  RefPc = 0x%08X: ", cpu.nowStatus.pc, cpuRef.get_pc());
                print_err("Prac CPU failed with code 0x07");
            }
            RefUartTxCh  = 0;
            PracUartTxCh = 0;

            is_testing = false;
            if (cpuRef.isRecording) {
                cpuRef.stop_record();
                cpu.stop_record();
                auto f = fopen("history.ansi", "w");
                forward_compare(cpu, cpuRef, 0, f);
                fclose(f);
                // exit(0);
            }
            exit(0);
        }

        // 进度输出
        if (is_testing && UTEST_SELECT == UTEST_STREAM) {
            auto  now    = cpuRef.get_gpr()[4];
            auto  target = cpuRef.get_gpr()[6];
            float per    = ((now - 0x80100000) * 100) * 1.0 / (target - 0x80100000);
            print_d(CTL_LIGHTBLUE, "[RunG UTEST_STREAM] " CTL_RESET "0x%08X of 0x%08X, percent %.1f %%", cpuRef.get_gpr()[4], cpuRef.get_gpr()[6], per);
        }

        if (sendFlag) {
            serial_print(cpu, cpuRef, sendChar);
            sendFlag = false;
        }

        running = !cpuRef.is_finished();

        // if (StayCnt >= 10) {
        //     print_info("Pass the DiffTest!");
        //     cpu.perfTracer.print();
        //     print_ram(cpu, cpuRef);
        //     return 0;
        //     break;
        // }

        auto endTime = std::chrono::high_resolution_clock::now();
        auto during  = std::chrono::duration_cast<std::chrono::seconds>(endTime - startTime).count();

        // if (during > 100) {
        //     print_err("CPU emulation timeout!");
        //     print_ram(cpu, cpuRef);
        //     return 1;
        // }
    }
    print_ram(cpu, cpuRef);
    return 0;
}


TEST_CASE("perf") {
    char argv[] = {"perf"};
    REQUIRE(test_main(0, (char **)argv) == 0);
}