`include "common.vh"
module top (


    // _verilator 仿真参数
`ifdef VERILATOR 
    input wire clk_i,
    input wire rst_i
    
    // vivado 仿真参数
`else
    input wire          clk_50M     ,       //50MHz 时钟输入
    input wire          clk_11M0592 ,       //11.0592MHz 时钟输入（备用，可不用）

    input wire          clock_btn   ,       //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire          reset_btn   ,       //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]    touch_btn   ,       //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0]   dip_sw      ,       //32位拨码开关，拨到“ON”时为1
    output wire[15:0]   leds        ,       //16位LED，输出时1点亮
    output wire[7:0]    dpy0        ,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]    dpy1        ,       //数码管高位信号，包括小数点，输出1点亮

    //BaseRAM信号
    inout  wire[31:0]   base_ram_data,      //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0]   base_ram_addr,      //BaseRAM地址
    output wire[3:0]    base_ram_be_n,      //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire         base_ram_ce_n,      //BaseRAM片选，低有效
    output wire         base_ram_oe_n,      //BaseRAM读使能，低有效
    output wire         base_ram_we_n,      //BaseRAM写使能，低有效

    //ExtRAM信号
    inout  wire[31:0]   ext_ram_data ,      //ExtRAM数据
    output wire[19:0]   ext_ram_addr ,      //ExtRAM地址
    output wire[3:0]    ext_ram_be_n ,      //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire         ext_ram_ce_n ,      //ExtRAM片选，低有效
    output wire         ext_ram_oe_n ,      //ExtRAM读使能，低有效
    output wire         ext_ram_we_n ,      //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
`endif

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
    // ID->IF 提前跳转总线
    wire [32:0] jbr_bus_c;
    wire ctl_jbr_taken;
    assign ctl_jbr_taken = jbr_bus_c[32];

    // 各级允许进入信号:本级无效，或本级执行完成且下级允许进入
    assign ctl_if_allow_in  = ctl_if_over & ctl_id_allow_in;
    assign ctl_id_allow_in  = ~ctl_id_valid  | (ctl_id_over  & ctl_ex_allow_in );
    assign ctl_ex_allow_in  = ~ctl_ex_valid  | (ctl_ex_over  & ctl_mem_allow_in);
    assign ctl_mem_allow_in = ~ctl_mem_valid | (ctl_mem_over & ctl_wb_allow_in );
    assign ctl_wb_allow_in  = ~ctl_wb_valid  | ctl_wb_over;


    /*==================================================*/
    //                流水数据信号定义部分
    /*==================================================*/
    /*================================*/
    //            数据通路
    /*================================*/
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
    wire         dm_re_c;
    wire         dm_we_c;

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
    //                   仿真信号转接
    /*==================================================*/
`ifndef VERILATOR
    wire   clk_i;
    wire   rst_i;
    assign clk_i = clk_50M;
    assign rst_i = reset_btn;

    // 指令 rom 接口
    assign if_inst_c     = base_ram_data;
    assign base_ram_addr = if_pc_c[21:2];
    assign base_ram_be_n = 4'd0;
    assign base_ram_ce_n = 1'b0;
    assign base_ram_oe_n = 1'b0;
    assign base_ram_we_n = 1'b1;

    // 数据 ram 接口
    assign dm_rdata_c = ext_ram_data;
    assign ext_ram_data =  dm_we_c ? dm_wdata_c : 32'bz;
    assign ext_ram_addr =  dm_addr_c[21:2];
    assign ext_ram_be_n =  dm_wbe_n_c;
    assign ext_ram_ce_n =  0;
    assign ext_ram_oe_n =  ~dm_re_c;
    assign ext_ram_we_n =  ~dm_we_c;

    assign leds         = 0;
    assign dpy0         = 0;
    assign dpy1         = 0;
    assign txd          = 1;
    assign flash_a      = 0;
    assign flash_d      = 0;
    assign flash_rp_n   = 1;
    assign flash_vpen   = 0;
    assign flash_ce_n   = 1;
    assign flash_oe_n   = 1;
    assign flash_we_n   = 1;
    assign flash_byte_n = 1;
    assign video_red    = 0;
    assign video_green  = 0;
    assign video_blue   = 0;
    assign video_hsync  = 0;
    assign video_vsync  = 0;
    assign video_clk    = 0;
    assign video_de     = 0;

`endif

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
        // .rst_i(rst_i),
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
        .dm_re_o(dm_re_c),
        .dm_we_o(dm_we_c),
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
        ._occupy_pc_o(),

        .ctl_wb_valid_i(ctl_wb_valid),
        .ctl_wb_over_o(ctl_wb_over),
        .ctl_wb_dest_o(ctl_wb_dest_c)
    );

    /*================================*/
    //        ram controller
    /*================================*/

// _verilator 仿真模块
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

// vivado 仿真模块
`else

    // wire locked, clk_cpu, clk_20M;
    // pll_example clock_gen 
    // (
    //     // Clock in ports
    //     .clk_in1(clk_50M),  // 外部时钟输入
    //     // Clock out ports
    //     .clk_out1(clk_cpu), // 时钟输出1，频率在IP配置界面中设置
    //     .clk_out2(clk_20M), // 时钟输出2，频率在IP配置界面中设置
    //     // Status and control signals
    //     .reset(reset_btn), // PLL复位输入
    //     .locked(locked)    // PLL锁定指示输出，"1"表示时钟稳定，
    //                         // 后级电路复位信号应当由它生成（见下）
    // );

    // reg reset_of_clk_cpu;
    // // 异步复位，同步释放，将locked信号转为后级电路的复位reset_of_clk_cpu
    // always@(posedge clk_cpu or negedge locked) begin
    //     if(~locked) reset_of_clk_cpu <= 1'b1;
    //     else        reset_of_clk_cpu <= 1'b0;
    // end

    // always@(posedge clk_cpu or posedge reset_of_clk_cpu) begin
    //     if(reset_of_clk_cpu)begin
    //         // Your Code
    //     end
    //     else begin
    //         // Your Code
    //     end
    // end
    // sram_model U_irom_1(
    //     .Address(if_pc_c[21:2]),
    //     .DataIO(w_rom_data[15:0]),
    //     .OE_n(0),
    //     .CE_n(0),
    //     .WE_n(1),
    //     .LB_n(0),
    //     .UB_n(0)
    // );

    // sram_model U_irom_2(
    //     .Address(if_pc_c[21:2]),
    //     .DataIO(w_rom_data[31:16]),
    //     .OE_n(0),
    //     .CE_n(0),
    //     .WE_n(1),
    //     .LB_n(0),
    //     .UB_n(0)
    // );

    // sram_model U_iram_1(
    //     .Address(dm_addr_c[21:2]),
    //     .DataIO(w_rom_data[15:0]),
    //     .OE_n(dm_rw_c),
    //     .CE_n(0),
    //     .WE_n(~dm_rw_c),
    //     .LB_n(dm_wbe_n_c[0]),
    //     .UB_n(dm_wbe_n_c[1])
    // );

    // sram_model U_iram_2(
    //     .Address(dm_addr_c[21:2]),
    //     .DataIO(w_rom_data[31:16]),
    //     .OE_n(dm_rw_c),
    //     .CE_n(0),
    //     .WE_n(~dm_rw_c),
    //     .LB_n(dm_wbe_n_c[2]),
    //     .UB_n(dm_wbe_n_c[3])
    // );
`endif

    //--------------------------{各模块实例化}end----------------------------//





endmodule