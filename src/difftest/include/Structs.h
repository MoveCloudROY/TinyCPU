#pragma once

#include <array>
#include <cstdint>

// 指令PC及提交后状态
struct GeneralStatus {
    uint32_t                 pc;
    std::array<uint32_t, 32> gpr;
};