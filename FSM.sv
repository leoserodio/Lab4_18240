module FSM
  (input logic clock, reset_L,
  input logic startGame, enough,
  master_ready, gradeIt, correct, 
  more_rounds, max_rounds,
  output logic round_clear, cl_all, inc_game, 
  adding, cl_z, round_en, gameWon);

  enum logic [2:0] {INIT, CHOOSE_PATTERN, GRADE, 
                    ROUND_DONE, WIN, LOSE} current_state, next_state;


  always_ff @(posedge clock, negedge reset_L)
    if(~reset_L)
      current_state <= INIT;
    else
      current_state <= next_state;


  always_comb begin
    case(current_state)
      INIT: begin
        //state
        next_state = (~startGame | (startGame & ~enough)) ? INIT : CHOOSE_PATTERN;
        //output
        round_clear = (~startGame) ? 1 : 0;
        cl_all = (startGame & enough) ? 1 : 0;
        inc_game = (startGame & enough) ? 1 : 0;
        adding = (startGame & enough) ? 0 : 1;

      end 
      CHOOSE_PATTERN: begin
        next_state = (master_ready) ? GRADE : CHOOSE_PATTERN;
        cl_all = (~master_ready) ? 0 : 1;
      end
      GRADE: begin
        next_state = (gradeIt) ? ROUND_DONE : GRADE;
        cl_z = (gradeIt) ? 0 : 1;
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
        if(~correct & max_rounds)
          gameWon = 0;
        else if(correct)
          gameWon = 1;
      end 
      LOSE: begin
        //next state logic
        if(~startGame) next_state = LOSE;
        else if(startGame & ~enough) next_state = INIT;
        else next_state = CHOOSE_PATTERN;

        //output logic
        if(~startGame) gameWon = 0;
        else if(startGame & enough)
          adding = 0;
          cl_all = 1;
          inc_game = 1;
      end
      WIN: begin
        //next state logic
        if(~startGame) next_state = WIN;
        else if(startGame & ~enough) next_state = INIT;
        else next_state = CHOOSE_PATTERN;

        //output logic
        if(~startGame) gameWon = 1;
        else if(startGame & enough)
          adding = 0;
          cl_all = 1;
          inc_game = 1;


      end
      
    endcase

  end


endmodule: FSM