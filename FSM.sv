module FSM
  (input logic clock, reset_L,
  input logic startGame, enough,
  master_ready, gradeIt, 
  output logic round_clear, cl_all, inc_game, 
  adding, cl_z, round_en);

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
      end 
      
    endcase

  end


endmodule: FSM