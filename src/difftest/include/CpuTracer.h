#pragma once

#include <cstdio>
#include <device/uartsim.hpp>
#include <cstddef>
#include <memory>
#include <string>
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Status.h"


namespace difftest {

template <typename T>
class CpuTracer {
public:
    CpuTracer(int argc, char **argv)
        : context{std::make_unique<VerilatedContext>()}
        , beforeCallback{[]() {}}
        , afterCallback{[]() {}} {
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
        beforeCallback();
        context->timeInc(1);
        top->clk_i = 0;
        top->eval();

        if (wave_on)
            tfp->dump(context->time());

        // Repeat for the positive edge of the clock
        context->timeInc(1);
        top->clk_i = 1;
        top->eval();
        if (wave_on)
            tfp->dump(context->time());

        // // Now the negative edge
        // context->timeInc(1);
        // top->clk_i = 0;
        // top->eval();
        // if (wave_on) {
        //     tfp->dump(context->time());
        //     tfp->flush();
        // }
        afterCallback();
    }

    void reset_all() {
        printf("[mycpu] Resetting ...\n");

        top->rst_i = 1;
        for (int i = 0; i < 20; i++) {
            step();
        }

        top->rst_i = 0;
        // top->rxd_i = 1;
        printf("[mycpu] Reset done.\n");
    }

    void register_beforeCallback(std::function<void(void)> beforeCallback_t) {
        beforeCallback = beforeCallback_t;
    }
    void register_afterCallback(std::function<void(void)> afterCallback_t) {
        afterCallback = afterCallback_t;
    }

    T *operator->() {
        return top;
    }

public:
    uartsim uart;
    Status  lastStatus;

private:
    std::unique_ptr<VerilatedContext> context;
    T                                *top;
    std::unique_ptr<VerilatedVcdC>    tfp;
    std::function<void(void)>         beforeCallback;
    std::function<void(void)>         afterCallback;
    bool                              wave_on;
};

} // namespace difftest