`include "common.vh"

module bridge (
    input [31:0] ifu_wdata_i,
    output[31:0] ifu_rdata_o,
    input [31:0] ifu_addr_i,
    input [3:0]  ifu_be_n_i,
    input        ifu_oe_n_i,
    input        ifu_we_n_i,
    input        ifu_req_i,
    output       ifu_resp_o,

    input [31:0] lsu_wdata_i,
    output[31:0] lsu_rdata_o,
    input [31:0] lsu_addr_i,
    input [3:0]  lsu_be_n_i,
    input        lsu_oe_n_i,
    input        lsu_we_n_i,
    input        lsu_req_i,
    output       lsu_resp_o,

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

    output wire         uart_we_o,
    output wire         uart_re_o,
    output wire[7:0]    uart_tx_data_o,  //直连串口发送端
    input  wire[7:0]    uart_rx_data_i  //直连串口接收端
);
// 虚拟内存空间为0x8000_0000～0x807F_FFFF，共8MB，要求整个内存空间均可读可写可执行。其中
// 0x8000_0000～0x803F_FFFF映射到BaseRAM；
// 0x8040_0000～0x807F_FFFF映射到ExtRAM。
// CPU复位后从0x80000000开始取指令执行。
// 猜测 UART 0xbfd0_0000
//      [31:22]                      + [21:2] + [1:0]
//      [31:28] + [27:24] + [23:22]
// Base: 0b1000'0000'00 ~ 0b1000'0000'00
// Ext : 0b1000'0000'01 ~ 0b1000'0000'01
// UART: 0b1011'1111'11 01 0


    /*==================================================*/
    //                    Arbiter
    /*==================================================*/
    wire ifu_tar_base, ifu_tar_ext;
    wire lsu_tar_base, lsu_tar_ext, lsu_tar_uart;

    assign ifu_tar_base = (ifu_addr_i[31:22] == 0'b1000000000);
    assign ifu_tar_ext  = (ifu_addr_i[31:22] == 0'b1000000001);
    assign lsu_tar_base = (ifu_addr_i[31:22] == 0'b1000000000);
    assign lsu_tar_ext  = (ifu_addr_i[31:22] == 0'b1000000001);
    assign lsu_tar_uart = (ifu_addr_i[31:22] == 0'b1011111111);

    assign ifu_resp_o = ifu_tar_base & ifu_req_i & ~lsu_tar_base & (
            ( ~lsu_tar_ext  & ~lsu_tar_uart & ~lsu_req_i )
        |   (  lsu_tar_ext  & ~lsu_tar_uart &  lsu_req_i )
        |   ( ~lsu_tar_ext  &  lsu_tar_uart &  lsu_req_i )
    );

    assign lsu_resp_o = ifu_tar_base & ifu_req_i & lsu_req_i & (
            (  lsu_tar_base & ~lsu_tar_ext  & ~lsu_tar_uart )
        |   ( ~lsu_tar_base &  lsu_tar_ext  & ~lsu_tar_uart )
        |   ( ~lsu_tar_base & ~lsu_tar_ext  &  lsu_tar_uart )
    );

    /*==================================================*/
    //                      Xbar
    /*==================================================*/


    wire ifu_base_valid;
    wire lsu_base_valid;
    wire lsu_ext_valid ;
    wire lsu_uart_valid;
    
    assign ifu_base_valid = ifu_tar_base & ifu_resp_o;
    assign lsu_base_valid = lsu_tar_base & lsu_resp_o;
    assign lsu_ext_valid  = lsu_tar_ext  & lsu_resp_o;
    assign lsu_uart_valid = lsu_tar_uart & lsu_resp_o;

    assign lsu_rdata_o = lsu_base_valid ? base_ram_data
                        : lsu_ext_valid ? ext_ram_data
                        : lsu_uart_valid ? {24'd0, uart_rx_data_i} 
                        : 32'hdeadbeef; 
    assign ifu_rdata_o = ifu_base_valid ? base_ram_data
                        : 32'hdeadbeef; 

    assign base_ram_data = lsu_base_valid & ~lsu_we_n_i ? lsu_wdata_i
                        : ifu_base_valid & ~ifu_we_n_i ? ifu_wdata_i
                        : 32'hdeadbeef; 
    assign base_ram_addr = lsu_base_valid ? lsu_addr_i[21:2] : ifu_base_valid ? ifu_addr_i[21:2] : 20'd0;
    assign base_ram_be_n = lsu_base_valid ? lsu_be_n_i : ifu_base_valid ? ifu_be_n_i : 4'b1111;
    assign base_ram_ce_n = ~(lsu_base_valid | ifu_base_valid);
    assign base_ram_oe_n = lsu_base_valid ? lsu_oe_n_i : ifu_base_valid ? ifu_oe_n_i : 1;
    assign base_ram_we_n = lsu_base_valid ? lsu_we_n_i : ifu_base_valid ? ifu_we_n_i : 1;

    assign ext_ram_data = lsu_ext_valid & ~lsu_we_n_i ? lsu_wdata_i
                        : 32'hdeadbeef; 
    assign ext_ram_addr = lsu_ext_valid ? lsu_addr_i[21:2] : 20'd0;
    assign ext_ram_be_n = lsu_ext_valid ? lsu_be_n_i : 4'b1111;
    assign ext_ram_ce_n = ~(lsu_ext_valid);
    assign ext_ram_oe_n = lsu_ext_valid ? lsu_oe_n_i : 1;
    assign ext_ram_we_n = lsu_ext_valid ? lsu_we_n_i : 1;


    assign uart_tx_data_o = lsu_uart_valid & ~lsu_we_n_i? lsu_wdata_i[7:0]
                        : 8'hcc;
    assign uart_we_o = lsu_uart_valid ? ~lsu_we_n_i : 0;
    assign uart_re_o = lsu_uart_valid ? ~lsu_oe_n_i : 0;


endmodule