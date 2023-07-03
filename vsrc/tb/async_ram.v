`include "common.vh"
module async_ram(
    input         clk,
    input         en,   //access enable, HIGH valid
    input  [ 1:0] wen,  //write enable by byte, HIGH valid
    input  [ 19:0] addr,
    input  [15:0] wdata,
    output [15:0] rdata
);

reg  [15:0] bit_array [1048575:0];
wire [15:0] rd_out;

// bit array write
always @(posedge clk) begin
    if (en) begin
        if (wen[0]) bit_array[addr][ 7: 0] <= wdata[ 7: 0];
        if (wen[1]) bit_array[addr][15: 8] <= wdata[15: 8];
    end
end

// bit array read
assign rd_out = bit_array[addr];

// final output
assign rdata = rd_out;

endmodule
