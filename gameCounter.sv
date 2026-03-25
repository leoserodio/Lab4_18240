`default_nettype none

module gameCounter
  (input  logic        clock,
   input  logic        inc_game,
   input  logic        game_clear,
   input  logic        inc_round,
   input  logic        round_clear,
   input  logic [3:0]  num_rounds,
   input  logic [3:0]  znarly,
   output logic        enough,
   output logic        space,
   output logic        max_rounds,
   output logic        more_rounds,
   output logic        correct);

   logic [3:0] NumGames, Round_Number;

   // compare NumGames to 7
   MagComp #(4) SPACE_CHECK (.A(NumGames), .B(4'd7), .AeqB(), .AltB(space), .AgtB());

   // count number of games
   Counter #(4) GAME_COUNTER (.D(4'd0), .Q(NumGames),
       .en(inc_game), .clear(game_clear), .load(1'b0),
       .up(1'b1), .clock(clock));

   // compare NumGames to 0
   MagComp #(4) ENOUGH_CHECK (.A(NumGames), .B(4'd0),
       .AeqB(), .AltB(), .AgtB(enough));

   // count round number
   Counter #(4) ROUND_COUNTER (.D(4'd0), .Q(Round_Number),
       .en(inc_round), .clear(round_clear), .load(1'b0),
       .up(1'b1), .clock(clock));

   // compare Round_Number to num_rounds
   MagComp #(4) ROUND_CHECK (.A(Round_Number), .B(num_rounds),
       .AeqB(max_rounds), .AltB(more_rounds), .AgtB());

   // check if znarly is 4
   Comparator #(4) WIN_CHECK (.A(znarly), .B(4'd4), .AeqB(correct));

endmodule : gameCounter

module gameCounter_test();
  logic        clock, inc_game, game_clear;
  logic        inc_round, round_clear;
  logic [3:0]  num_rounds, znarly;
  logic        enough, space, max_rounds, more_rounds, correct;

  gameCounter dut(.clock, .inc_game, .game_clear,
                  .inc_round, .round_clear, .num_rounds,
                  .znarly, .enough, .space,
                  .max_rounds, .more_rounds, .correct);

  // clock generator - was missing before!
  always #5 clock = ~clock;

  initial begin
    clock       = 1'b0;
    inc_game    = 1'b0;
    game_clear  = 1'b0;
    inc_round   = 1'b0;
    round_clear = 1'b0;
    num_rounds  = 4'd8;
    znarly      = 4'd0;

    // clear to known state
    game_clear = 1'b1; round_clear = 1'b1;
    @(posedge clock); #1;
    game_clear = 1'b0; round_clear = 1'b0;
    @(posedge clock); #1;

    // ---- GAME COUNTER TESTS ----
    $display("=== Game Counter Tests ===");
    $display("");

    $display("NumGames=0   should be enough=0 space=1");
    $display("got   enough=%0b space=%0b", enough, space);
    $display("");

    $display("inc_game x1  should be enough=1 space=1");
    inc_game = 1'b1; @(posedge clock); #1; inc_game = 1'b0; @(posedge clock); #1;
    $display("got   enough=%0b space=%0b", enough, space);
    $display("");

    $display("inc_game x6  should be enough=1 space=0");
    repeat(6) begin inc_game = 1'b1; @(posedge clock); #1; inc_game = 1'b0; @(posedge clock); #1; end
    $display("got   enough=%0b space=%0b", enough, space);
    $display("");

    $display("game_clear   should be enough=0 space=1");
    game_clear = 1'b1; @(posedge clock); #1; game_clear = 1'b0; @(posedge clock); #1;
    $display("got   enough=%0b space=%0b", enough, space);
    $display("");

    // ---- ROUND COUNTER TESTS ----
    $display("=== Round Counter Tests (num_rounds=8) ===");
    $display("");

    $display("Round=0      should be more_rounds=1 max_rounds=0");
    $display("got   more_rounds=%0b max_rounds=%0b", more_rounds, max_rounds);
    $display("");

    $display("inc_round x7 should be more_rounds=1 max_rounds=0");
    repeat(7) begin inc_round = 1'b1; @(posedge clock); #1; inc_round = 1'b0; @(posedge clock); #1; end
    $display("got   more_rounds=%0b max_rounds=%0b", more_rounds, max_rounds);
    $display("");

    $display("inc_round x1 should be more_rounds=0 max_rounds=1");
    inc_round = 1'b1; @(posedge clock); #1; inc_round = 1'b0; @(posedge clock); #1;
    $display("got   more_rounds=%0b max_rounds=%0b", more_rounds, max_rounds);
    $display("");

    $display("round_clear  should be more_rounds=1 max_rounds=0");
    round_clear = 1'b1; @(posedge clock); #1; round_clear = 1'b0; @(posedge clock); #1;
    $display("got   more_rounds=%0b max_rounds=%0b", more_rounds, max_rounds);
    $display("");

    // ---- WIN CHECK TESTS ----
    $display("=== Win Check Tests ===");
    $display("");

    $display("znarly=0     should be correct=0");
    znarly = 4'd0; #1;
    $display("got   correct=%0b", correct);
    $display("");

    $display("znarly=3     should be correct=0");
    znarly = 4'd3; #1;
    $display("got   correct=%0b", correct);
    $display("");

    $display("znarly=4     should be correct=1");
    znarly = 4'd4; #1;
    $display("got   correct=%0b", correct);
    $display("");

    $display("znarly=5     should be correct=0");
    znarly = 4'd5; #1;
    $display("got   correct=%0b", correct);
    $display("");

    $finish;:Q
  end
endmodule : gameCounter_test
