`include "common.vh"

module ex_mem(
    input clk_i,
    input rst_i,
    input [`EX2MEMBusSize - 1 :0] ex2mem_bus_i,
    output reg [`EX2MEMBusSize - 1 :0] ex2mem_bus_ro,

    input wire ctl_ex_over_i,
    output wire ctl_mem_allow_in_i
);

    always @(posedge clk_i) begin
        if (rst_i) begin
            ex2mem_bus_ro <= 0;

        end else if (ctl_ex_over_i && ctl_mem_allow_in_i) begin
            ex2mem_bus_ro <= ex2mem_bus_i;
        end
    end


endmodule