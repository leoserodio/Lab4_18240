/** FILE
 *  chip_interface.sv
 *
 *  BRIEF
 *  This is a chip interface couples mastermindVGA.sv with the 40MHz clk
 *  to drive the VGA and a 200 MHz clk to drive the VGA to hdmi input.
 *  Includes HDMI_TX & clk_wizard for a proper HDMI output
 *  for the AMD FPGA.
 *
 *  This includes a couple 'TO DO:'s that students should fill out
 *  to properly connect with their mastermind
 *
 *  AUTHOR
 *  Angie Shere (ashere)
 *
 */


// `default_nettype none


module ChipInterface (
    input  logic        CLOCK_100,
    input  logic [ 3:0] BTN,
    input  logic [15:0] SW,
    output logic [ 3:0] D2_AN, D1_AN,
    output logic [ 7:0] D2_SEG, D1_SEG,
    output logic        hdmi_clk_n, hdmi_clk_p,
    output logic [ 2:0] hdmi_tx_p, hdmi_tx_n,
    output logic [15:0] LD
    );

    //TO DO:
    // - Include your game here!
    // - 2Declare connecting wires/signals to/from your game
    // - Use those wires/signals to connect to the MastermindVGA and
    //   EightSevenSegmentDisplays modules below

    // new code that delays guess:
    logic master_ready_d;

    always_ff @(posedge clk_40MHz or posedge reset_sync) begin
        if (reset_sync)
            master_ready_d <= 0;
        else
            master_ready_d <= master_ready;
    end
    // end of new code

    logic [11:0] guess, masterPattern;
    logic [3:0]  znarly, zood, credit, roundNumber, numGames;

    logic        master_ready;
    logic        enough, space, max_rounds, more_rounds, correct;
    logic        round_clear, cl_all, inc_game, adding, cl_z, round_en, gameWon;
    logic        gradeIt;
    logic        startGame;

    logic        loadGuess, loadNumGames, loadZnarlyZood;
    logic        clearGame, displayMasterPattern;
    logic game_clear;

    assign guess                = SW[11:0];
    //assign gradeIt              = BTN[3];
    //assign loadGuess            = BTN[3];
    //assign loadZnarlyZood       = BTN[3];
    assign loadNumGames         = 1;
    assign clearGame            = reset_sync | (startGame & correct) | (startGame & max_rounds) ; // new line
    assign displayMasterPattern = 1'b1;//000gameWon | max_rounds;

    // EDGE DETECTION SECTION
    logic btn1_prev, btn2_prev, btn3_prev;
    logic btn1_pulse, btn2_pulse, btn3_pulse;

    always_ff @(posedge clk_40MHz or posedge reset_sync) begin
        if (reset_sync) begin
            btn1_prev  <= 0;
            btn2_prev  <= 0;
            btn3_prev  <= 0;
            btn1_pulse <= 0;
            btn2_pulse <= 0;
            btn3_pulse <= 0;
        end
        else begin
            // pulses (rising edge)
            btn1_pulse <= BTN[1] & ~btn1_prev;
            btn2_pulse <= BTN[2] & ~btn2_prev;
            btn3_pulse <= BTN[3] & ~btn3_prev;

            // store previous
            btn1_prev <= BTN[1];
            btn2_prev <= BTN[2];
            btn3_prev <= BTN[3];
        end
    end

    assign startGame = btn2_pulse;
    assign gradeIt   = btn3_pulse & master_ready_d;
    assign loadGuess = btn3_pulse & master_ready_d;
    assign loadZnarlyZood = btn3_pulse & master_ready_d;
    // END OF EDGE DETECTION SECTION



    //  Previous logic
    logic fsm_inc_game, coin_inc_game,
          inc_game_comb, adding_comb, fsm_adding, coin_adding;
    /*
    assign inc_game_comb = fsm_inc_game | coin_inc_game;
    assign inc_game = inc_game_comb;
    assign adding_comb = coin_inc_game ? 1'b1 : fsm_adding;
    assign adding = adding_comb;
    */

    // new logic
    assign inc_game_comb = fsm_inc_game | coin_inc_game;
    always_comb begin
        adding_comb = fsm_adding;  // default

        if (coin_inc_game)
            adding_comb = 1'b1;

        if (fsm_inc_game)
            adding_comb = fsm_adding; // FSM overrides
    end
    assign inc_game = inc_game_comb;
    assign adding = adding_comb;


    // NEW LOGIC
    /*
    logic fsm_inc_game, coin_inc_game,
          inc_game_comb, adding_comb,
          fsm_adding, coin_adding;
    always_comb begin
         if (fsm_inc_game && coin_inc_game) begin
             inc_game_comb = 1'b0;
             adding_comb   = 1'b0;
         end
         else if (fsm_inc_game) begin
             inc_game_comb = 1'b1;
             adding_comb   = 1'b0;
         end
         else if (coin_inc_game) begin
             inc_game_comb = 1'b1;
             adding_comb   = 1'b1;
         end
         else begin
             inc_game_comb = 1'b0;
             adding_comb   = fsm_adding;
         end
    end
         */


    // END OF NEW LOGIC



    grader GRADER (
        .guess(guess),
        .masterPattern(masterPattern),
        .znarly(znarly),
        .zood(zood),
        //.GradeIt(gradeIt),
        .cl_z(cl_z),
        .clock(clk_40MHz)
    );

    Select_Pattern SELECT_PATTERN (
        .ShapeLocation(SW[4:3]),
        .LoadShape(SW[2:0]),
        //.guess(guess),
        .cl_all(cl_all),
        .LoadShapeNow(btn3_pulse),
        .clock(clk_40MHz),
        .reset(reset_sync),
        .master_ready(master_ready),
        .masterPattern(masterPattern)
    );

    gameCounter GAME_COUNTER (
        .clock(clk_40MHz),
        .adding(adding_comb),
        .inc_game(inc_game_comb),
        .game_clear(game_clear | reset_sync),
        .inc_round(round_en),
        .round_clear(round_clear), // was round_clear
        .znarly(znarly),
        .enough(enough),
        .space(space),
        .max_rounds(max_rounds),
        .more_rounds(more_rounds),
        .correct(correct),
        .roundNumber(roundNumber),
        .numGames(numGames),
        .master_ready(master_ready) // added this line
    );

    FSM CONTROL (
        .clock(clk_40MHz),
        .reset(reset_sync),
        .startGame(btn2_pulse),
        .enough(enough),
        .master_ready(master_ready),
        .gradeIt(gradeIt),
        .correct(correct),
        .more_rounds(more_rounds),
        .max_rounds(max_rounds),
        .round_clear(round_clear),
        .cl_all(cl_all),
        .inc_game(fsm_inc_game),
        .adding(fsm_adding),
        .cl_z(cl_z),
        .round_en(round_en),
        .gameWon(gameWon),
        .cur_state(cur_state)
    );

    coinFSM COIN_FSM (
        .credit(credit),
        .game_clear(game_clear),
        .space(space), // added this signal
        .inc_game(coin_inc_game),
        .adding(coin_adding), // was coin_adding
        .cv(SW[15:14]),
        .coinInserted(btn1_pulse),
        .clock(clk_40MHz),
        .reset(reset_sync)
    );

