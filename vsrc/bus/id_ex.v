`include "common.vh"

module id_ex(
    // to EXE bus
    input clk_i,
    input rst_i,
    input [`ID2EXBusSize - 1:0] id2ex_bus_i,

    output reg [`ID2EXBusSize - 1:0] id2ex_bus_ro
);

    always @(posedge clk_i) begin
        if (rst_i) begin
            id2ex_bus_ro <= {12'd0, 32'd0, 32'd0, 6'd0, 32'd0, 5'd0, 1'd0, 32'd0};

        end else begin
            // 向 ID 传递 PC INST
            id2ex_bus_ro <= id2ex_bus_i;
        end
    end


endmodule