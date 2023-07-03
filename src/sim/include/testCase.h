#pragma once
#include <cstdint>
#include <stdlib.h>
#include <string>
#include <vector>


#define PER_ENUM_STR(x) \
    case OP_ENUM::x: return #x;

enum class OP_ENUM {
    ADD = 8,
    SUB = 4,
    MUL = 2,
    DIV = 1,
    NOP = 0
};

inline std::string getOpName(int8_t x) {
    switch (OP_ENUM(x)) {
        PER_ENUM_STR(ADD)
        PER_ENUM_STR(SUB)
        PER_ENUM_STR(MUL)
        PER_ENUM_STR(DIV)
        PER_ENUM_STR(NOP)
    }
}


// 表示一个测试用例的类
// 公共成员变量: 操作符, 操作码, 操作数1, 操作数2, 正确的结果1, 正确的结果2
// 操作符为string类型, 可以是"add", "sub", "mul", "div"
// 操作码为4位的无符号数, 可以使用uint8_t存储, 0表示空操作, 8表示加法, 4表示减法, 2表示乘法, 1表示除法
// 操作数1和操作数2为4位的有符号数, 可以使用int8存储
// 正确的结果1和正确的结果2为4位的有符号数, 可以使用int8存储
// 每个成员变量的低4位有效, 高4位为0
class testCase {
private:
    /* data */
public:
    std::string op; // 操作符
    uint8_t     opCode;
    int8_t      op1;
    int8_t      op2;
    int8_t      res1; // 加法, 减法的结果; 乘法的低位, 除法的商
    int8_t      res2; // 乘法的高位, 除法的余数

    testCase(uint8_t opCode, std::vector<int8_t> params);
    ~testCase();
};