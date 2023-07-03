`include "common.vh"

module sram_ctl (
    // CLK & RESET
    input clk_i,
    input rst_i,

    // 启动信号
    input start_i,
    // 选择读(1)写(0) 
    input rw_i,
    // 数据读写 from CPU 
    input [31:0] data_i,
	input [3:0]  data_be_i,
    output [31:0] data_o,
    // 地址 from CPU
    input [23:0] addr_i,
    
    // 读-数据 就位
    output reg r_ready_o,
    // 写-数据 完成
    output reg w_finish_o,
    // 工作中
    output reg busy_o,

    // 和 sram 连接完成
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n        //BaseRAM写使能，低有效
);

    localparam [1:0]
    IDLE    =   2'd0,
    RD0     =   2'd1,
    WR0     =   2'd2;
    

    reg [1:0] reg_cur_state;
    reg [1:0] reg_nxt_state;
    reg [31:0] reg_data_o;
    reg [31:0] reg_data_i;
    reg reg_busy;
    reg reg_we_n;

    // 状态转移
    always@(posedge clk_i)  begin
        if (rst_i) begin
            reg_cur_state <= IDLE;
        end else begin
            reg_cur_state <= reg_nxt_state;
        end
    end
    // 组合逻辑部分
    always @(*) begin
        if (!start_i) begin
            reg_nxt_state = IDLE;
        end else begin
            
        case(reg_cur_state)
            IDLE: begin
                if (rw_i) 
                    reg_nxt_state = RD0;
                else
                    reg_nxt_state = WR0;
            end
            RD0: begin
                reg_nxt_state = IDLE;
            end
            WR0: begin
                reg_nxt_state = IDLE; 
            end
            default: begin
            end
        endcase
        end
    end

    // 输出部分
    always @(posedge clk_i) begin
        case(reg_cur_state)
            IDLE: begin
                r_ready_o <= 1'b0;
                w_finish_o <= 1'b0;
                busy_o <= 1'b0;

                base_ram_addr <= 20'd0;
                base_ram_be_n <= 4'd0;
                base_ram_ce_n <= 1'b0;
                // 默认使能读
                base_ram_oe_n <= 1'b0;
                base_ram_we_n <= 1'b1;

                reg_data_o <= 32'd0;
                reg_busy <= 1'b0;
                reg_we_n <= 1'b1;
                // 写提前准备数据
                if (start_i && !rw_i)
                    reg_data_i <= data_i;
                else 
                    reg_data_i <= 32'd0;

                // 读写均要提前准备地址
                if (start_i && rw_i) begin
                    base_ram_addr <= addr_i[19:0];
                end else if (start_i && !rw_i)begin
                    base_ram_addr <= addr_i[19:0];
                end
            end
            RD0: begin
                r_ready_o <= 1'b1;
                busy_o <= 1'b1;
                // 一个 clk 后读出值
                reg_data_o <= base_ram_data;
            end
            WR0: begin
                w_finish_o <= 1'b1;
                busy_o <= 1'b1;

                base_ram_be_n <= data_be_i;
                base_ram_ce_n <= 1'b0;
                // 给出写信号
                base_ram_oe_n <= 1'b1;
                base_ram_we_n <= 1'b0;
                reg_we_n <= 1'b0;

            end
            default: begin
                
            end
        endcase
    end

    assign data_o = reg_data_o;
    // 写信号的同时将数据接入
    assign base_ram_data = (base_ram_we_n) ? 32'bz : reg_data_i;

endmodule