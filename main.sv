module MastermindVGA (
input logic clk_40MHz ,
// VGA display signals -- route directly to HDMI IP
output logic [7:0] VGA_R , VGA_G , VGA_B ,
output logic VGA_BLANK_N , VGA_CLK , VGA_SYNC_N ,
output logic VGA_VS , VGA_HS ,
// game information
input logic [3:0] numGames ,
input logic loadNumGames ,
// Items for a particular round
input logic [3:0] roundNumber ,
input logic [11:0] guess ,
input logic loadGuess ,
input logic [3:0] znarly , zood ,
input logic loadZnarlyZood ,
input logic clearGame ,
// master patterns
input logic [11:0] masterPattern ,
input logic displayMasterPattern ,
// other
input logic reset
);

endmodule: MastermindVGA