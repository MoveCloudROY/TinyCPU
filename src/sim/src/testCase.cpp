#include "testCase.h"


testCase::testCase(uint8_t opCode, std::vector<int8_t> params) {
    this->opCode = opCode;
    // 根据操作码设置
    switch (opCode) {
    case 0:
        this->op   = "nop";
        this->op1  = 0;
        this->op2  = 0;
        this->res1 = 0;
        this->res2 = 0;
        break;
    case 8:
        this->op   = "add";
        this->op1  = params[0];
        this->op2  = params[1];
        this->res1 = 0;
        this->res2 = params[2];
        break;
    case 4:
        this->op   = "sub";
        this->op1  = params[0];
        this->op2  = params[1];
        this->res1 = 0;
        this->res2 = params[3];
        break;
    case 2:
        this->op   = "mul";
        this->op1  = params[0];
        this->op2  = params[1];
        this->res1 = params[5];
        this->res2 = params[4];
        break;
    case 1:
        this->op   = "div";
        this->op1  = params[0];
        this->op2  = params[1];
        this->res1 = params[6];
        this->res2 = params[7];
        break;
    default:
        this->op = "error";
        break;
    }
}

testCase::~testCase() {
}
