`include "common.vh"

module predictor (
    input clk_i,
    input rst_i,

    input [`RegW-1:0] if_predict_pc_i,

    output [`RegW-1:0] if_predict_targetPc_o,
    output wire if_predict_taken_o,
    output wire if2idBus_predict_suscess_o,

    input [`RegW-1:0] id_update_targetPc_i,
    input wire id_update_taken_i
);
    parameter NUM_ENTRIES = 64;
    localparam [1:0]
    STRONG_NOT_TAKEN =  2'b00,
    WEAK_NOT_TAKEN   =  2'b01,
    WEAK_TAKEN       =  2'b10,
    STRONG_TAKEN     =  2'b11;

    reg [1:0] state;
    reg [1:0] nxt_state;
    
    /*
        32bit PC
        0x8000_0000～0x803F_FFFF
        [5:2]
        predict 16 instructions
    */
    reg         pd_valid        [NUM_ENTRIES-1:0];
    reg [1:0]   pd_history      [NUM_ENTRIES-1:0];
    reg [31:0]  pd_targetPc     [NUM_ENTRIES-1:0];

    // Index into the predictor table
    wire [7:2] pd_index;
    assign pd_index = if_predict_pc_i[7:2];

    // Current prediction for the branch
    wire [1:0] current_prediction;
    assign current_prediction = pd_history[pd_index];

    // Prediction is valid or not
    wire current_valid;
    assign current_valid = pd_valid[pd_index];

    // Prediction target pc addr
    wire [`RegW-1:0] current_targetPc;
    assign current_targetPc = pd_targetPc[pd_index];

    // Predict whether the branch will be taken or not
    assign if_predict_taken_o           = current_prediction[1];
    assign if_predict_targetPc_o        = current_targetPc;

    wire prediction_isFailed;
    assign prediction_isFailed = current_prediction[1] ^ id_update_taken_i;
    assign if2idBus_predict_suscess_o   = ~prediction_isFailed;

    // Update the predictor based on actual outcome
    always @(posedge clk_i) begin
        if (rst_i) begin
            for (int i = 0; i < NUM_ENTRIES; i = i + 1) begin
                pd_history[i] <= STRONG_NOT_TAKEN;
            end
        end else begin
            if (current_valid) begin
                if (prediction_isFailed) begin
                    // If prediction failed, valid is 0
                    pd_valid[pd_index] <= 1'b0;
                end else begin
                    // else Update as
                    /*
                            T       T       T
                        00 ---> 01 ---> 11 ---> 11

                            F       F       F
                        11 ---> 10 ---> 00 ---> 00
                    */
                    if (id_update_taken_i) begin
                        if (pd_history[pd_index] < STRONG_TAKEN)
                            pd_history[pd_index] <= {pd_history[pd_index][0], 1'b1};
                    end else begin
                        if (pd_history[pd_index] > STRONG_NOT_TAKEN)
                            pd_history[pd_index] <= {pd_history[pd_index][0], 1'b0};
                    end
                end
            end else if (/*!current_valid &&*/ id_update_taken_i) begin
                // Enable valid of this line
                // Reset 2bit counter and Update history Pc addr 
                pd_valid[pd_index] <= 1'b1;
                pd_history[pd_index] <= STRONG_NOT_TAKEN;
                pd_targetPc[pd_index] <= id_update_targetPc_i;
            end /*
            else if (!current_valid && !id_update_taken_i) begin
                // Not update
            end */
        end
    end

endmodule


/*

#				    |<--      20ns     -->|
#					 __________	           __________            __________            __________
# 		CLK 	____|          |__________|          |__________|          |__________|          |__________

*/