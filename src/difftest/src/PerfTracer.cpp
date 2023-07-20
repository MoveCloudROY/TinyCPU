#include "PerfTracer.h"
#include "tools.h"

namespace difftest {

void PerfTracer::tick(bool submit, uint32_t inst, bool right) {
    ++clkCnt;
    if (submit) {
        ++instCnt;
    } else {
        ++frontEndJamCnt;
    }
}

void PerfTracer::print() {
    print_d(CTL_ORIANGE, "===============================================================================" CTL_RESET);

    print_info("Performance Report");
    print_d(CTL_ORIANGE, "clkCnt:" CTL_RESET "\t\t%lu\t\t" CTL_ORIANGE "instCnt: " CTL_RESET "%lu", clkCnt, instCnt);
    print_d(CTL_ORIANGE, "frontEndJamCnt:" CTL_RESET "\t%lu\t", frontEndJamCnt);
    print_d(CTL_ORIANGE, "IPC:" CTL_RESET "\t\t%f", static_cast<double>(instCnt) / clkCnt);
}


} // namespace difftest