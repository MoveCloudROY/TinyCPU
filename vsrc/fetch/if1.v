`include "common.vh"

module if1(
    input clk_i,
    input rst_i,

    input ctl_if_allow_nxt_pc_i,
    input ctl_if_valid_i,
    output ctl_if_over_o,

    input [`RegW-1:0] if_pc_i,
    input [`RegW-1:0] if_inst_i,
    output [`RegW-1:0]  if1_pc_o,
    output [`RegW-1:0]  if1_inst_o
);

    reg [`RegW-1:0] pc;
    reg [`RegW-1:0] inst;


    always @(posedge clk_i) begin
        if(rst_i) begin
            pc <= `LOONG_PC_START_ADDR - 4;
        end else if (ctl_if_allow_nxt_pc_i) begin
            pc <= if_pc_i;
            inst <= if_inst_i;
        end
    end

    assign ctl_if_over_o = ctl_if_valid_i;
    assign if1_pc_o = pc;
    assign if1_inst_o = inst;
endmodule
