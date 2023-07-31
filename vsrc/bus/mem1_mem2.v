`include "common.vh"

module mem1_mem2(
    input clk_i,
    input rst_i,
    input [`MEM02MEM1BusSize - 1 :0] mem12mem2_bus_i,
    output reg [`MEM02MEM1BusSize - 1 :0] mem12mem2_bus_ro
);

    always @(posedge clk_i) begin
        if (rst_i) begin
            mem12mem2_bus_ro <= 0;

        end else begin
            mem12mem2_bus_ro <= mem12mem2_bus_i;
        end
    end


endmodule
