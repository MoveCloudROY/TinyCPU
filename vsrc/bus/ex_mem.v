`include "common.vh"

module ex_mem(
    input clk_i,
    input rst_i,
    input [`EX2MEMBusSize - 1 :0] ex2mem_bus_i,
    output reg [`EX2MEMBusSize - 1 :0] ex2mem_bus_ro
);

    always @(posedge clk_i) begin
        if (rst_i) begin
            ex2mem_bus_ro <= 0;

        end else begin
            ex2mem_bus_ro <= ex2mem_bus_i;
        end
    end


endmodule