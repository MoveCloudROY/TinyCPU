#pragma once

#include <array>
#include <cstdint>
#include <string>
#include <device/nscscc_confreg.hpp>
#include <device/uartsim.hpp>
#include <memory/memory_bus.hpp>
#include <memory/ram.hpp>
#include <core/la32r/la32r_core.hpp>
#include <thread>
#include <condition_variable>
#include <csignal>

namespace difftest {

class CpuRefImpl {
public:
    CpuRefImpl(std::string path, size_t start_addr = 0, bool device_sim = true, bool trace = true);
    ~CpuRefImpl();

    void operator+=(int step);

    void step();

    bool is_finished();

    uint32_t get_pc();

    void jump(uint32_t new_pc);

    std::array<uint32_t, 32> get_gpr();


private:
public:
    bool           device_sim;
    bool           trace;
    memory_bus     mmio;
    nscscc_confreg confreg;
    la32r_core<32> core;
    uartsim        uart;

    std::mutex              mtx;
    std::condition_variable cv;
    std::thread             uart_input_thread;


    ram func_mem{1024 * 1024};
    ram data_mem0{0x1000000};
    ram data_mem1{0x1000000};
    ram data_mem2{0x1000000};
    ram data_mem3{0x1000000};
    ram data_mem4{0x1000000};
    ram data_mem5{0x1000000};

private:
};


} // namespace difftest
