`include "common.vh"

module if_id(
    input               clk_i,
    input               rst_i,

    input [`RegW-1:0]   if_pc_i,
    input [`RegW-1:0]   if_inst_i,

    // ID 阶段信号
    output reg [`IF2IDBusSize - 1:0]  if2id_bus_ro
    // output reg [`RegW-1:0]  if_id_pc_o,
    // output reg [`RegW-1:0]  if_id_pcnow_o,
    // output reg [`RegW-1:0]  if_id_inst_o
);
    reg [`RegW-1:0] if_id_pcnow;
    //               --      --      --
    //              |  \    |  \    |  \
    //          ----    ----    ----    ----
    //     PC:   pc0    pc1     pc2
    //   IDPC:   ...    pc0     pc1
    //insaddr:   pc0    pc1     pc2
    //   inst:   ...            inst0   inst1 

    always @(posedge clk_i) begin
        if (rst_i) begin
            if2id_bus_ro <= {32'd0, 32'd0, 32'd0};
            if_id_pcnow <= 32'd0;
        end else begin
            if_id_pcnow <= if_pc_i;
            // 向 ID 传递 PC INST
            if2id_bus_ro <= {if_pc_i, if_id_pcnow, if_inst_i};
            
        end
    end

endmodule