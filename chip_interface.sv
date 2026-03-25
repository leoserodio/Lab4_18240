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
    logic [11:0] guess, masterPattern;
    logic [3:0]  znarly, zood, credit, roundNumber, numGames;

    logic        master_ready;
    logic        enough, space, max_rounds, more_rounds, correct;
    logic        round_clear, cl_all, inc_game_fsm, adding_fsm, cl_z, round_en, gameWon;
    logic        inc_game_coin, adding_coin;
    logic        gradeIt;

    logic        loadGuess, loadNumGames, loadZnarlyZood;
    logic        clearGame, displayMasterPattern;

    assign guess                = SW[11:0];
    assign gradeIt              = BTN[3];
    assign loadGuess            = BTN[3];
    assign loadZnarlyZood       = BTN[3];
    assign loadNumGames         = inc_game_coin;
    assign clearGame            = reset_sync;
    assign displayMasterPattern = gameWon | max_rounds;

    grader GRADER (
        .guess(guess),
        .znarly(znarly),
        .zood(zood),
        .GradeIt(gradeIt),
        .reset(reset_sync),
        .clock(clk_40MHz)
    );

    Select_Pattern SELECT_PATTERN (
        .ShapeLocation(SW[4:3]),
        .LoadShape(SW[2:0]),
        .guess(guess),
        .cl_all(cl_all),
        .LoadShapeNow(BTN[3]),
        .clock(clk_40MHz),
        .reset_L(~reset_sync),
        .master_ready(master_ready),
        .masterPattern(masterPattern)
    );

    gameCounter GAME_COUNTER (
        .clock(clk_40MHz),
        .inc_game(inc_game_coin),
        .game_clear(reset_sync),
        .inc_round(round_en),
        .round_clear(round_clear),
        .num_rounds(4'd8),
        .znarly(znarly),
        .enough(enough),
        .space(space),
        .max_rounds(max_rounds),
        .more_rounds(more_rounds),
        .correct(correct),
        .roundNumber(roundNumber),
        .numGames(numGames)
    );

    FSM CONTROL (
        .clock(clk_40MHz),
        .reset_L(~reset_sync),
        .startGame(BTN[2]),
        .enough(enough),
        .master_ready(master_ready),
        .gradeIt(gradeIt),
        .correct(correct),
        .more_rounds(more_rounds),
        .max_rounds(max_rounds),
        .round_clear(round_clear),
        .cl_all(cl_all),
        .inc_game(inc_game_fsm),
        .adding(adding_fsm),
        .cl_z(cl_z),
        .round_en(round_en),
        .gameWon(gameWon)
    );

    coinFSM COIN_FSM (
        .credit(credit),
        .inc_game(inc_game_coin),
        .adding(adding_coin),
        .cv(SW[15:14]),
        .coinInserted(BTN[1]),
        .clock(clk_40MHz),
        .reset_L(~reset_sync)
    );

/*
 *  BEWARE CHANGING CODE BELOW THIS LINE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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

    assign LD[0]    = gameWon;
    assign LD[15:1] = 15'b0;

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
