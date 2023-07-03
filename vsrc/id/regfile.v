`include "common.vh"

module regfile(
    input               clk_i,
    input               rst_i,
    input      [4 :0] raddr1_i,
    input      [4 :0] raddr2_i,
    input      [4 :0] waddr_i,
    input      [`RegW-1:0] wdata_i,
    output reg [`RegW-1:0] rdata1_o,
    output reg [`RegW-1:0] rdata2_o
);

    reg[`RegW-1:0] regfile[`RegNum-1:0];

    // write
    always @(posedge clk_i) begin
        regfile[waddr_i] <= wdata_i;
    end
    
    // read port 1
    always @(*) begin
        case (raddr1_i)
            5'd1 : rdata1_o = regfile[1 ];
            5'd2 : rdata1_o = regfile[2 ];
            5'd3 : rdata1_o = regfile[3 ];
            5'd4 : rdata1_o = regfile[4 ];
            5'd5 : rdata1_o = regfile[5 ];
            5'd6 : rdata1_o = regfile[6 ];
            5'd7 : rdata1_o = regfile[7 ];
            5'd8 : rdata1_o = regfile[8 ];
            5'd9 : rdata1_o = regfile[9 ];
            5'd10: rdata1_o = regfile[10];
            5'd11: rdata1_o = regfile[11];
            5'd12: rdata1_o = regfile[12];
            5'd13: rdata1_o = regfile[13];
            5'd14: rdata1_o = regfile[14];
            5'd15: rdata1_o = regfile[15];
            5'd16: rdata1_o = regfile[16];
            5'd17: rdata1_o = regfile[17];
            5'd18: rdata1_o = regfile[18];
            5'd19: rdata1_o = regfile[19];
            5'd20: rdata1_o = regfile[20];
            5'd21: rdata1_o = regfile[21];
            5'd22: rdata1_o = regfile[22];
            5'd23: rdata1_o = regfile[23];
            5'd24: rdata1_o = regfile[24];
            5'd25: rdata1_o = regfile[25];
            5'd26: rdata1_o = regfile[26];
            5'd27: rdata1_o = regfile[27];
            5'd28: rdata1_o = regfile[28];
            5'd29: rdata1_o = regfile[29];
            5'd30: rdata1_o = regfile[30];
            5'd31: rdata1_o = regfile[31];
            default : rdata1_o = 32'd0;
        endcase
    end
    //读端口2
    always @(*) begin
        case (raddr2_i)
            5'd1 : rdata2_o = regfile[1 ];
            5'd2 : rdata2_o = regfile[2 ];
            5'd3 : rdata2_o = regfile[3 ];
            5'd4 : rdata2_o = regfile[4 ];
            5'd5 : rdata2_o = regfile[5 ];
            5'd6 : rdata2_o = regfile[6 ];
            5'd7 : rdata2_o = regfile[7 ];
            5'd8 : rdata2_o = regfile[8 ];
            5'd9 : rdata2_o = regfile[9 ];
            5'd10: rdata2_o = regfile[10];
            5'd11: rdata2_o = regfile[11];
            5'd12: rdata2_o = regfile[12];
            5'd13: rdata2_o = regfile[13];
            5'd14: rdata2_o = regfile[14];
            5'd15: rdata2_o = regfile[15];
            5'd16: rdata2_o = regfile[16];
            5'd17: rdata2_o = regfile[17];
            5'd18: rdata2_o = regfile[18];
            5'd19: rdata2_o = regfile[19];
            5'd20: rdata2_o = regfile[20];
            5'd21: rdata2_o = regfile[21];
            5'd22: rdata2_o = regfile[22];
            5'd23: rdata2_o = regfile[23];
            5'd24: rdata2_o = regfile[24];
            5'd25: rdata2_o = regfile[25];
            5'd26: rdata2_o = regfile[26];
            5'd27: rdata2_o = regfile[27];
            5'd28: rdata2_o = regfile[28];
            5'd29: rdata2_o = regfile[29];
            5'd30: rdata2_o = regfile[30];
            5'd31: rdata2_o = regfile[31];
            default : rdata2_o = 32'd0;
        endcase
    end



endmodule