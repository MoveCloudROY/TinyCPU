`timescale 1 ns/1 ps


/*==============================================*/
//                    ABI 相关
/*==============================================*/
`define LOONG_PC_START_ADDR   32'h1c000000


/*==============================================*/
//                  机器字长相关
/*==============================================*/
`define InstLen 32          //指令长度
`define InstAddrBusW 32     //ROM的地址总线宽度
`define InstDataBusW 32     //ROM的数据总线宽度 
`define InstMemSize 131071  //ROM的实际大小为128KB
`define InstMemSizeLog2 17  //ROM实际使用的地址线宽度

`define RegAddrBusW 5       //Regfile模块的地址线宽度
`define RegDataBusW 32      //Regfile模块的数据线宽度
`define RegW 32             //通用寄存器的宽度
`define DoubleRegW 64       //两倍的通用寄存器的宽度
`define DoubleRegBus 64     //两倍的通用寄存器的数据线宽度
`define RegNum 32           //通用寄存器的数量
`define RegNumLog2 5        //寻址通用寄存器使用的地址位数
`define NOPRegAddr 5'b00000 

/*==============================================*/
//                级间寄存器相关
/*==============================================*/
`define IF2IDBusSize        (3 * `RegW)
`define ID2EXBusSize        (12 + 2 * `RegW + 6 + `RegW + `RegAddrBusW + 1 + `RegW)
`define EX2MEMBusSize       (6 + `RegW + `RegW + `RegAddrBusW + 1 + `RegW)
`define MEM2WBBusSize       (5 + 1 + `RegW + `RegW)


/*==============================================*/
//                   指令相关
/*==============================================*/
// OPCODE.length == 22
`define INST_RDTIMEL_W 22'b11000
`define INST_RDTIMEH_W 22'b11001
`define INST_TLBSRCH   22'b11001001000001010
`define INST_TLBRD     22'b11001001000001011
`define INST_TLBWR     22'b11001001000001100
`define INST_TLBFILL   22'b11001001000001101
`define INST_ERTN      22'b11001001000001110
// OPCODE.length == 17
`define INST_ADD_W     17'b100000
`define INST_SUB_W     17'b100010
`define INST_SLT       17'b100100
`define INST_SLTU      17'b100101
`define INST_NOR       17'b101000
`define INST_AND       17'b101001
`define INST_OR        17'b101010
`define INST_XOR       17'b101011
`define INST_SLL_W     17'b101110
`define INST_SRL_W     17'b101111
`define INST_SRA_W     17'b110000
`define INST_MUL_W     17'b111000
`define INST_MULH_W    17'b111001
`define INST_MULH_WU   17'b111010
`define INST_DIV_W     17'b1000000
`define INST_MOD_W     17'b1000001
`define INST_DIV_WU    17'b1000010
`define INST_MOD_WU    17'b1000011
`define INST_BREAK     17'b1010100
`define INST_SYSCALL   17'b1010110
`define INST_SLLI_W    17'b10000001
`define INST_SRLI_W    17'b10001001
`define INST_SRAI_W    17'b10010001
`define INST_IDLE      17'b110010010001
`define INST_INVTLB    17'b110010010011
`define INST_DBAR      17'b111000011100100
`define INST_IBAR      17'b111000011100101
// OPCODE.length == 10
`define INST_SLTI      10'b1000
`define INST_SLTUI     10'b1001
`define INST_ADDI_W    10'b1010
`define INST_ANDI      10'b1101
`define INST_ORI       10'b1110
`define INST_XORI      10'b1111
`define INST_CACOP     10'b11000
`define INST_LD_B      10'b10100000
`define INST_LD_H      10'b10100001
`define INST_LD_W      10'b10100010
`define INST_ST_B      10'b10100100
`define INST_ST_H      10'b10100101
`define INST_ST_W      10'b10100110
`define INST_LD_BU     10'b10101000
`define INST_LD_HU     10'b10101001
`define INST_PRELD     10'b10101011
// OPCODE.length == 8
`define INST_CSR       8'b100
`define INST_LL_W      8'b100000
`define INST_SC_W      8'b100001
// OPCODE.length == 7
`define INST_LU12I_W   7'b1010
`define INST_PCADDU12I 7'b1110
// OPCODE.length == 6
`define INST_JIRL      6'b10011
`define INST_B         6'b10100
`define INST_BL        6'b10101
`define INST_BEQ       6'b10110
`define INST_BNE       6'b10111
`define INST_BLT       6'b11000
`define INST_BGE       6'b11001
`define INST_BLTU      6'b11010
`define INST_BGEU      6'b11011