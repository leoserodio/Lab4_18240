`default_nettype none
module Select_Pattern
  (input logic [1:0] ShapeLocation,
  input logic [2:0] LoadShape,
  input logic [11:0] guess,
  input logic LoadShapeNow, clock, reset_L,
  output logic master_ready,
  output logic [11:0] masterPattern);

logic [3:0] select;
Decoder #(4) Decode(.I(ShapeLocation), .en(1'b1), .D(select));

//register signals
logic mp3_en, mp2_en, mp1_en, mp0_en, cl_all;

//3 bit sections of 12 bit pattern
logic [2:0] mp3, mp2, mp1, mp0;
Register #(3) MP3(.en(mp3_en), .clear(cl_all), .clock,
                  .D(LoadShape), .Q(mp3));

Register #(3) MP2(.en(mp2_en), .clear(cl_all), .clock,
                  .D(LoadShape), .Q(mp2));

Register #(3) MP1(.en(mp1_en), .clear(cl_all), .clock,
                  .D(LoadShape), .Q(mp1));

Register #(3) MP0(.en(mp0_en), .clear(cl_all), .clock,
                  .D(LoadShape), .Q(mp0));

//check if all shapes are loaded in 3 bit sections
logic check3, check2, check1, check0;
Comparator #(3) Comp3(.A(mp3), .B('d0), .AeqB(check3));
Comparator #(3) Comp2(.A(mp2), .B('d0), .AeqB(check2));
Comparator #(3) Comp1(.A(mp1), .B('d0), .AeqB(check1));
Comparator #(3) Comp0(.A(mp0), .B('d0), .AeqB(check0));

assign mp3_en = select[3] & check3 & LoadShapeNow;
assign mp2_en = select[2] & check2 & LoadShapeNow;
assign mp1_en = select[1] & check1 & LoadShapeNow;
assign mp0_en = select[0] & check0 & LoadShapeNow;

//concatenate masterPattern
assign masterPattern = {mp3, mp2, mp1, m0};

//all shapes are loaded
assign master_ready = ~(check3 | check2 | check1 | check0); //check this logic again
                

endmodule: Select_Pattern

//need to make a test bench to test the idea that all registers 
//are not cleared within the fsm, then master ready outputs 1 appropriately.