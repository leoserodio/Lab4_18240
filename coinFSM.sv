`default_nettype none

module coinFSM
    (output logic [3:0] credit,
     output logic       inc_game,
     output logic       adding,
     // took out game_clear
     input  logic [1:0] cv,
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
                if (cv == 2'b01 || cv == 2'b11) nextState = ONE;
                else if (cv == 2'b10)           nextState = THREE;
            end

            ONE: begin
                if (cv == 2'b01 || cv == 2'b11) nextState = DROP_TWO;
                else if (cv == 2'b10)           nextState = PERF_DROP;
            end

            TWO: begin
                if (cv == 2'b01 || cv == 2'b11) nextState = DROP_THREE;
                else if (cv == 2'b10)           nextState = DROP_ONE;
            end

            THREE: begin
                if (cv == 2'b01 || cv == 2'b11) nextState = PERF_DROP;
                else if (cv == 2'b10)           nextState = DROP_TWO;
            end

            PERF_DROP:  nextState = START;
            DROP_ONE:   nextState = ONE;
            DROP_TWO:   nextState = TWO;
            DROP_THREE: nextState = THREE;

            default:    nextState = START;
        endcase
    end

    always_comb begin
        credit     = 4'd0;
        inc_game   = 1'b0;
        // took out game_clear
        adding     = 1'b1;

        unique case (currState)
            START: begin
                credit = 4'd0;
            end

            ONE: begin
                credit = 4'd1;
            end

            TWO: begin
                credit = 4'd2;
            end

            THREE: begin
                credit = 4'd3;
            end

            PERF_DROP: begin
                credit     = 4'd0;
                inc_game   = 1'b1;
                game_clear = 1'b0;
            end

            DROP_ONE: begin
                credit     = 4'd1;
                inc_game   = 1'b1;
                game_clear = 1'b0;
            end

            DROP_TWO: begin
                credit     = 4'd2;
                inc_game   = 1'b1;
                game_clear = 1'b0;
            end

            DROP_THREE: begin
                credit     = 4'd3;
                inc_game   = 1'b1;
                game_clear = 1'b0;
            end

            default: begin
                credit     = 4'd0;
                inc_game   = 1'b0;
                game_clear = 1'b0;
                adding     = 1'b1;
            end
        endcase
    end

endmodule : coinFSM
