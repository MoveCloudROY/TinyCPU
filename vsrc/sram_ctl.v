`include "common.vh"

module sram_ctl (
    // CLK & RESET
    input clk_i,
    input rst_i,

    // 选择读(1)写(0) 
    input re_n_i,
    input we_n_i,
	input [3:0]  data_be_n_i,
    // 数据读写 from CPU 
    output [31:0] rdata_o,
    input [31:0] wdata_i,
    // 地址 from CPU
    input [31:0] addr_i,
    
    output ctl_ram_ok_o,
    output mem_ctl_req_o,
    input ctl_ram_valid_i,

    // 和 sram 连接完成
    input wire[31:0] ram_rdata,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[31:0] ram_wdata,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[31:0] ram_addr, //BaseRAM地址
    output wire[3:0] ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ram_ce_n,       //BaseRAM片选，低有效
    output wire ram_oe_n,       //BaseRAM读使能，低有效
    output wire ram_we_n        //BaseRAM写使能，低有效
);

    localparam [1:0]
    IDLE    =   2'd0,
    RD0     =   2'd1,
    WR0     =   2'd2;


    reg [1:0] cur_state_r;
    reg [1:0] nxt_state_r;
    reg [31:0] wdata_r;
    reg [31:0] rdata_r;
    reg [31:0] addr_r;
    reg[3:0] be_n_r;
    reg ce_n_r;
    reg oe_n_r;
    reg we_n_r, we_n_r_posedge;
    reg ok;
    reg req;

    // 状态转移
    always@(posedge clk_i)  begin
        if (rst_i) begin
            cur_state_r <= IDLE;
        end else begin
            cur_state_r <= nxt_state_r;
        end
    end
    // 组合逻辑部分
    always @(*) begin
        nxt_state_r = IDLE;
        case(cur_state_r)
            IDLE: begin
                if (!re_n_i & ~ok) 
                    nxt_state_r = RD0;
                else if(!we_n_i & ~ok)
                    nxt_state_r = WR0;
                else
                    nxt_state_r = IDLE;
            end
            RD0: begin
                if (ctl_ram_valid_i) 
                    nxt_state_r = IDLE;
                else
                    nxt_state_r = RD0;
            end
            WR0: begin
                if (ctl_ram_valid_i)
                    nxt_state_r = IDLE;
                else
                    nxt_state_r = WR0;
            end
            default: begin
            end
        endcase
    end

    // 输出部分
    always @(posedge clk_i) begin
        if (rst_i) begin
            wdata_r <= 32'hdeadbeef;
            addr_r <= 32'd0;
            be_n_r <= 4'b1111;
            ce_n_r <= 1'b1;
            oe_n_r <= 1'b1;
            we_n_r_posedge <= 1'b1;
            ok <= 1'b0;
            req <= 1'b0;

        end else begin
        case(cur_state_r)
            IDLE: begin
                if (!re_n_i) begin
                    addr_r <= addr_i;
                    be_n_r <= data_be_n_i;
                    ce_n_r <= 1'b0;
                    oe_n_r <= 1'b0 | ok;
                    we_n_r_posedge <= 1'b1;
                    rdata_r <= ram_rdata;
                    ok <= 1'b0;
                    req <= 1'b1;

                end else if(!we_n_i) begin
                    addr_r <= addr_i;
                    wdata_r <= wdata_i;
                    be_n_r <= data_be_n_i;
                    ce_n_r <= 1'b0;
                    oe_n_r <= 1'b1;
                    we_n_r_posedge <= 1'b0 | ok; // ?
                    ok <= 1'b0;
                    req <= 1'b1;

                end else begin
                    be_n_r <= 4'b1111;
                    ce_n_r <= 1'b1;
                    oe_n_r <= 1'b1;
                    we_n_r_posedge <= 1'b1;
                    ok <= 1'b0;
                    req <= 1'b0;

                end
            end
            RD0: begin
                ok <= ctl_ram_valid_i & 1'b1;
                we_n_r_posedge <= 1'b1;
                req <= 1'b1;
            end
            WR0: begin
                ok <= ctl_ram_valid_i & 1'b1;
                we_n_r_posedge <= 1'b1 ;
                req <= 1'b1;

            end
            default: begin
                
            end
        endcase
        end
    end

    always @(negedge clk_i) begin
        we_n_r <= we_n_r_posedge;
    end

    assign rdata_o = rdata_r;
    assign ram_wdata = wdata_r;
    assign ram_addr = addr_r;
    assign ram_be_n = be_n_r;
    assign ram_ce_n = ce_n_r;
    assign ram_oe_n = oe_n_r;
    assign ram_we_n = we_n_r;

    assign ctl_ram_ok_o = ok;
    assign mem_ctl_req_o = req;

endmodule
