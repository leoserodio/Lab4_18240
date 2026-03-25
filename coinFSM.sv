`default_nettype none

module coinFSM
    (output logic [3:0] credit,
     output logic       inc_game,
     output logic       adding,
     input  logic [1:0] cv,
     input  logic       coinInserted,
     input  logic       clock, reset_L);

    enum logic [2:0] {START, ONE, TWO, THREE, PERF_DROP, DROP_ONE, DROP_TWO, DROP_THREE} currState, nextState;

    always_ff @(posedge clock, negedge reset_L) begin
        if (~reset_L)
            currState <= START;
        else
            currState <= nextState;
    end

    always_comb begin
        nextState = currState;
        case (currState)
            START: begin
                if (coinInserted) begin
                    if      (cv == 2'b01) nextState = ONE;       // +1 -> 1
                    else if (cv == 2'b10) nextState = THREE;     // +3 -> 3
                    else if (cv == 2'b11) nextState = DROP_ONE;  // +5 -> drop, 1 left
                end
            end
            ONE: begin
                if (coinInserted) begin
                    if      (cv == 2'b01) nextState = TWO;       // +1 -> 2
                    else if (cv == 2'b10) nextState = PERF_DROP; // +3 -> drop, 0 left
                    else if (cv == 2'b11) nextState = DROP_TWO;  // +5 -> drop, 2 left
                end
            end
            TWO: begin
                if (coinInserted) begin
                    if      (cv == 2'b01) nextState = THREE;     // +1 -> 3
                    else if (cv == 2'b10) nextState = DROP_ONE;  // +3 -> drop, 1 left
                    else if (cv == 2'b11) nextState = DROP_THREE;// +5 -> drop, 3 left
                end
            end
            THREE: begin
                if (coinInserted) begin
                    if      (cv == 2'b01) nextState = PERF_DROP; // +1 -> drop, 0 left
                    else if (cv == 2'b10) nextState = DROP_TWO;  // +3 -> drop, 2 left
                    else if (cv == 2'b11) nextState = PERF_DROP; // +5 -> drop, edge case
                end
            end
            PERF_DROP: begin
                if (coinInserted) begin
                    if      (cv == 2'b01) nextState = ONE; 
                    else if (cv == 2'b10) nextState = THREE;  
                    else if (cv == 2'b11) nextState = DROP_ONE;
                    else                  nextState = START;
                end 
            end
            DROP_ONE: begin
                if (coinInserted) begin
                    if      (cv == 2'b01) nextState = TWO; 
                    else if (cv == 2'b10) nextState = PERF_DROP;  
                    else if (cv == 2'b11) nextState = DROP_TWO;
                    else                  nextState = ONE;
                end 
            end
            DROP_TWO:  begin
                if (coinInserted) begin
                    if      (cv == 2'b01) nextState = THREE; 
                    else if (cv == 2'b10) nextState = DROP_ONE;  
                    else if (cv == 2'b11) nextState = DROP_THREE;
                    else                  nextState = TWO;
                end
            end
            DROP_THREE: begin
                if (coinInserted) begin
                    if      (cv == 2'b01) nextState = PERF_DROP; 
                    else if (cv == 2'b10) nextState = DROP_TWO;  
                    else if (cv == 2'b11) nextState = PERF_DROP;
                    else                  nextState = THREE;
                end
            end
            default:    nextState = START;
        endcase
    end

    always_comb begin
        credit   = 4'd0;
        inc_game = 1'b0;
        adding   = 1'b1;
        unique case (currState)
            START:      begin credit = 4'd0; inc_game = 1'b0; end
            ONE:        begin credit = 4'd1; inc_game = 1'b0; end
            TWO:        begin credit = 4'd2; inc_game = 1'b0; end
            THREE:      begin credit = 4'd3; inc_game = 1'b0; end
            PERF_DROP:  begin credit = 4'd0; inc_game = 1'b1; end
            DROP_ONE:   begin credit = 4'd1; inc_game = 1'b1; end
            DROP_TWO:   begin credit = 4'd2; inc_game = 1'b1; end
            DROP_THREE: begin credit = 4'd3; inc_game = 1'b1; end
            //default:    begin credit = 4'd0; inc_game = 1'b0; adding = 1'b1; end
        endcase
    end

endmodule : coinFSM


module coinFSM_test();
    logic [3:0] credit;
    logic       inc_game;
    logic [1:0] coin;
    logic       clock, reset_L;
    logic       adding;
    logic       coinInserted;

    integer i;

    coinFSM dut(.credit, .inc_game, .adding, .coinInserted,
                .clock, .reset_L, .cv(coin));

    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    initial begin
        $monitor($time,,"state=%-10s credit=%0d coin=%b inc_game=%0b adding=%0b, coin inserted=%b",
                 dut.currState.name(), credit, coin, inc_game, adding, coinInserted);

        // initialize
        coin         <= 2'b00;
        coinInserted <= 1'b0;
        reset_L      <= 1'b0;

        // hold reset for a few cycles
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);

        // release reset
        @(posedge clock);
        reset_L <= 1'b1;

        // insert 4 circles one at a time -> should drop after 4th
        for (i = 0; i < 4; i = i + 1) begin
            coin         <= 2'b01;
            coinInserted <= 1'b1;
            @(posedge clock);
            coinInserted <= 1'b0;
            @(posedge clock);
        end

        // insert triangle (+3) then circle (+1) -> should drop
        coin         <= 2'b10;
        coinInserted <= 1'b1;
        @(posedge clock);
        coinInserted <= 1'b0;
        @(posedge clock);

        coin         <= 2'b01;
        coinInserted <= 1'b1;
        @(posedge clock);
        coinInserted <= 1'b0;
        @(posedge clock);

        // insert pentagon from START -> DROP_ONE (5 mod 4 = 1 left)
        coin         <= 2'b11;
        coinInserted <= 1'b1;
        @(posedge clock);
        coinInserted <= 1'b0;
        @(posedge clock);

        // insert pentagon from ONE -> DROP_TWO (6 mod 4 = 2 left)
        coin         <= 2'b11;
        coinInserted <= 1'b1;
        @(posedge clock);
        coinInserted <= 1'b0;
        @(posedge clock);

        // insert pentagon from TWO -> DROP_THREE (7 mod 4 = 3 left)
        coin         <= 2'b11;
        coinInserted <= 1'b1;
        @(posedge clock);
        coinInserted <= 1'b0;
        @(posedge clock);

        // insert pentagon from THREE -> PERF_DROP (8 mod 4 = 0 left, edge case)
        coin         <= 2'b11;
        coinInserted <= 1'b1;
        @(posedge clock);
        coinInserted <= 1'b0;
        @(posedge clock);

        // no coin inserted -> should stay in START
        coin         <= 2'b01;
        coinInserted <= 1'b0;
        @(posedge clock);
        @(posedge clock);

        // reset mid game
        coin         <= 2'b01;
        coinInserted <= 1'b1;
        @(posedge clock);
        coinInserted <= 1'b0;
        @(posedge clock);

        coin         <= 2'b01;
        coinInserted <= 1'b1;
        @(posedge clock);
        coinInserted <= 1'b0;
        @(posedge clock);

        reset_L <= 1'b0;
        @(posedge clock);
        reset_L <= 1'b1;
        @(posedge clock);
        @(posedge clock);

        #1 $finish;
    end

endmodule : coinFSM_test
