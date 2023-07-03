#pragma once

#include <cstddef>
#include <string>
#include "verilated.h"
#include "verilated_vcd_c.h"

template <typename T>
class VcdWriter {
public:
    VcdWriter(const std::string &path, VerilatedContext *context, T *module, std::size_t dep)
        : context{context}
        , module{module}
        , tfp{new VerilatedVcdC} {
        // create VCD wave
        Verilated::traceEverOn(true);
        module->trace(tfp, dep); // Trace 99 levels of hierarchy (or see below)
        tfp->open(path.c_str());
    }
    ~VcdWriter() {
        tfp->close();
        delete tfp;
    }
    void tick() {
        context->timeInc(1);
        module->eval();
        tfp->dump(context->time());
    }

private:
    VerilatedContext *context;
    T                *module;
    VerilatedVcdC    *tfp;
};