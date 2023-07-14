#include "CpuRefImpl.h"
#include "device/uart8250.hpp"
#include <array>
#include <cstdint>
#include <iterator>
#include <memory/ram.hpp>
#include <thread>
#include <termios.h>


namespace difftest {

// static void uart_input(uart8250 &uart) {
//     termios tmp;
//     tcgetattr(STDIN_FILENO, &tmp);
//     tmp.c_lflag &= (~ICANON & ~ECHO);
//     tcsetattr(STDIN_FILENO, TCSANOW, &tmp);
//     while (true) {
//         char c = getchar();
//         if (c == 10)
//             c = 13; // convert lf to cr
//         uart.putc(c);
//     }
// }


CpuRefImpl::CpuRefImpl(std::string path, size_t start_addr, bool device_sim_t, bool trace_t)
    : device_sim{device_sim_t}
    , trace{trace_t}
    , mmio{}
    , confreg{device_sim}
    , core{0, mmio, trace, 0}
    , uart{}
    , mtx{}
    , cv{}
    , uart_input_thread{[&](uartsim &uart) {
                            termios tmp;
                            tcgetattr(STDIN_FILENO, &tmp);
                            tmp.c_lflag &= (~ICANON & ~ECHO);
                            tcsetattr(STDIN_FILENO, TCSANOW, &tmp);
                            while (true) {
                                char c = getchar();
                                if (c == 10)
                                    c = 13; // convert lf to cr
                                uart.putc(c);
                            }
                        },
                        std::ref(uart)} {

    func_mem.load_binary(start_addr, path.c_str());
    func_mem.set_allow_warp(true);

    assert(mmio.add_dev(0x00000000, 0x100000, &func_mem));
    // assert(mmio.add_dev(0x00000000, 0x1000000, &data_mem0));
    assert(mmio.add_dev(0x80000000, 0x1000000, &data_mem1));
    assert(mmio.add_dev(0x90000000, 0x1000000, &data_mem2));
    assert(mmio.add_dev(0xa0000000, 0x1000000, &data_mem1));
    assert(mmio.add_dev(0xc0000000, 0x1000000, &data_mem3));
    assert(mmio.add_dev(0xd0000000, 0x1000000, &data_mem4));
    assert(mmio.add_dev(0xe0000000, 0x1000000, &data_mem5));
    assert(mmio.add_dev(0x1faf0000, 0x10000, &confreg));
    assert(mmio.add_dev(0xbfaf0000, 0x10000, &confreg));
    assert(mmio.add_dev(0xbfd003f8, 0x8, &uart));
}

CpuRefImpl::~CpuRefImpl() {
    uart_input_thread.detach();
}

void CpuRefImpl::operator+=(int step) {
    while (step--)
        core.step();
}

void CpuRefImpl::step() {
    core.step();
}

bool CpuRefImpl::is_finished() {
    return core.is_end();
}

uint32_t CpuRefImpl::get_pc() {
    return core.get_pc();
}

void CpuRefImpl::jump(uint32_t new_pc) {
    return core.jump(new_pc);
}

std::array<uint32_t, 32> CpuRefImpl::get_gpr() {
    std::array<uint32_t, 32> ret;
    std::copy(std::begin(core.GPR), std::end(core.GPR), ret.begin());
    return ret;
}


} // namespace difftest