`include "common.vh"
module top (
    input wire clk_i,
    input wire rst_i
    
    // // 启动信号
    // input start_i,
    // // 选择读(1)写(0) 
    // input rw_i,
    // // 数据读写 from CPU 
    // input [31:0] data_i,
	// output [31:0] data_o,
    // // 地址 from CPU
    // input [23:0] addr_i,
    
    // // 读-数据 就位
    // output reg r_ready_o,
    // // 写-数据 完成
    // output reg w_finish_o,
    // // 工作中
    // output reg busy_o
    
    // // inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    // // output wire[19:0] base_ram_addr, //BaseRAM地址
    // // output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    // // output wire base_ram_ce_n,       //BaseRAM片选，低有效
    // // output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    // // output wire base_ram_we_n       //BaseRAM写使能，低有效

);

    /*==================================================*/
    //                 流水控制信号定义部分
    /*==================================================*/

    // 5模块有效信号
    reg ctl_if_valid;
    reg ctl_id_valid;
    reg ctl_ex_valid;
    reg ctl_mem_valid;
    reg ctl_wb_valid;
    // 5模块执行完成信号,来自各模块的输出
    wire ctl_if_over;
    wire ctl_id_over;
    wire ctl_ex_over;
    wire ctl_mem_over;
    wire ctl_wb_over;
    // 5模块允许下一级指令进入
    wire ctl_if_allow_in;
    wire ctl_id_allow_in;
    wire ctl_ex_allow_in;
    wire ctl_mem_allow_in;
    wire ctl_wb_allow_in;

    // 数据冒险检测信号
    wire [`RegAddrBusW-1:0] ctl_ex_dest_c;
    wire [`RegAddrBusW-1:0] ctl_mem_dest_c;
    wire [`RegAddrBusW-1:0] ctl_wb_dest_c;
    
    wire ctl_jbr_taken;
    assign ctl_jbr_taken = jbr_bus_c[32];

    // 各级允许进入信号:本级无效，或本级执行完成且下级允许进入
    assign ctl_if_allow_in  = ctl_if_over & ctl_id_allow_in;
    assign ctl_id_allow_in  = ~ctl_id_valid  | (ctl_id_over  & ctl_ex_allow_in );
    assign ctl_ex_allow_in  = ~ctl_ex_valid  | (ctl_ex_over  & ctl_mem_allow_in);
    assign ctl_mem_allow_in = ~ctl_mem_valid | (ctl_mem_over & ctl_wb_allow_in );
    assign ctl_wb_allow_in  = ~ctl_wb_valid  | ctl_wb_over;

    /*==================================================*/
    //                  流水控制信号转移
    /*==================================================*/

    always @(posedge clk_i) begin
        if (rst_i) begin
            ctl_if_valid <= 1'b0;
        end else begin
            ctl_if_valid <= 1'b1;
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            ctl_id_valid <= 1'b0;
        end else if (ctl_id_allow_in) begin
            ctl_id_valid <= ctl_if_over;
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            ctl_ex_valid <= 1'b0;
        end else if (ctl_ex_allow_in) begin
            ctl_ex_valid <= ctl_id_over;
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            ctl_mem_valid <= 1'b0;
        end else if (ctl_mem_allow_in) begin
            ctl_mem_valid <= ctl_ex_over;
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            ctl_wb_valid <= 1'b0;
        end else if (ctl_wb_allow_in) begin
            ctl_wb_valid <= ctl_mem_over;
        end
    end


    /*==================================================*/
    //                流水数据信号定义部分
    /*==================================================*/
    /*================================*/
    //            数据通路
    /*================================*/
    // ID->IF 提前跳转总线
    wire [32:0] jbr_bus_c;
    // IF->InstRAM 取指令
    wire [`RegW-1:0] if_pc_c;
    // IF->IF/ID 构建级间寄存器
    wire [`RegW-1:0] if_inst_c;

    // ID->Regfile 取值
    wire [`RegW-1:0] rj_data_c;
    wire [`RegW-1:0] rk_data_c;
    wire [`RegAddrBusW-1:0] rj_addr_c;
    wire [`RegAddrBusW-1:0] rk_addr_c;

    // MEM->DataRAM 访存相关
    wire [ 31:0] dm_rdata_c;
    wire [ 31:0] dm_addr_c;
    wire [  3:0] dm_wbe_n_c;
    wire [ 31:0] dm_wdata_c;
    wire         dm_rw_c;

    // WB->Regfile 写回寄存器
    wire [  4:0] rf_wdest_c;
    wire           rf_we_c;
    wire [ 31:0] rf_wdata_c;

    /*================================*/
    //           级间总线信号
    /*================================*/
    wire [`IF2IDBusSize - 1:0]  if2id_bus_r;
    wire [`ID2EXBusSize - 1:0]  id2ex_bus_c;
    wire [`ID2EXBusSize - 1:0]  id2ex_bus_r;
    wire [`EX2MEMBusSize - 1 :0] ex2mem_bus_c;
    wire [`EX2MEMBusSize - 1 :0] ex2mem_bus_r;
    wire [`MEM2WBBusSize - 1 :0] mem2wb_bus_c;
    wire [`MEM2WBBusSize - 1 :0] mem2wb_bus_r;


    /*==================================================*/
    //                    五级流水部分
    /*==================================================*/
    /*================================*/
    //               IF
    /*================================*/
    pc_reg U_pc_reg(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .jbr_bus_i(jbr_bus_c),
        .if_pc_o(if_pc_c),

        .ctl_if_valid_i(ctl_if_valid),
        .ctl_if_over_o(ctl_if_over),
        .ctl_if_allow_in_i(ctl_if_allow_in)
    );

    if_id U_if2id(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .if_pc_i(if_pc_c),
        .if_inst_i(if_inst_c),
        .if2id_bus_ro(if2id_bus_r),

        .ctl_jbr_taken_i(ctl_jbr_taken),
        .ctl_if_over_i(ctl_if_over),
        .ctl_id_allow_in_i(ctl_id_allow_in)
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
        .id2ex_bus_o(id2ex_bus_c),

        .ctl_ex_dest_i(ctl_ex_dest_c),
        .ctl_mem_dest_i(ctl_mem_dest_c),
        .ctl_wb_dest_i(ctl_wb_dest_c),

        .ctl_if_over_i(ctl_if_over),
        .ctl_id_valid_i(ctl_id_valid),
        .ctl_id_over_o(ctl_id_over)
    );

    regfile U_reg_file(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .we_i(rf_we_c),
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
        .id2ex_bus_ro(id2ex_bus_r),

        .ctl_id_over_i(ctl_id_over),
        .ctl_ex_allow_in_i(ctl_ex_allow_in)
    );

    /*================================*/
    //               EXE
    /*================================*/

    ex U_ex(
        .id2ex_bus_ri(id2ex_bus_r),
        .ex2mem_bus_o(ex2mem_bus_c),

        .ctl_ex_valid_i(ctl_ex_valid),
        .ctl_ex_over_o(ctl_ex_over),
        .ctl_ex_dest_o(ctl_ex_dest_c)
    );

    ex_mem U_ex2mem(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .ex2mem_bus_i(ex2mem_bus_c),
        .ex2mem_bus_ro(ex2mem_bus_r),

        .ctl_ex_over_i(ctl_ex_over),
        .ctl_mem_allow_in_i(ctl_mem_allow_in)
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
        .mem2wb_bus_o(mem2wb_bus_c),

        .ctl_mem_valid_i(ctl_mem_valid),
        .ctl_mem_over_o(ctl_mem_over),
        .ctl_mem_dest_o(ctl_mem_dest_c)
    );

    mem_wb U_mem2wb(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .mem2wb_bus_i(mem2wb_bus_c),
        .mem2wb_bus_ro(mem2wb_bus_r),

        .ctl_mem_over_i(ctl_mem_over),
        .ctl_wb_allow_in_i(ctl_wb_allow_in)
    );

    /*================================*/
    //               WB
    /*================================*/

    wb U_wb(
        .rf_wdest_o(rf_wdest_c),
        .rf_we_o(rf_we_c),
        .rf_wdata_o(rf_wdata_c),
        .mem2wb_bus_ri(mem2wb_bus_r),

        .ctl_wb_valid_i(ctl_wb_valid),
        .ctl_wb_over_o(ctl_wb_over),
        .ctl_wb_dest_o(ctl_wb_dest_c)
    );

    /*================================*/
    //        ram controller
    /*================================*/

`ifdef VERILATOR
    IROM #(.ADDR_BITS(20)) U_irom (
        .a(if_pc_c[21:2]),
        .spo(if_inst_c)
    );

    DRAM #(.ADDR_BITS(20)) U_dram (
        .clk(clk_i),
        .a(dm_addr_c[21:2]),
        .we(~dm_wbe_n_c),
        .d(dm_wdata_c),
        .spo(dm_rdata_c)
    );
    // async_ram U_bram_inst_1(
    //     .clk(clk_i),
    //     .we_n(0), 
    //     .web_n(0),
    //     .addr(if_pc_c[19:0]),
    //     .wdata(0),
    //     .rdata(if_inst_c[15:0])
    // );

    // async_ram U_bram_inst_2(
    //     .clk(clk_i),
    //     .we_n(0), 
    //     .web_n(0),
    //     .addr(if_pc_c[19:0]),
    //     .wdata(0),
    //     .rdata(if_inst_c[31:16])
    // );

    // async_ram U_extram_data_1(
    //     .clk(clk_i),
    //     .we_n(dm_rw_c), 
    //     .web_n(dm_wbe_n_c[1:0]),
    //     .addr(dm_addr_c[19:0]),
    //     .wdata(dm_wdata_c[15:0]),
    //     .rdata(dm_rdata_c[15:0])
    // );

    // async_ram U_extram_data_2(
    //     .clk(clk_i),
    //     .we_n(dm_rw_c), 
    //     .web_n(dm_wbe_n_c[3:2]),
    //     .addr(dm_addr_c[19:0]),
    //     .wdata(dm_wdata_c[31:16]),
    //     .rdata(dm_rdata_c[31:16])
    // );
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
    // sram_ctl U_rom_ctl(
    //     .clk_i(clk_i),
    //     .rst_i(rst_i),
    //     .start_i(1),
    //     .rw_i(1),
    //     .data_i(0),
    //     .data_be_i(0),

    //     .data_o(if_inst_c),
    //     .addr_i(if_pc_c[23:0]),

    //     .r_ready_o(r_ready_o),
    //     .w_finish_o(w_finish_o),
    //     .busy_o(busy_o),

    //     .base_ram_data(w_rom_data),
    //     .base_ram_addr(w_rom_addr),
    //     .base_ram_be_n(w_rom_be_n),
    //     .base_ram_ce_n(w_rom_ce_n),
    //     .base_ram_oe_n(w_rom_oe_n),
    //     .base_ram_we_n(w_rom_we_n)
    // );

    // sram_ctl U_ram_ctl(
    //     .clk_i(clk_i),
    //     .rst_i(rst_i),
    //     .start_i(1),

    //     .rw_i(dm_rw_c),
    //     .data_i(dm_wdata_c),
    //     .data_be_i(dm_wbe_n_c),
    //     .data_o(dm_rdata_c),
    //     .addr_i(dm_addr_c[23:0]),

    //     .r_ready_o(r_ready_o),
    //     .w_finish_o(w_finish_o),
    //     .busy_o(busy_o),

    //     .base_ram_data(w_ram_data),
    //     .base_ram_addr(w_ram_addr),
    //     .base_ram_be_n(w_ram_be_n),
    //     .base_ram_ce_n(w_ram_ce_n),
    //     .base_ram_oe_n(w_ram_oe_n),
    //     .base_ram_we_n(w_ram_we_n)

    // );

    //--------------------------{各模块实例化}end----------------------------//





endmodule