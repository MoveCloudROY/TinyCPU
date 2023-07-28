`include "common.vh"

module multiplier(
    input                   clk_i,
    input                   mult_start_i, // 乘法开始信号
    input  [`RegW - 1:0]    mult_opd1_i,   // 乘法源操作数1
    input  [`RegW - 1:0]    mult_opd2_i,   // 乘法源操作数2

    output [2*`RegW - 1:0]  product_o,    // 乘积
    output                  mult_end_o    // 乘法结束信号
);

    reg result_ready; 
    reg [2*`RegW + 1:0] result;

    reg [5:0] calc_cnt;
    reg [`RegW:0] M, M_comp;
    reg [1:0] state;


    always @(posedge clk_i) begin 
        if (!mult_start_i || result_ready) begin
            result_ready <= 1'b0;
            result <= 66'd0;
            calc_cnt <= 6'd0;
            state <= 2'd0;
            {M, M_comp} <= {33'd0, 33'd0};
        end
        case (state)
            2'd0: begin
                {M, M_comp} <= {{mult_opd1_i[`RegW - 1], mult_opd1_i}, ~{mult_opd1_i[`RegW - 1], mult_opd1_i} + 1'b1};
                result <= {33'd0, mult_opd2_i, 1'b0};
                state <= 2'd1;
                calc_cnt <=  6'd0;
            end 
            2'd1: begin
                if (calc_cnt == 6'd32) begin
                    result_ready <= 1'b1;
                    result <= {result[2*`RegW + 1], result[2*`RegW + 1:1]};
                    state <= 2'd0;
                end
                else if(result[1:0] == 2'b01) begin
                    result <= {result[2*`RegW + 1:`RegW + 1] + M, result[`RegW:0]};
                    state <= 2'd2;
                end
                else if(result[1:0] == 2'b10) begin
                    result <= {result[2*`RegW + 1:`RegW + 1] + M_comp, result[`RegW:0]};
                    state <= 2'd2;
                end
                else begin
                    state <= 2'd2;
                end
                
            end
            2'd2: begin
                result <= {result[2*`RegW + 1], result[2*`RegW + 1:1]};
                calc_cnt <= calc_cnt + 1'd1;
                state <= 2'd1;
            end

            // ?
            2'd3: begin
                state <= 2'd0;
            end 
        endcase
    end

    assign product_o = result[2*`RegW - 1:0];
    assign mult_end_o = result_ready;

endmodule