`include "common.vh"
module mem1(

    input      [`MEM02MEM1BusSize - 1:0] mem02mem1_bus_ri,    // EXE->MEM总线
    output     [`MEM12MEM2BusSize - 1:0] mem12mem2_bus_o,     // MEM->WB总线

    input                       ctl_mem1_valid_i,
    output                      ctl_mem1_over_o,
    output [`RegAddrBusW-1:0]   ctl_mem1_dest_o,
    output [`RegW - 1: 0]       ctl_mem1_pc_o,
    output                      ctl_mem1_ls_o
);
    /*==================================================*/
    //                 级间寄存器信号解析
    /*==================================================*/
    //访存需要用到的load/store信息
    wire [5 :0] mem_control;  //MEM需要使用的控制信号
    
    //EXE结果
    wire [`RegW - 1:0] exe_result;
    
    //写回需要用到的信息
    wire [4:0] wb_wdest;  //写回的目的寄存器
    wire       wb_we;    //写回的寄存器写使能
    
    
    //pc
    `NO_TOUCH wire [`RegW - 1:0] pc;

    assign {
        mem_control,
        exe_result,
        wb_wdest,
        wb_we,
        pc 
    } = mem02mem1_bus_ri;  

    /*==================================================*/
    //                 load/store访存
    /*==================================================*/
    /*
        TODO: 
        自然对齐是指,访问半字对象时地址是 2 字节边界对齐,
        访问字对象时地址是 4 字节边界对齐,访问双字对象时地址是 8 字节边界对齐...
    */

    wire        inst_load;      // load操作
    wire        inst_store;     // store操作
    wire        ld_bh_sign;     // load一字节为有符号load
    wire [2:0]  ld_st_size;     // load/store为 4:byte;2:halfword;1:word

    assign {inst_load,inst_store,ld_bh_sign,ld_st_size} = mem_control;


    /*==================================================*/
    //              下级所需数据/总线生成
    /*==================================================*/
    
    assign mem12mem2_bus_o = mem02mem1_bus_ri;                           

    /*==================================================*/
    //                控制信号与冒险处理
    /*==================================================*/
    assign ctl_mem1_dest_o = wb_wdest & {5{ctl_mem1_valid_i}};

    assign ctl_mem1_over_o = ctl_mem1_valid_i;

    assign ctl_mem1_pc_o = pc;

    assign ctl_mem1_ls_o = inst_load | inst_store;

endmodule