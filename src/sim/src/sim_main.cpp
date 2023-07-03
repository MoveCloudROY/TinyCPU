#include <cstddef>
#include <cstdint>
#include <iostream>
#include "Vtop.h"
#include "Vtop___024root.h"
#include "verilated.h"
#include "VcdWriter.h"
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
    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    Vtop *top = new Vtop{contextp};

    VcdWriter vcdWriter("top.vcd", contextp, top, 99);

    int64_t count = 0;

    // reset
    top->clk_i = 0;
    top->rst_i = 1;
    vcdWriter.tick();
    top->clk_i = 1;
    top->rst_i = 1;
    vcdWriter.tick();


    // write start
    top->clk_i = 0;
    top->rst_i = 0;

    top->start_i = 1;
    top->rw_i    = 0;
    top->data_i  = 0x89ABCDEF;
    top->addr_i  = SET_BIT(0x00123456, 20).to_ulong();
    vcdWriter.tick();
    print_info("clk = %d, rw = %d, r_ready_o = %d, w_finish_o = %d, addr= 0x%08X, data_i = 0x%08X, data_o = 0x%08X", top->clk_i, top->rw_i, top->r_ready_o, top->w_finish_o, top->addr_i, top->data_i, top->data_o);


    top->clk_i = 1;
    vcdWriter.tick();
    print_info("clk = %d, rw = %d, r_ready_o = %d, w_finish_o = %d, addr= 0x%08X, data_i = 0x%08X, data_o = 0x%08X", top->clk_i, top->rw_i, top->r_ready_o, top->w_finish_o, top->addr_i, top->data_i, top->data_o);


    top->clk_i = 0;

    top->rw_i   = 0;
    top->data_i = 0x89ABCDEF;
    top->addr_i = SET_BIT(0x00123456, 20).to_ulong();
    vcdWriter.tick();
    print_info("clk = %d, rw = %d, r_ready_o = %d, w_finish_o = %d, addr= 0x%08X, data_i = 0x%08X, data_o = 0x%08X", top->clk_i, top->rw_i, top->r_ready_o, top->w_finish_o, top->addr_i, top->data_i, top->data_o);

    top->clk_i = 1;

    top->rw_i   = 1;
    top->data_i = 0;
    top->addr_i = 0;
    vcdWriter.tick();
    print_info("clk = %d, rw = %d, r_ready_o = %d, w_finish_o = %d, addr= 0x%08X, data_i = 0x%08X, data_o = 0x%08X", top->clk_i, top->rw_i, top->r_ready_o, top->w_finish_o, top->addr_i, top->data_i, top->data_o);
    // write end

    // read start
    top->clk_i = 0;

    top->rw_i   = 1;
    top->addr_i = SET_BIT(0x00123456, 20).to_ulong();
    vcdWriter.tick();
    print_info("clk = %d, rw = %d, r_ready_o = %d, w_finish_o = %d, addr= 0x%08X, data_i = 0x%08X, data_o = 0x%08X", top->clk_i, top->rw_i, top->r_ready_o, top->w_finish_o, top->addr_i, top->data_i, top->data_o);


    top->clk_i = 1;
    vcdWriter.tick();
    print_info("clk = %d, rw = %d, r_ready_o = %d, w_finish_o = %d, addr= 0x%08X, data_i = 0x%08X, data_o = 0x%08X", top->clk_i, top->rw_i, top->r_ready_o, top->w_finish_o, top->addr_i, top->data_i, top->data_o);


    top->clk_i = 0;
    vcdWriter.tick();
    print_info("clk = %d, rw = %d, r_ready_o = %d, w_finish_o = %d, addr= 0x%08X, data_i = 0x%08X, data_o = 0x%08X", top->clk_i, top->rw_i, top->r_ready_o, top->w_finish_o, top->addr_i, top->data_i, top->data_o);

    top->clk_i = 1;
    vcdWriter.tick();
    print_info("clk = %d, rw = %d, r_ready_o = %d, w_finish_o = %d, addr= 0x%08X, data_i = 0x%08X, data_o = 0x%08X", top->clk_i, top->rw_i, top->r_ready_o, top->w_finish_o, top->addr_i, top->data_i, top->data_o);

    top->clk_i = 0;
    vcdWriter.tick();
    print_info("clk = %d, rw = %d, r_ready_o = %d, w_finish_o = %d, addr= 0x%08X, data_i = 0x%08X, data_o = 0x%08X", top->clk_i, top->rw_i, top->r_ready_o, top->w_finish_o, top->addr_i, top->data_i, top->data_o);

    // while (!contextp->gotFinish() && count < MAX_TEST) {
    // }

    delete top;
    delete contextp;
    return 0;
}
