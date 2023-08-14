#pragma once

#include <array>
#include <cstdint>
#include <cstdio>
#include <device/uartsim.hpp>
#include <cstddef>
#include <memory>
#include <string>
#include <functional>
#include "defines.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Structs.h"
#include "PerfTracer.h"


namespace difftest {

template <typename T, typename TStatus>
class CpuTracer {
public:
    CpuTracer(int argc, char **argv, size_t historySize = 5)
        : context{std::make_unique<VerilatedContext>()}
        , historySize{historySize} {
        context->commandArgs(argc, argv);
        top = new T{context.get()};
    }
    ~CpuTracer() {
        if (wave_on) {
            tfp->close();
        }
        delete top;
    }

    void enable_trace(const std::string &path, std::size_t dep = 99) {
        if (wave_on)
            return;
        wave_on = true;
        Verilated::traceEverOn(true);
        tfp = std::make_unique<VerilatedVcdC>();
        top->trace(tfp.get(), dep); // Trace 99 levels of hierarchy (or see below)
        tfp->open(path.c_str());
    }

    void tick() {
        context->timeInc(1);
        top->eval();
        if (wave_on) {
            tfp->dump(context->time());
            tfp->flush();
        }
    }
    void step() {
        lastStatus = beforeCallback();
        context->timeInc(1);
        top->clk_i = 0;
        top->eval();

        if (wave_on)
            tfp->dump(context->time());

        // Repeat for the positive edge of the clock
        context->timeInc(1);
        top->clk_i = 1;
        top->eval();
        if (wave_on) {
            tfp->dump(context->time());
            tfp->flush();
        }

        update_tx(top->txd_o, top->rootp->top__DOT__ext_uart_t__DOT__BitTick);
        nowStatus = afterCallback();

        perfTracer.tick(lastStatus.pc != nowStatus.pc);

        if (lastStatus.pc != nowStatus.pc) {
            recentStatus = GeneralStatus{lastStatus.pc, getGprCallback()};
            history.push(recentStatus);
            if (history.size() > historySize)
                history.pop();
            if (isRecording)
                record.push(recentStatus);
        }
    }

    void reset_all() {
        printf("[mycpu] Resetting ...\n");

        top->rst_i = 1;
        for (int i = 0; i < 20; i++) {
            step();
        }

        top->rst_i = 0;
        top->rxd_i = 1;
        printf("[mycpu] Reset done.\n");
    }

    void register_beforeCallback(std::function<TStatus(void)> beforeCallback_t) {
        beforeCallback = beforeCallback_t;
    }
    void register_afterCallback(std::function<TStatus(void)> afterCallback_t) {
        afterCallback = afterCallback_t;
    }
    void register_getGprCallback(std::function<std::array<uint32_t, 32>(void)> getGprCallback_t) {
        getGprCallback = getGprCallback_t;
    }

    bool exist_tx() {
        return !txBuf.empty();
    }

    char get_tx_c() {
        if (!txBuf.empty()) {
            char res = txBuf.front();
            txBuf.pop();
            return res;
        } else
            return EOF;
    }

    void sleep(size_t cycles) {
        while (cycles--)
            step();
    }

    void start_record() {
        print_d(CTL_PUP, "[prac CPU Record] Start Record " CTL_RESET);
        isRecording = 1;
        while (!record.empty())
            record.pop();
    }
    void stop_record() {
        isRecording = 0;
        print_d(CTL_PUP, "[Prac CPU Record] Stop Record " CTL_RESET);
    }

    auto get_gpr() {
        return getGprCallback();
    }

    void operator+=(int step) {
        sleep(step);
    }

    T *operator->() {
        return top;
    }

private:
    void update_tx(char txd, bool uartPulse) {
        static int state = 0;
        // state : start<0>(1bit) --> data<...>(8bit) --> stop<1>(1bit)

        if (!uartPulse)
            return;

        txd = txd & 0x01;
        switch (state) {
        case 0: {
            if (txd == 0) {
                txTerm = 0;
                state += 1;
            }
            break;
        }
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
        case 8: {
            txTerm |= (txd << (state - 1));
            state += 1;
            break;
        }
        case 9: {
            if (txd == 1) {
                txBuf.push(txTerm);
                state = 0;
            }
            break;
        }
        }
    }


public:
    TStatus                   lastStatus{}, nowStatus{};
    char                      txTerm;
    std::queue<char>          txBuf;
    GeneralStatus             recentStatus;
    std::queue<GeneralStatus> history;
    difftest::PerfTracer      perfTracer;

    std::queue<GeneralStatus> record;
    bool                      isRecording;

private:
    std::unique_ptr<VerilatedContext>             context;
    T                                            *top;
    std::unique_ptr<VerilatedVcdC>                tfp;
    std::function<TStatus(void)>                  beforeCallback;
    std::function<TStatus(void)>                  afterCallback;
    std::function<std::array<uint32_t, 32>(void)> getGprCallback;
    bool                                          wave_on;

    size_t historySize;
};

} // namespace difftest