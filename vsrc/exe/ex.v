`include "common.vh"

module ex(
    // input              EXE_valid,    // 执行级有效信号
    // input      [166:0] ID_EXE_bus_r, // ID->EXE总线
    // output             EXE_over,     // EXE模块执行完成

    input  [`ID2EXBusSize - 1:0]    id2ex_bus_ri,
    output [`EX2MEMBusSize - 1:0]   ex2mem_bus_o,

    input ctl_ex_valid_i,
    output ctl_ex_over_o,
    output [`RegAddrBusW-1:0] ctl_ex_dest_o,
    output [`RegW - 1: 0] ctl_ex_pc_o

    
    //5级流水新增
    // input              clk,       // 时钟
    // output     [  4:0] EXE_wdest,   // EXE级要写回寄存器堆的目标地址号
);
    /*==================================================*/
    //                 级间寄存器信号解析
    /*==================================================*/
    wire [11:0] id_aluop;
    wire [`RegW - 1:0] id_rj;
    wire [`RegW - 1:0] id_rk;
    wire [5:0] id_mem_ctl;
    wire [`RegW - 1:0] id_mem_st_data;
    wire [`RegAddrBusW-1:0] id_wb_rd_addr;
    wire id_wb_rd_we;
    wire [`RegW - 1:0] pc;
    assign {
        id_aluop,
        id_rj,
        id_rk,
        id_mem_ctl,
        id_mem_st_data,
        id_wb_rd_addr,
        id_wb_rd_we,
        pc  } = id2ex_bus_ri;

    /*==================================================*/
    //                      ALU
    /*==================================================*/

    wire [31:0] alu_result;


    /*================================*/
    // +- << >> >>(a) < <(u) & | ~ ^ 
    /*================================*/
    alu alu_module(
        .alu_control  (id_aluop     ),  // I, 12, ALU控制信号
        .alu_rj       (id_rj        ),  // I, 32, ALU操作数1
        .alu_rk       (id_rk        ),  // I, 32, ALU操作数2
        .alu_result   (alu_result   )   // O, 32, ALU结果
    );


    /*================================*/
    //               *
    /*================================*/
    // wire        mult_begin; 
    // wire [63:0] product; 
    // wire        mult_end;
    
    // // assign mult_begin = multiply & EXE_valid;
    // multiply multiply_module (
    //     .clk       (clk       ),
    //     .mult_begin(mult_begin  ),
    //     .mult_op1  (alu_operand1), 
    //     .mult_op2  (alu_operand2),
    //     .product   (product   ),
    //     .mult_end  (mult_end  )
    // );




    /*==================================================*/
    //              下级所需数据/总线生成
    /*==================================================*/
    wire [31:0] exe_result;   //在exe级能确定的最终写回结果
    // wire [31:0] lo_result;
    // wire        hi_write;
    // wire        lo_write;
    //要写入HI的值放在exe_result里，包括MULT和MTHI指令,
    //要写入LO的值放在lo_result里，包括MULT和MTLO指令,
    assign exe_result = alu_result;

    assign ex2mem_bus_o = {
        // MEM 需要的信号
        id_mem_ctl, id_mem_st_data, // load/store信息和store数据
        exe_result,                 // exe运算结果
        // WB 需要的信号
        id_wb_rd_addr,              // 写回的目的寄存器
        id_wb_rd_we,                // 写回的寄存器写使能
        pc};                        // PC

    /*==================================================*/
    //                控制信号与冒险处理
    /*==================================================*/
    //对于ALU操作，都是1拍可完成，
    //但对于乘法操作，需要多拍完成
    assign ctl_ex_over_o = ctl_ex_valid_i /* & (~multiply | mult_end) */ ;

    //只有在EXE模块有效时，其写回目的寄存器号才有意义
    assign ctl_ex_dest_o = id_wb_rd_addr & {5{ctl_ex_valid_i}};

    assign ctl_ex_pc_o = pc;


endmodule
