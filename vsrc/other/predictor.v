`include "common.vh"

module predictor (
    input clk_i,
    input rst_i,

    input [`RegW-1:0] if_predict_pc_i,

    output [`RegW-1:0] if_predict_targetPc_o,
    output wire if_predict_taken_o,
    output wire if_predict_failed_o,
    output [`RegW-1:0] if_flush_pc_o,
    
    input id_update_isJumpInst_i,
    input [`RegW-1:0] id_update_pc_i, 
    input [`RegW-1:0] id_update_targetPc_i,
    input wire id_update_taken_i
);
    parameter NUM_ENTRIES = 64;
    localparam [1:0]
    STRONG_NOT_TAKEN =  2'b00,
    WEAK_NOT_TAKEN   =  2'b01,
    WEAK_TAKEN       =  2'b10,
    STRONG_TAKEN     =  2'b11;

    
    /*
        32bit PC
        0x8000_0000～0x803F_FFFF
        [5:2]
        predict 16 instructions
    */
    // reg         pd_valid        [NUM_ENTRIES-1:0];
    reg [1:0]   pd_history      [NUM_ENTRIES-1:0];
    reg [31:0]  pd_targetPc     [NUM_ENTRIES-1:0];

    // Index into the predictor table
    wire [7:2] pd_index;
    assign pd_index = if_predict_pc_i[7:2];

    // Current prediction for the branch
    wire [1:0] current_prediction;
    assign current_prediction = pd_history[pd_index];

    // Prediction target pc addr
    wire [`RegW-1:0] current_targetPc;
    assign current_targetPc = pd_targetPc[pd_index];

    // Predict whether the branch will be taken or not
    assign if_predict_taken_o     = current_prediction[1];
    assign if_predict_targetPc_o  = current_targetPc;

    wire [7:2] update_index;
    assign update_index = id_update_pc_i[7:2];
    wire [1:0] update_history;
    assign update_history = pd_history[update_index];

    wire prediction_isFailed;
    assign prediction_isFailed = (update_history[1] ^ id_update_taken_i) & id_update_isJumpInst_i;
    assign if_predict_failed_o  = prediction_isFailed;
    assign if_flush_pc_o = update_history[1] ? 
                            id_update_pc_i + 32'd4 : id_update_targetPc_i;


    // Prediction is valid or not
    // wire update_valid;
    // assign update_valid = pd_valid[update_index];
    reg stall;
    always @(posedge clk_i) begin
        if (rst_i) begin
            stall <= 1'b0;
        end else begin
            stall <= prediction_isFailed;
        end
    end
    // Update the predictor based on actual outcome
    always @(posedge clk_i) begin
        if (rst_i) begin
            for (int i = 0; i < NUM_ENTRIES; i = i + 1) begin
                pd_history[i] <= STRONG_NOT_TAKEN;
            end
        end else begin
            if (id_update_isJumpInst_i) begin
                // else Update as
                /*
                        T       T       T
                    00 ---> 01 ---> 11 ---> 11

                        F       F       F
                    11 ---> 10 ---> 00 ---> 00
                */
                if (id_update_taken_i) begin
                    case (update_history)
                        STRONG_NOT_TAKEN: begin
                            pd_history[update_index] <= WEAK_NOT_TAKEN;
                            pd_targetPc[update_index] <= id_update_targetPc_i;
                        end 
                        WEAK_NOT_TAKEN  : begin
                            pd_history[update_index] <= STRONG_TAKEN;
                            pd_targetPc[update_index] <= id_update_targetPc_i;
                        end
                        WEAK_TAKEN      : begin
                            pd_history[update_index] <= STRONG_TAKEN;
                            pd_targetPc[update_index] <= id_update_targetPc_i;
                        end
                        STRONG_TAKEN    : begin
                            pd_history[update_index] <= STRONG_TAKEN;
                            pd_targetPc[update_index] <= id_update_targetPc_i;
                        end
                    endcase
                end else begin
                    case (update_history)
                        STRONG_NOT_TAKEN: pd_history[update_index] <= STRONG_NOT_TAKEN;
                        WEAK_NOT_TAKEN  : pd_history[update_index] <= STRONG_NOT_TAKEN;
                        WEAK_TAKEN      : pd_history[update_index] <= STRONG_NOT_TAKEN;
                        STRONG_TAKEN    : pd_history[update_index] <= WEAK_TAKEN;
                    endcase
                end
            end else if(~stall) begin
                pd_history[update_index] <= STRONG_NOT_TAKEN;
            end
        end
    end

endmodule


/*

#				    |<--      20ns     -->|
#					 __________	           __________            __________            __________
# 		CLK 	____|          |__________|          |__________|          |__________|          |__________

*/