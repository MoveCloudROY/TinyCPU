#pragma once

#include <cstdio>
#include <device/uartsim.hpp>
#include <cstddef>
#include <memory>
#include <string>
#include <functional>
#include "verilated.h"
#include "verilated_vcd_c.h"


namespace difftest {

template <typename T, typename TStatus>
class CpuTracer {
public:
    CpuTracer(int argc, char **argv)
        : context{std::make_unique<VerilatedContext>()} {
        context->commandArgs(argc, argv);
        top = new T{context.get()};
    }
    ~CpuTracer() {
        tfp->close();
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

        // // Now the negative edge
        // context->timeInc(1);
        // top->clk_i = 0;
        // top->eval();
        // if (wave_on) {
        //     tfp->dump(context->time());
        //     tfp->flush();
        // }
        update_tx(top->txd_o);
        nowStatus = afterCallback();
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


    T *
    operator->() {
        return top;
    }

private:
    void update_tx(char txd) {
        static int state = 0;
        // state : start<0>(1bit) --> data<...>(8bit) --> stop<1>(1bit)

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
    TStatus          lastStatus{}, nowStatus{};
    char             txTerm;
    std::queue<char> txBuf;


private:
    std::unique_ptr<VerilatedContext> context;
    T                                *top;
    std::unique_ptr<VerilatedVcdC>    tfp;
    std::function<TStatus(void)>      beforeCallback;
    std::function<TStatus(void)>      afterCallback;
    bool                              wave_on;
};

} // namespace difftest