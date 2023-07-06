`include "common.vh"
module tb (
    input clk_i,
    input rst_i,
    

    // 启动信号
    input start_i,
    // 选择读(1)写(0) 
    input rw_i,
    // 数据读写 from CPU 
    input [31:0] data_i,
	output [31:0] data_o,
    // 地址 from CPU
    input [23:0] addr_i,
    
    // 读-数据 就位
    output reg r_ready_o,
    // 写-数据 完成
    output reg w_finish_o,
    // 工作中
    output reg busy_o
    
    // inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    // output wire[19:0] base_ram_addr, //BaseRAM地址
    // output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    // output wire base_ram_ce_n,       //BaseRAM片选，低有效
    // output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    // output wire base_ram_we_n       //BaseRAM写使能，低有效

);
    wire[31:0] w_ram_data;
    wire[19:0] w_ram_addr;
    wire[3:0] w_ram_be_n;
    wire w_ram_ce_n;
    wire w_ram_oe_n;
    wire w_ram_we_n;


`ifdef VERILATOR
    async_ram U_sram_1(
        .clk(clk_i),
        .we_n(w_ram_we_n && !w_ram_oe_n), 
        .web_n(w_ram_be_n[1:0]),
        .addr(w_ram_addr),
        .wdata(w_ram_data[15:0]),
        .rdata(w_ram_data[15:0])
    );

    async_ram U_sram_2(
        .clk(clk_i),
        .we_n(w_ram_we_n && !w_ram_oe_n), 
        .web_n(w_ram_be_n[3:2]),
        .addr(w_ram_addr),
        .wdata(w_ram_data[31:16]),
        .rdata(w_ram_data[31:16])
    );
`else
    // sram_model U_sram_1(
    //     .Address(w_ram_addr),
    //     .DataIO(w_ram_data[15:0]),
    //     .OE_n(w_ram_oe_n),
    //     .CE_n(w_ram_ce_n),
    //     .WE_n(w_ram_we_n),
    //     .LB_n(w_ram_be_n[0]),
    //     .UB_n(w_ram_be_n[1])
    // );

    // sram_model U_sram_2(
    //     .Address(w_ram_addr),
    //     .DataIO(w_ram_data[31:16]),
    //     .OE_n(w_ram_oe_n),
    //     .CE_n(w_ram_ce_n),
    //     .WE_n(w_ram_we_n),
    //     .LB_n(w_ram_be_n[2]),
    //     .UB_n(w_ram_be_n[3])
    // );
`endif
    sram_ctl U_sram_ctl(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .start_i(start_i),
        .rw_i(rw_i),
        .data_i(data_i),
        .data_be_i(4'd0),
        .data_o(data_o),
        .addr_i(addr_i),
        .r_ready_o(r_ready_o),
        .w_finish_o(w_finish_o),
        .busy_o(busy_o),

        .base_ram_data(w_ram_data), 
        .base_ram_addr(w_ram_addr),
        .base_ram_be_n(w_ram_be_n), 
        .base_ram_ce_n(w_ram_ce_n),      
        .base_ram_oe_n(w_ram_oe_n),      
        .base_ram_we_n(w_ram_we_n)       

    );
endmodule