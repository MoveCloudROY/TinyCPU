`include "common.vh"


module wb(
    
    output [  4:0] rf_wdest_o /* verilator public_flat */,     // 寄存器写地址
    output         rf_we_o,       // 寄存器写使能
    output [ 31:0] rf_wdata_o /* verilator public_flat */,     // 寄存器写数据

    //5级流水新增接口
    
    input  [`MEM2WBBusSize - 1:0] mem2wb_bus_ri, // MEM->WB总线
    output [`RegW - 1:0]          _occupy_pc_o,  // 占位，避免 warning

    input ctl_wb_valid_i,
    output ctl_wb_over_o,
    output [`RegAddrBusW-1:0] ctl_wb_dest_o
);
    /*==================================================*/
    //                 级间寄存器信号解析
    /*==================================================*/
    //MEM传来的result
    wire [31:0] mem_result;
    
    //寄存器堆写使能和写地址
    wire [4:0] wb_wdest;
    wire wb_we;

    wire [`RegW - 1:0] dbg_dm_addr /* verilator public_flat */; 
    
    //pc
    wire [31:0] pc;    
    assign {
        wb_wdest,
        wb_we,
        mem_result,
        dbg_dm_addr,
        pc } = mem2wb_bus_ri;
        

    /*==================================================*/
    //                   写回信号输出
    /*==================================================*/
    assign rf_we_o   = wb_we & ctl_wb_over_o;
    assign rf_wdest_o = wb_wdest;
    assign rf_wdata_o = mem_result;

    assign _occupy_pc_o = pc;

    /*==================================================*/
    //                控制信号与冒险处理
    /*==================================================*/
    assign ctl_wb_dest_o = rf_wdest_o & {5{ctl_wb_valid_i}};

    assign ctl_wb_over_o = ctl_wb_valid_i;

endmodule

