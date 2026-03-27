
//`default_nettype none

module FSM
  (input logic clock, reset,
  input logic startGame, enough,
  master_ready, gradeIt, correct,
  more_rounds, max_rounds,
  output logic round_clear, cl_all, inc_game,
  adding, cl_z, round_en, gameWon,
  output logic [2:0] cur_state
  );

  enum logic [2:0] {INIT = 3'd0, CHOOSE_PATTERN = 3'd1, GRADE = 3'd2,
                    ROUND_DONE = 3'd3, WIN = 3'd4, LOSE = 3'd5} current_state, next_state;

  assign cur_state = current_state;
  always_ff @(posedge clock, posedge reset)
    if(reset)
      current_state <= INIT;
    else
      current_state <= next_state;

  always_comb begin
    next_state  = current_state;
    round_clear = 0;
    cl_all      = 0;
    inc_game    = 0;
    adding      = 0;
    cl_z        = 0;
    round_en    = 0;
    gameWon     = 0;
    unique case(current_state)
      INIT: begin
        //state
        if(startGame & enough) next_state = CHOOSE_PATTERN;
        else next_state = INIT;
        //output
        //cl_z = 1;
        round_clear = (~startGame) ? 1 : 0;
        cl_all = (startGame & enough) ? 1 : 0;
        inc_game = (startGame & enough) ? 1 : 0;
        adding = (startGame & enough) ? 0 : 1;
      end
      CHOOSE_PATTERN: begin
        next_state = (master_ready) ? GRADE : CHOOSE_PATTERN;
      end
      GRADE: begin
        next_state = (gradeIt) ? ROUND_DONE : GRADE;
        //cl_z = (gradeIt) ? 0 : 1;
        //round_en = (gradeIt) ? 1 : 0; removed this
      end
      ROUND_DONE: begin
        //next state logic
        if(~correct & more_rounds)
          next_state = GRADE;
        else if(~correct & max_rounds)
          next_state = LOSE;
        else
          next_state = WIN;

        //output logic
        round_en = 1; // added this
        cl_z = 0;
        if(~correct & max_rounds)
          gameWon = 0;
        else if(correct)
          gameWon = 1;
      end
      LOSE: begin
        if(~startGame) next_state = LOSE;
        else if(startGame & ~enough) next_state = INIT;
        else next_state = CHOOSE_PATTERN;

        if(~startGame)
          gameWon = 0;
        else if(startGame & enough) begin
          adding = 0;
          cl_all = 1;
          inc_game = 1;
          round_clear = 1; // added this new line
        end
      end

      WIN: begin
        if(~startGame) next_state = WIN;
        else if(startGame & ~enough) next_state = INIT;
        else next_state = CHOOSE_PATTERN;

        if(~startGame)
          gameWon = 1;
        else if(startGame & enough) begin
          adding = 0;
          cl_all = 1;
          inc_game = 1;
          round_clear = 1; // added this new line
        end
      end
    endcase
  end

endmodule : FSM



/* new
module FSM
  (input logic clock, reset,
  input logic startGame, enough,
  master_ready, gradeIt, correct,
  more_rounds, max_rounds,
  output logic round_clear, cl_all, inc_game,
  adding, cl_z, round_en, gameWon
 // output logic [2:0] cur_state
  );

  enum logic [2:0] {INIT, CHOOSE_PATTERN, GRADE,
                    ROUND_DONE, WIN, LOSE} current_state, next_state;


  always_ff @(posedge clock, posedge reset)
    if(reset)
      current_state <= INIT;
    else
      current_state <= next_state;

  always_comb begin
    next_state  = current_state;
    round_clear = 0;
    cl_all      = 0;
    inc_game    = 0;
    adding      = 0;
    cl_z        = 0;
    round_en    = 0;
    gameWon     = 0;
    unique case(current_state)
      INIT: begin
        //state
        next_state = ~enough ? INIT : CHOOSE_PATTERN;
        //output
        //cl_z = 1;
        round_clear = (enough) ? 1 : 0;
        cl_all = (enough) ? 1 : 0;
        inc_game = (enough) ? 1 : 0;
        adding = (enough) ? 0 : 1;

      end
      CHOOSE_PATTERN: begin
        next_state = (master_ready & startGame) ? GRADE : CHOOSE_PATTERN;
      end
      GRADE: begin
        next_state = (gradeIt) ? ROUND_DONE : GRADE;
        //cl_z = (gradeIt) ? 0 : 1;
        round_en = (gradeIt) ? 1 : 0;
      end
      ROUND_DONE: begin
        //next state logic
        if(~correct & more_rounds)
          next_state = GRADE;
        else if(~correct & max_rounds)
          next_state = LOSE;
        else
          next_state = WIN;

        //output logic
          cl_z = 0;
        if(~correct & max_rounds)
          gameWon = 0;
        else if(correct)
          gameWon = 1;
      end
            LOSE: begin
        if(~startGame) next_state = LOSE;
        else if(startGame & ~enough) next_state = INIT;
        else next_state = CHOOSE_PATTERN;

        if(~startGame)
          gameWon = 0;
        else if(startGame & enough) begin
          adding = 0;
          cl_all = 1;
          inc_game = 1;
          round_clear = 1; // added this new line
        end
      end

      WIN: begin
        if(~startGame) next_state = WIN;
        else if(startGame & ~enough) next_state = INIT;
        else next_state = CHOOSE_PATTERN;

        if(~startGame)
          gameWon = 1;
        else if(startGame & enough) begin
          adding = 0;
          cl_all = 1;
          inc_game = 1;
          round_clear = 1; // added this new line
        end
      end
    endcase
  end

endmodule : FSM
*/
