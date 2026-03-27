`default_nettype none

module gameCounter
  (input  logic        clock,
   input  logic        master_ready, // added this
   input  logic        adding,
   input  logic        inc_game,
   input  logic        game_clear,
   input  logic        inc_round,
   input  logic        round_clear,
   input  logic [3:0]  znarly,
   output logic        enough,
   output logic        space,
   output logic        max_rounds,
   output logic        more_rounds,
   output logic        correct,
   output logic [3:0]  roundNumber, numGames);

   
   logic correct_raw;


   // compare numGames to 7
   MagComp #(4) SPACE_CHECK (.A(numGames), .B(4'd7), .AeqB(), .AltB(space), .AgtB());

   // count number of games
   Counter #(4) GAME_COUNTER (.D(4'd0), .Q(numGames),
       .en(inc_game), .clear(game_clear), .load(1'b0),
       .up(adding), .clock(clock));

   // compare numGames to 0
   MagComp #(4) ENOUGH_CHECK (.A(numGames), .B(4'd0),
       .AeqB(), .AltB(), .AgtB(enough));

   Counter #(4) ROUND_COUNTER (.D(4'd0), .Q(roundNumber),
       .en(inc_round), .clear(round_clear), .load(1'b0),
       .up(1'b1), .clock(clock));

   // compare roundNumber to num_rounds
   MagComp #(4) ROUND_CHECK (.A(roundNumber), .B(4'd8),
       .AeqB(max_rounds), .AltB(more_rounds), .AgtB());

   // check if znarly is 4
   Comparator #(4) WIN_CHECK (.A(znarly), .B(4'd4), .AeqB(correct_raw));
   assign correct = correct_raw & master_ready; // added this

endmodule : gameCounter


// ****************************  gamecounter testbench  ****************************** \\

module gameCounter_test;

  logic clock, master_ready, adding;
  logic inc_game, game_clear;
  logic inc_round, round_clear;
  logic [3:0] znarly;

  logic enough, space, max_rounds;
  logic more_rounds, correct;
  logic [3:0] roundNumber, numGames;

  gameCounter dut(
    .clock, .master_ready, .adding, .inc_game, .game_clear,
    .inc_round, .round_clear, .znarly,
    .enough, .space, .max_rounds,
    .more_rounds, .correct,
    .roundNumber, .numGames
  );

  initial clock = 0;
  always #5 clock = ~clock;

  initial begin
    $monitor($time,,
      "ng=%0d rn=%0d en=%b sp=%b more=%b max=%b cor=%b",
      numGames, roundNumber, enough, space,
      more_rounds, max_rounds, correct
    );

    master_ready = 0;
    adding       = 1;
    inc_game     = 0;
    game_clear   = 1;
    inc_round    = 0;
    round_clear  = 1;
    znarly       = 0;

    @(posedge clock);
    game_clear  = 0;
    round_clear = 0;

    @(posedge clock);
    $display("should be: ng=0 en=0 sp=1");

    // count up to 7
    repeat (7) begin
      @(negedge clock) inc_game = 1; adding = 1; #1;
      @(posedge clock);
      @(negedge clock) inc_game = 0; #1;
      @(posedge clock);
    end

    // count down twice
    repeat (2) begin
      @(negedge clock) inc_game = 1; adding = 0; #1;
      @(posedge clock);
      @(negedge clock) inc_game = 0; #1;
      @(posedge clock);
    end

    // clear games
    @(negedge clock) game_clear = 1; #1;
    @(posedge clock);
    @(negedge clock) game_clear = 0; #1;
    @(posedge clock);

    $display("should be: ng=0 en=0 sp=1");

    // count rounds to 8
    repeat (8) begin
      @(negedge clock) inc_round = 1; #1;
      @(posedge clock);
      @(negedge clock) inc_round = 0; #1;
      @(posedge clock);
    end

    // clear rounds
    @(negedge clock) round_clear = 1; #1;
    @(posedge clock);
    @(negedge clock) round_clear = 0; #1;
    @(posedge clock);

    $display("should be: rn=0 more=1 max=0");

    // correct logic tests
    @(negedge clock) znarly = 4'd0; master_ready = 0; #1;
    @(posedge clock);
    $display("should be: cor=0");

    @(negedge clock) znarly = 4'd4; master_ready = 1; #1;
    @(posedge clock);
    $display("should be: cor=1");

    @(negedge clock) znarly = 4'd3; master_ready = 1; #1;
    @(posedge clock);
    $display("should be: cor=0");

    @(negedge clock) znarly = 4'd4; master_ready = 1; #1;
    @(posedge clock);
    $display("should be: cor=1");

    #1 $finish;
  end

endmodule : gameCounter_test

// ***********************  end of gamecounter testbench  ************************* \\
