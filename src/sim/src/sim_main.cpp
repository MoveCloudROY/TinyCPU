#include <cstddef>
#include <cstdint>
#include <iostream>
#include "Vtop.h"
#include "Vtop___024root.h"
#include "verilated.h"
#include "VcdWriter.h"
#include "CpuTracer.h"
#include <memory>
#include <random>
#include <bitset>
using std::bitset;

#define MAX_TEST 1000000


#define U8H(x) (int8_t)((int8_t)((x) >> 4) & 0x0F)
#define U8L(x) (int8_t)((int8_t)(x)&0x0F)
#define BIT(x, n) bitset<(n)>((x)).to_string().c_str()
#define SET_BIT(x, n) (bitset<n>(x))

int main(int argc, char **argv) {
    srand(time(0));

    CpuTracer<Vtop> tp{argc, argv};
    tp.enable_trace("top.vcd");


    tp.reset_all();

    for (int i = 0; i < 260; ++i) {
        tp.step();
    }

    return 0;
}
