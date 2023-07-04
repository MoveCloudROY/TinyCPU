`include "common.vh"
module top (
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
    wire[31:0] w_rom_data;
    wire[19:0] w_rom_addr;
    wire[3:0] w_rom_be_n;
    wire w_rom_ce_n;
    wire w_rom_oe_n;
    wire w_rom_we_n;

    wire[31:0] w_ram_data;
    wire[19:0] w_ram_addr;
    wire[3:0] w_ram_be_n;
    wire w_ram_ce_n;
    wire w_ram_oe_n;
    wire w_ram_we_n;
    // //5模块的valid信号
    // reg IF_valid;
    // reg ID_valid;
    // reg EXE_valid;
    // reg MEM_valid;
    // reg WB_valid;
    // //5模块执行完成信号,来自各模块的输出
    // wire IF_over;
    // wire ID_over;
    // wire EXE_over;
    // wire MEM_over;
    // wire WB_over;
    // //5模块允许下一级指令进入
    // wire IF_allow_in;
    // wire ID_allow_in;
    // wire EXE_allow_in;
    // wire MEM_allow_in;
    // wire WB_allow_in;

    // //各级允许进入信号:本级无效，或本级执行完成且下级允许进入
    // assign IF_allow_in  = IF_over & ID_allow_in;
    // assign ID_allow_in  = ~ID_valid  | (ID_over  & EXE_allow_in);
    // assign EXE_allow_in = ~EXE_valid | (EXE_over & MEM_allow_in);
    // assign MEM_allow_in = ~MEM_valid | (MEM_over & WB_allow_in );
    // assign WB_allow_in  = ~WB_valid  | WB_over;

    wire [32:0] jbr_bus_c;
    wire [`RegW-1:0] if_pc_c;
    wire [`RegW-1:0] if_inst_c;

    wire [`RegW-1:0] rj_data_c;
    wire [`RegW-1:0] rk_data_c;
    wire [`RegAddrBusW-1:0] rj_addr_c;
    wire [`RegAddrBusW-1:0] rk_addr_c;

    wire [ 31:0] dm_rdata_c;
    wire [ 31:0] dm_addr_c;
    wire [  3:0] dm_wbe_n_c;
    wire [ 31:0] dm_wdata_c;
    wire         dm_rw_c;


    wire [  4:0] rf_wdest_c;
    wire           rf_wen_c;
    wire [ 31:0] rf_wdata_c;

    wire [`IF2IDBusSize - 1:0]  if2id_bus_r;
    wire [`ID2EXBusSize - 1:0]  id2ex_bus_c;
    wire [`ID2EXBusSize - 1:0]  id2ex_bus_r;
    wire [`EX2MEMBusSize - 1 :0] ex2mem_bus_c;
    wire [`EX2MEMBusSize - 1 :0] ex2mem_bus_r;
    wire [`MEM2WBBusSize - 1 :0] mem2wb_bus_c;
    wire [`MEM2WBBusSize - 1 :0] mem2wb_bus_r;


    //-------------------------{各模块实例化}begin---------------------------//
    /*================================*/
    //               IF
    /*================================*/
    pc_reg U_pc_reg(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .jbr_bus_i(jbr_bus_c),
        .if_pc_o(if_pc_c)
    );

    if_id U_if2id(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .if_pc_i(if_pc_c),
        .if_inst_i(if_inst_c),
        .if2id_bus_ro(if2id_bus_r)
    );

    /*================================*/
    //              ID
    /*================================*/

    id U_id(
        .rj_data_i(rj_data_c),
        .rk_data_i(rk_data_c),
        .rj_addr_o(rj_addr_c),
        .rk_addr_o(rk_addr_c),
        .jbr_bus_o(jbr_bus_c),
        .if2id_bus_ri(if2id_bus_r),
        .id2ex_bus_o(id2ex_bus_c)
    );

    regfile U_reg_file(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .raddr1_i(rj_addr_c),
        .raddr2_i(rk_addr_c),
        .waddr_i(rf_wdest_c),
        .wdata_i(rf_wdata_c),
        .rdata1_o(rj_data_c),
        .rdata2_o(rk_data_c)
    );

    id_ex U_id2ex(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .id2ex_bus_i(id2ex_bus_c),
        .id2ex_bus_ro(id2ex_bus_r)
    );

    /*================================*/
    //               EXE
    /*================================*/

    ex U_ex(
        .id2ex_bus_ri(id2ex_bus_r),
        .ex2mem_bus_o(ex2mem_bus_c)
    );

    ex_mem U_ex2mem(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .ex2mem_bus_i(ex2mem_bus_c),
        .ex2mem_bus_ro(ex2mem_bus_r)
    );

    /*================================*/
    //               MEM
    /*================================*/
    mem U_mem(
        .dm_rdata_i(dm_rdata_c),
        .dm_addr_o(dm_addr_c),
        .dm_wbe_n_o(dm_wbe_n_c),
        .dm_wdata_o(dm_wdata_c),
        .dm_rw_o(dm_rw_c),
        .ex2mem_bus_ri(ex2mem_bus_r),
        .mem2wb_bus_o(mem2wb_bus_c)
    );

    mem_wb U_mem2wb(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .mem2wb_bus_i(mem2wb_bus_c),
        .mem2wb_bus_ro(mem2wb_bus_r)
    );

    /*================================*/
    //               WB
    /*================================*/

    wb U_wb(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .rf_wdest_o(rf_wdest_c),
        .rf_wen_o(rf_wen_c),
        .rf_wdata_o(rf_wdata_c),
        .mem2wb_bus_ri(mem2wb_bus_r)
    );

    /*================================*/
    //        ram controller
    /*================================*/