/*
 *  BEWARE CHANGING CODE BELOW THIS LINE !!!!!game_clear!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 *
 *  You will need to connect your signals to these modules by changing what
 *  is written in the ( ... ) parenthesis places.  You shouldn't have to make
 *  any other changes than those connections.
 */

    // Don't change these signals
    logic [7:0] VGA_R, VGA_G, VGA_B;
    logic       VGA_BLANK_N, VGA_CLK, VGA_SYNC_N;
    logic       VGA_VS, VGA_HS;
    logic       reset_sync;

    MastermindVGA mmVGA(.clk_40MHz,
                        .VGA_R,
                        .VGA_G,
                        .VGA_B,
                        .VGA_BLANK_N,
                        .VGA_CLK,
                        .VGA_SYNC_N,
                        .VGA_VS,
                        .VGA_HS,
                        .reset(reset_sync),
                        .numGames(numGames),
                        .loadNumGames(loadNumGames),
                        .roundNumber(roundNumber),
                        .guess(guess),
                        .loadGuess(loadGuess),
                        .znarly(znarly),
                        .zood(zood),
                        .clearGame(clearGame),
                        .masterPattern(masterPattern),
                        .displayMasterPattern(displayMasterPattern),
                        .loadZnarlyZood(loadZnarlyZood)
                       );

    EightSevenSegmentDisplays displays(.HEX7(4'h0),
                                       .HEX6(4'h0),
                                       .HEX5(4'h0),
                                       .HEX4(4'h0),
                                       .HEX3(znarly),
                                       .HEX2(zood),
                                       .HEX1(roundNumber),
                                       .HEX0(numGames),
                                       .CLOCK_100,
                                       .reset(reset_sync),
                                       .dec_points(8'b0),
                                       .blank(8'b0),
                                       .D2_AN,
                                       .D1_AN,
                                       .D2_SEG,
                                       .D1_SEG
                                      );

    Synchronizer sync_reset(.async(BTN[0]),
                            .clock(clk_40MHz),
                            .sync(reset_sync)
                           );

    /*
    assign LD[0]    = gameWon;
    assign LD[15:1] = 15'b0;
    */ // old code
    logic [3:0] cur_state;

    assign LD[0] = gameWon;
    assign LD[1] = round_en;
    assign LD[2] = round_clear;
    assign LD[3] = cl_all;
    assign LD[4] = startGame;
    assign LD[5] = gradeIt;
    assign LD[6] = btn3_pulse;
    assign LD[7] = enough;
    assign LD[8] = adding;
    assign LD[9] = fsm_adding;
    assign LD[10] = (cur_state == 3'd0); // INIT
    assign LD[11] = (cur_state == 3'd1); // CP
    assign LD[12] = (cur_state == 3'd2); // Grade
    assign LD[13] = (cur_state == 3'd3); // RD
    assign LD[14] = (cur_state == 3'd4); // Win
    assign LD[15] = (cur_state == 3'd5); // Lose
    // INIT, CHOOSE_PATTERN, GRADE,ROUND_DONE, WIN, LOSE

/*
 *  DO NOT EDIT CODE BELOW THIS LINE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 *  If you do, the Zorgmeister will Zzzzzt you!
 */

    logic clk_40MHz, clk_200MHz;
    logic locked;

    // 2 clk freq outputs
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_40MHz),
        .clk_out2(clk_200MHz),
        .reset(1'b0),
        .locked(locked),
        .clk_in1(CLOCK_100)
    );

    //convert sigs from VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //clk and reset
        .pix_clk(clk_40MHz),
        .pix_clkx5(clk_200MHz),
        .pix_clk_locked(locked),

        .rst(reset_sync),

        //color and sync Signals
        .red(VGA_R),
        .green(VGA_G),
        .blue(VGA_B),

        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .vde(VGA_BLANK_N),

        //differential outputs
        .TMDS_CLK_P(hdmi_clk_p),
        .TMDS_CLK_N(hdmi_clk_n),
        .TMDS_DATA_P(hdmi_tx_p),
        .TMDS_DATA_N(hdmi_tx_n)
    );

endmodule : ChipInterface
