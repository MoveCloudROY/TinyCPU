`include "common.vh"

module mem_wb(
    input clk_i,
    input rst_i,
    input [`MEM2WBBusSize - 1 :0] mem2wb_bus_i,
    output reg [`MEM2WBBusSize - 1 :0] mem2wb_bus_ro
);

    always @(posedge clk_i) begin
        if (rst_i) begin
            mem2wb_bus_ro <= 0;

        end else begin
            mem2wb_bus_ro <= mem2wb_bus_i;
        end
    end


endmodule