`ifdef VERILATOR
    async_ram U_bram_1(
        .clk(clk_i),
        .en(~w_rom_we_n && w_rom_oe_n), 
        .wen(~w_rom_be_n[1:0]),
        .addr(w_rom_addr),
        .wdata(w_rom_data[15:0]),
        .rdata(w_rom_data[15:0])
    );

    async_ram U_bram_2(
        .clk(clk_i),
        .en(!w_rom_we_n && w_rom_oe_n), 
        .wen(~w_rom_be_n[3:2]),
        .addr(w_rom_addr),
        .wdata(w_rom_data[31:16]),
        .rdata(w_rom_data[31:16])
    );

    async_ram U_extram_1(
        .clk(clk_i),
        .en(~w_ram_we_n && w_ram_oe_n), 
        .wen(~w_ram_be_n[1:0]),
        .addr(w_ram_addr),
        .wdata(w_ram_data[15:0]),
        .rdata(w_ram_data[15:0])
    );

    async_ram U_extram_2(
        .clk(clk_i),
        .en(!w_ram_we_n && w_ram_oe_n), 
        .wen(~w_ram_be_n[3:2]),
        .addr(w_ram_addr),
        .wdata(w_ram_data[31:16]),
        .rdata(w_ram_data[31:16])
    );
`else
    // sram_model U_sram_1(
    //     .Address(w_rom_addr),
    //     .DataIO(w_rom_data[15:0]),
    //     .OE_n(w_rom_oe_n),
    //     .CE_n(w_rom_ce_n),
    //     .WE_n(w_rom_we_n),
    //     .LB_n(w_rom_be_n[0]),
    //     .UB_n(w_rom_be_n[1])
    // );

    // sram_model U_sram_2(
    //     .Address(w_rom_addr),
    //     .DataIO(w_rom_data[31:16]),
    //     .OE_n(w_rom_oe_n),
    //     .CE_n(w_rom_ce_n),
    //     .WE_n(w_rom_we_n),
    //     .LB_n(w_rom_be_n[2]),
    //     .UB_n(w_rom_be_n[3])
    // );
`endif
    sram_ctl U_rom_ctl(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .start_i(1),
        .rw_i(1),
        .data_i(0),
        .data_be_i(0),
        .data_o(if_inst_c),
        .addr_i(if_pc_c[23:0]),
        .r_ready_o(r_ready_o),
        .w_finish_o(w_finish_o),
        .busy_o(busy_o),

        .base_ram_data(w_rom_data),
        .base_ram_addr(w_rom_addr),
        .base_ram_be_n(w_rom_be_n),
        .base_ram_ce_n(w_rom_ce_n),
        .base_ram_oe_n(w_rom_oe_n),
        .base_ram_we_n(w_rom_we_n)
    );

    sram_ctl U_ram_ctl(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .start_i(1),
        .rw_i(dm_rw_c),
        .data_i(dm_wdata_c),
        .data_be_i(dm_wbe_n_c),
        .data_o(dm_rdata_c),
        .addr_i(dm_addr_c[23:0]),
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

    //--------------------------{各模块实例化}end----------------------------//





endmodule