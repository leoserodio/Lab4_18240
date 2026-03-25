`default_nettype none

module coinFSM
    (output logic [3:0] credit,
     output logic       inc_game,
     output logic       adding,
     input  logic [1:0] cv,
     input  logic       coinInserted,  // added
     input  logic       clock, reset);

    enum logic [2:0] {START, ONE, TWO, THREE, PERF_DROP, DROP_ONE, DROP_TWO, DROP_THREE} currState, nextState;

    always_ff @(posedge clock, posedge reset) begin
        if (reset)
            currState <= START;
        else
            currState <= nextState;
    end

    always_comb begin
        nextState = currState;
        case (currState)
            START: begin
                if (coinInserted) begin  // gate with coinInserted
                    if      (cv == 2'b01 || cv == 2'b11) nextState = ONE;
                    else if (cv == 2'b10)                nextState = THREE;
                end
            end
            ONE: begin
                if (coinInserted) begin
                    if      (cv == 2'b01 || cv == 2'b11) nextState = DROP_TWO;
                    else if (cv == 2'b10)                nextState = PERF_DROP;
                end
            end
            TWO: begin
                if (coinInserted) begin
                    if      (cv == 2'b01 || cv == 2'b11) nextState = DROP_THREE;
                    else if (cv == 2'b10)                nextState = DROP_ONE;
                end
            end
            THREE: begin
                if (coinInserted) begin
                    if      (cv == 2'b01 || cv == 2'b11) nextState = PERF_DROP;
                    else if (cv == 2'b10)                nextState = DROP_TWO;
                end
            end
            PERF_DROP:  nextState = START;
            DROP_ONE:   nextState = ONE;
            DROP_TWO:   nextState = TWO;
            DROP_THREE: nextState = THREE;
            default:    nextState = START;
        endcase
    end
    
    // output logic unchanged
    always_comb begin
        credit   = 4'd0;
        inc_game = 1'b0;
        adding   = 1'b1;
        unique case (currState)
            START:      credit = 4'd0;
            ONE:        credit = 4'd1;
            TWO:        credit = 4'd2;
            THREE:      credit = 4'd3;
            PERF_DROP:  begin credit = 4'd0; inc_game = 1'b1; end
            DROP_ONE:   begin credit = 4'd1; inc_game = 1'b1; end
            DROP_TWO:   begin credit = 4'd2; inc_game = 1'b1; end
            DROP_THREE: begin credit = 4'd3; inc_game = 1'b1; end
            default:    begin credit = 4'd0; inc_game = 1'b0; adding = 1'b1; end
        endcase
    end

endmodule : coinFSM
