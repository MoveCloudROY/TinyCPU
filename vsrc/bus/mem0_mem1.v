`include "common.vh"

module mem0_mem1(
    input clk_i,
    input rst_i,
    input [`MEM02MEM1BusSize - 1 :0] mem02mem1_bus_i,
    output reg [`MEM02MEM1BusSize - 1 :0] mem02mem1_bus_ro
);

    always @(posedge clk_i) begin
        if (rst_i) begin
            mem02mem1_bus_ro <= 0;

        end else begin
            mem02mem1_bus_ro <= mem02mem1_bus_i;
        end
    end


endmodule
