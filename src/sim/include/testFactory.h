#pragma once
#include <stdlib.h>
#include <vector>

#include "testCase.h"

#define SET_4BIT(x) ((x)&0x0F)

// 用于生成加减乘除四则运算的测试用例
// 有4个public方法: genAddTest, genSubTest, genMulTest, genDivTest
// 每个方法内部随机生成两个操作数, 并计算出正确的结果
// 每个操作数为4位的有符号数, 可以使用int8存储
// genAddTest方法中, 生成两个结果, 一个为和, 一个为进位
// genSubTest方法中, 生成两个结果, 一个为差, 一个为借位
// genMulTest方法中, 生成两个结果, 一个为积的高位, 一个为积的低位
// genDivTest方法中, 生成两个结果, 一个为商, 一个为余数
// 所有方法的生成结果均为int8, 但只有低4位有效, 高4位为0;
// 这4个方法返回一个vector, 第一个元素为操作数1, 第二个元素为操作数2, 第三个元素为正确的结果
class testFactory {
private:
    /* data */
public:
    testFactory(/* args */);
    ~testFactory();
    std::vector<int8_t> genAddTest();
    std::vector<int8_t> genAddTest(int a, int b);
    std::vector<int8_t> genSubTest();
    std::vector<int8_t> genMulTest();
    testCase            genDivTest();
    testCase            genRandomTest(bool no);
};
