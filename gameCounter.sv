`default_nettype none

module gameCounter
  (input  logic        clock,
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

   logic [3:0] NumGames;
   assign numGames = NumGames;
   

   // compare NumGames to 7
   MagComp #(4) SPACE_CHECK (.A(NumGames), .B(4'd7), .AeqB(), .AltB(space), .AgtB());

   // count number of games
   Counter #(4) GAME_COUNTER (.D(4'd0), .Q(NumGames),
       .en(inc_game), .clear(game_clear), .load(1'b0),
       .up(adding), .clock(clock));

   // compare NumGames to 0
   MagComp #(4) ENOUGH_CHECK (.A(NumGames), .B(4'd0),
       .AeqB(), .AltB(), .AgtB(enough));

   Counter #(4) ROUND_COUNTER (.D(4'd0), .Q(roundNumber),
       .en(inc_round), .clear(round_clear), .load(1'b0),
       .up(1'b1), .clock(clock));

   // compare roundNumber to num_rounds
   MagComp #(4) ROUND_CHECK (.A(roundNumber), .B(4'd8),
       .AeqB(max_rounds), .AltB(more_rounds), .AgtB());

   // check if znarly is 4
   Comparator #(4) WIN_CHECK (.A(znarly), .B(4'd4), .AeqB(correct));

endmodule : gameCounter


/*
module gameCounter_test();

  logic       clock, inc_game, game_clear;
  logic       inc_round, round_clear;
  logic [3:0] num_rounds, znarly;
  logic [3:0] roundNumber, numGames;
  logic       enough, space, max_rounds, more_rounds, correct;

  gameCounter dut(.clock, .inc_game, .game_clear,
                  .inc_round, .round_clear, .num_rounds,
                  .znarly, .enough, .space,
                  .max_rounds, .more_rounds, .correct,
                  .roundNumber, .numGames);

  always #5 clock = ~clock;

  initial begin
    clock       = 1'b0;
    inc_game    = 1'b0;
    game_clear  = 1'b0;
    inc_round   = 1'b0;
    round_clear = 1'b0;
    num_rounds  = 4'd8;
    znarly      = 4'd0;

    game_clear  = 1'b1;
    round_clear = 1'b1;
    @(posedge clock); #1;
    game_clear  = 1'b0;
    round_clear = 1'b0;
    #1;

    $display("NumGames=%0d   enough=%0b space=%0b", numGames, enough, space);

    inc_game = 1'b1;
    @(posedge clock); #1;
    inc_game = 1'b0;
    #1;
    $display("NumGames=%0d   enough=%0b space=%0b", numGames, enough, space);

    repeat (6) begin
      inc_game = 1'b1;
      @(posedge clock); #1;
      inc_game = 1'b0;
      #1;
    end
    $display("NumGames=%0d   enough=%0b space=%0b", numGames, enough, space);

    game_clear = 1'b1;
    @(posedge clock); #1;
    game_clear = 1'b0;
    #1;
    $display("After clear NumGames=%0d   enough=%0b space=%0b", numGames, enough, space);

    $display("Round=%0d    more_rounds=%0b max_rounds=%0b",
             roundNumber, more_rounds, max_rounds);

    repeat (7) begin
      inc_round = 1'b1;
      @(posedge clock); #1;
      inc_round = 1'b0;
      #1;
    end
    $display("Round=%0d    more_rounds=%0b max_rounds=%0b",
             roundNumber, more_rounds, max_rounds);

    inc_round = 1'b1;
    @(posedge clock); #1;
    inc_round = 1'b0;
    #1;
    $display("Round=%0d    more_rounds=%0b max_rounds=%0b",
             roundNumber, more_rounds, max_rounds);

    round_clear = 1'b1;
    @(posedge clock); #1;
    round_clear = 1'b0;
    #1;
    $display("Round=%0d    more_rounds=%0b max_rounds=%0b",
             roundNumber, more_rounds, max_rounds);

    znarly = 4'd0; #1;
    $display("znarly=0     correct=%0b", correct);

    znarly = 4'd3; #1;
    $display("znarly=3     correct=%0b", correct);

    znarly = 4'd4; #1;
    $display("znarly=4     correct=%0b", correct);

    znarly = 4'd5; #1;
    $display("znarly=5     correct=%0b", correct);

    $finish;
  end

endmodule : gameCounter_test
*/
