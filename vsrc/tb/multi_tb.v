`include "common.vh"

module mult_tb(
    input                   CLK,
    input  [`RegW - 1:0]    A,   // 乘法源操作数1
    input  [`RegW - 1:0]    B,   // 乘法源操作数2

    output [`RegW - 1:0]  P    // 乘积
);

    reg [2*`RegW - 1:0] rP;
    reg [`RegW -1:0] rA, rB;
    reg [1:0] stage;

    always @(posedge CLK) begin 
        rA <= A;
        rB <= B;
        rP <= rA * rB;
    end

    assign P = rP[`RegW - 1:0];

endmodule