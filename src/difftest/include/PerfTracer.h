#pragma once

#include <cstddef>
#include <cstdint>
namespace difftest {

class PerfTracer {
public:
    void tick(bool submit = 0, uint32_t inst = 0, bool right = true);
    void print();

public:
    std::size_t clkCnt         = 0;
    std::size_t instCnt        = 0;
    std::size_t jmpCnt         = 0;
    std::size_t jmpPredErrCnt  = 0;
    std::size_t loadCnt        = 0;
    std::size_t storeCnt       = 0;
    std::size_t frontEndJamCnt = 0;
    std::size_t backEndJamCnt  = 0;
};


} // namespace difftest


/*


时钟周期数

提交指令数

brq返回分支指令数

brq返回预测错误分支指令数

一级数据Cache访问次数

一级数据Cache缺失次数

victim_cache访问次数

victim_cache缺失次数

三级Cache访问次数

三级Cache缺失次数

返回条件跳转类分支指令数

brq返回条件跳转类错误预测分支指令数

处理器提交load指令数

处理器提交store指令数

提交阻塞周期数

前端阻塞周期数

后端阻塞周期数

定点发射队列阻塞周期数

访存发射队列阻塞周期数


*/