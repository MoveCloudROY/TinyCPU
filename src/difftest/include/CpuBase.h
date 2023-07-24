#pragma once

#include "Structs.h"
#include <cstdint>
#include <queue>

namespace difftest {


class CpuBase {

public:
    virtual void start_record()  = 0;
    virtual void stop_record()   = 0;
    virtual void step()          = 0;
    virtual void operator+=(int) = 0;

public:
    GeneralStatus             recentStatus;
    std::queue<GeneralStatus> history;
    std::queue<GeneralStatus> record;

private:
    std::size_t historySize;
    bool        isRecording;
};

} // namespace difftest