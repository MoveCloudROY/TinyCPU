#pragma once

#include <array>
#include <cstdint>

// 指令PC及提交后状态
struct GeneralStatus {
    uint32_t                 pc;
    std::array<uint32_t, 32> gpr;
};

struct CpuStatus {
    uint32_t pc;
    uint32_t targetAddr;
    uint32_t targetData;
    uint32_t uartTxBusy;
    uint32_t uartRxReady;
    uint32_t uartRxJustReady;
};