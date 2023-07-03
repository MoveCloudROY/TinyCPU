`include "common.vh"

module wb(
    // input          WB_valid,     // 写回级有效
    input  [`MEM2WBBusSize - 1:0] mem2wb_bus_ri, // MEM->WB总线
    output [  4:0] rf_wdest_o,     // 寄存器写地址
    output         rf_wen_o,       // 寄存器写使能
    
    output [ 31:0] rf_wdata_o,     // 寄存器写数据
    // output         WB_over,      // WB模块执行完成

    //5级流水新增接口
    input           clk_i,       // 时钟
    input           rst_i      // 复位信号，低电平有效
    // output [ 32:0]  exc_bus,    // Exception pc总线
    // output [  4:0]  WB_wdest     // WB级要写回寄存器堆的目标地址号
);
    /*==================================================*/
    //                 级间寄存器信号解析
    /*==================================================*/
    //MEM传来的result
    wire [31:0] mem_result;
    
    //寄存器堆写使能和写地址
    wire wen;
    wire [4:0] wdest;
    
    //pc
    wire [31:0] pc;    
    assign {
        wdest,
        wen,
        mem_result,
        pc } = mem2wb_bus_ri;


//-----{WB执行完成}begin
    //WB模块所有操作都可在一拍内完成
    //故WB_valid即是WB_over信号
    // assign WB_over = WB_valid;
//-----{WB执行完成}end

    /*==================================================*/
    //                   写回信号输出
    /*==================================================*/
    assign rf_wen_o   = wen;
    assign rf_wdest_o = wdest;
    assign rf_wdata_o = mem_result;


//-----{WB模块的dest值}begin
   //只有在WB模块有效时，其写回WB_wdest目的寄存器号才有意义
    // assign WB_wdest = rf_wdest & {5{WB_valid}};
//-----{WB模块的dest值}end


endmodule

