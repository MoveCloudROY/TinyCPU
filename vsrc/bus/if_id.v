`include "common.vh"

module if_id(
    input               clk_i,
    input               rst_i,

    input [`RegW-1:0]   if_pc_i,
    input [`RegW-1:0]   if_inst_i,
    input if_predict_failed_i,

    // 控制信号 
    input ctl_baseram_hazard,
    input ctl_if_over_i,
    input ctl_id_allow_in_i,
    input ctl_jbr_taken_i,
    // ID 阶段信号
    output reg [`IF2IDBusSize - 1:0]  if2id_bus_ro
);
    //               --      --      --
    //              |  \    |  \    |  \
    //          ----    ----    ----    ----
    //     PC:   pc0    pc1     pc2
    //   IDPC:   ...    pc0     pc1
    //insaddr:   pc0    pc1     pc2
    //   inst:   ...            inst0   inst1 
    reg [`RegW-1:0] if_prepc;
    always @(posedge clk_i) begin
        if (rst_i) begin
            if2id_bus_ro <= {32'd0, 32'd0};
            if_prepc <= 32'd0;
        end else if (if_predict_failed_i & ctl_id_allow_in_i) begin
            if2id_bus_ro <= {if_prepc, 10'b0000001101, 22'd0};
        end else if (ctl_baseram_hazard) begin
            if2id_bus_ro <= if2id_bus_ro;
            // if_prepc <= if_pc_i;
        end else if(ctl_if_over_i && ctl_id_allow_in_i && ~ctl_baseram_hazard) begin
            // 向 ID 传递 PC INST
            if2id_bus_ro <= {if_pc_i, if_inst_i};
            if_prepc <= if_pc_i;
        end
    end

endmodule
