#include "CpuRefImpl.h"
#include "device/uart8250.hpp"
#include <array>
#include <cstdint>
#include <iterator>
#include <memory/ram.hpp>
#include <thread>
#include <termios.h>


namespace difftest {


CpuRefImpl::CpuRefImpl(std::string cpath, std::string dpath, size_t cstart_addr, size_t dstart_addr, bool device_sim_t, bool trace_t, size_t historySize)
    : device_sim{device_sim_t}
    , trace{trace_t}
    , mmio{}
    , confreg{device_sim}
    , core{0, mmio, trace, 0}
    , uart{}
    , historySize{historySize} {

    func_mem.load_binary(cstart_addr, cpath.c_str());
    func_mem.set_allow_warp(true);
    if (dpath != "")
        data_mem1.load_binary(0x0400000 + dstart_addr, dpath.c_str());

    assert(mmio.add_dev(0x00000000, 0x1000000, &func_mem));
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
}

void CpuRefImpl::operator+=(int step) {
    while (step--)
        core.step();
}

void CpuRefImpl::step() {
    auto refLastPc = get_pc();
    core.step();
    recentStatus = GeneralStatus{refLastPc, get_gpr()};
    history.push(recentStatus);
    if (history.size() > historySize)
        history.pop();
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

uint32_t CpuRefImpl::get_inst() {
    return core.instr.dbg_inst;
}

} // namespace difftest