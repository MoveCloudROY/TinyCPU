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

// clang-format off
#define print_err(fmt, args...) printf("\033[31;1m" fmt "\033[0m\n", ##args)
#define print_info(fmt, args...) printf("\033[33;1m" fmt "\033[0m\n", ##args)
#define debug(fmt, args...) printf("\033[32;1m" "[DEBUG] %s:%d:%s" "\033[0m  "  fmt "\n", __FILE_NAME__, __LINE__, __func__, ##args)
// clang-format on

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


    // print_info("PC = 0x%08X, data_i = 0x%08X, data_o = 0x%08X", top->rw_i, top->r_ready_o, top->w_finish_o, top->addr_i, top->data_i, top->data_o);


    // top->clk_i = 1;

    // while (!contextp->gotFinish() && count < MAX_TEST) {
    // }

    // delete top;
    // delete contextp;
    return 0;
}
