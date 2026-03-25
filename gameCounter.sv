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

