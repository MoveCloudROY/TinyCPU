`include "common.vh"

module pc_reg(
    input clk_i,
    input rst_i,
    input [32:0] jbr_bus_i,   // 跳转总线

    input ctl_if_allow_nxt_pc_i,
    input ctl_if_valid_i,
    output ctl_if_over_o,

    output [`RegW-1:0] if_pc_o
);
    // 下一个 PC
    wire [`RegW-1:0] next_pc;
    wire [`RegW-1:0] seq_pc;

    reg  [`RegW-1:0] pc;

    //跳转pc
    wire        jbr_taken;
    wire [31:0] jbr_target;
    assign {jbr_taken, jbr_target} = jbr_bus_i;  // 跳转总线传是否跳转和目标地址

    //pc+4
    assign seq_pc[`RegW-1:2]    = pc[`RegW-1:2] + 1'b1;  // 下一指令地址：PC = PC + 4
    assign seq_pc[1:0]     = pc[1:0];

    assign next_pc = jbr_taken ? jbr_target : seq_pc;

    always @(posedge clk_i) begin
        if(rst_i) begin
            pc <= `LOONG_PC_START_ADDR - 4;
        end else if (ctl_if_allow_nxt_pc_i) begin
            pc <= next_pc;
        end
    end


    assign ctl_if_over_o = ctl_if_valid_i;

    assign if_pc_o = pc;
endmodule
