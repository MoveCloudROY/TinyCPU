`include "common.vh"


module adder(
    input  [31:0] operand1,
    input  [31:0] operand2,
    input         cin,
    output [31:0] result,
    output        cout
);

    assign {cout,result} = operand1 + operand2 + {31'd0, cin};

endmodule
