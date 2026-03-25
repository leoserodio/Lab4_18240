`default_nettype none
module Select_Pattern
  (input logic [1:0] ShapeLocation,
  input logic [2:0] LoadShape,
  input logic [11:0] guess,
  input logic cl_all,
  input logic LoadShapeNow, clock, reset_L,
  output logic master_ready,
  output logic [11:0] masterPattern);

logic [3:0] select;
Decoder #(4) Decode(.I(ShapeLocation), .en(1'b1), .D(select));

//register signals
logic mp3_en, mp2_en, mp1_en, mp0_en;

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
Comparator #(3) Comp3(.A(mp3), .B(3'd0), .AeqB(check3));
Comparator #(3) Comp2(.A(mp2), .B(3'd0), .AeqB(check2));
Comparator #(3) Comp1(.A(mp1), .B(3'd0), .AeqB(check1));
Comparator #(3) Comp0(.A(mp0), .B(3'd0), .AeqB(check0));

assign mp3_en = select[3] & check3 & LoadShapeNow;
assign mp2_en = select[2] & check2 & LoadShapeNow;
assign mp1_en = select[1] & check1 & LoadShapeNow;
assign mp0_en = select[0] & check0 & LoadShapeNow;

//concatenate masterPattern
assign masterPattern = {mp3, mp2, mp1, mp0};

//all shapes are loaded
assign master_ready = ~(check3 | check2 | check1 | check0); //check this logic again
                

endmodule: Select_Pattern

//need to make a test bench to test the idea that all registers 
//are not cleared within the fsm, then master ready outputs 1 appropriately.

module tb_pattern;

  logic [1:0] ShapeLocation;
  logic [2:0] LoadShape;
  logic [11:0] guess;
  logic LoadShapeNow, clock, reset_L, cl_all;
  logic master_ready;
  logic [11:0] masterPattern;

  Select_Pattern dut(.*);

  initial begin
    $monitor($time, " MP=%12b ready=%b loc=%b shape=%b lsn=%b cl=%b",
      masterPattern, master_ready, ShapeLocation, LoadShape, LoadShapeNow, cl_all);

    clock = 0;
    reset_L = 0;
    cl_all = 0;
    reset_L <= 1;
    forever #5 clock = ~clock;
  end

  initial begin
    {ShapeLocation, LoadShape, LoadShapeNow, guess, cl_all} = '0;

    // =========================================================
    // TEST 1: after reset, all zeros, master_ready = 0
    // =========================================================
    cl_all <= 1;
    @(posedge clock);
    cl_all <= 0;
    @(posedge clock);

    // =========================================================
    // TEST 2: load shape at position 0 — tetrahedron (001)
    // =========================================================
    ShapeLocation <= 2'b00; LoadShape <= 3'b001; LoadShapeNow <= 1;
    @(posedge clock);
    LoadShapeNow <= 0;
    @(posedge clock);

    // =========================================================
    // TEST 3: load shape at position 1 — cube (010)
    // =========================================================
    ShapeLocation <= 2'b01; LoadShape <= 3'b010; LoadShapeNow <= 1;
    @(posedge clock);
    LoadShapeNow <= 0;
    @(posedge clock);

    // =========================================================
    // TEST 4: attempt overwrite of position 0 — should be ignored
    // =========================================================
    ShapeLocation <= 2'b00; LoadShape <= 3'b110; LoadShapeNow <= 1;
    @(posedge clock);
    LoadShapeNow <= 0;
    @(posedge clock);

    // =========================================================
    // TEST 5: load positions 2 and 3 — master_ready should go high
    // =========================================================
    ShapeLocation <= 2'b10; LoadShape <= 3'b101; LoadShapeNow <= 1;
    @(posedge clock);
    LoadShapeNow <= 0;
    @(posedge clock);

    ShapeLocation <= 2'b11; LoadShape <= 3'b100; LoadShapeNow <= 1;
    @(posedge clock);
    LoadShapeNow <= 0;
    @(posedge clock);

    // =========================================================
    // TEST 6: LoadShapeNow=0 — no load even with valid inputs
    // =========================================================
    ShapeLocation <= 2'b00; LoadShape <= 3'b110; LoadShapeNow <= 0;
    @(posedge clock);
    @(posedge clock);

    // =========================================================
    // TEST 7: cl_all clears all registers, master_ready drops
    // =========================================================
    cl_all <= 1;
    @(posedge clock);
    cl_all <= 0;
    @(posedge clock);

    // =========================================================
    // TEST 8: reload in non-sequential order (3, 1, 0, 2)
    // =========================================================
    ShapeLocation <= 2'b11; LoadShape <= 3'b110; LoadShapeNow <= 1;
    @(posedge clock);
    LoadShapeNow <= 0;
    @(posedge clock);

    ShapeLocation <= 2'b01; LoadShape <= 3'b011; LoadShapeNow <= 1;
    @(posedge clock);
    LoadShapeNow <= 0;
    @(posedge clock);

    ShapeLocation <= 2'b00; LoadShape <= 3'b001; LoadShapeNow <= 1;
    @(posedge clock);
    LoadShapeNow <= 0;
    @(posedge clock);

    ShapeLocation <= 2'b10; LoadShape <= 3'b101; LoadShapeNow <= 1;
    @(posedge clock);
    LoadShapeNow <= 0;
    @(posedge clock);

    $finish;
  end





endmodule: tb_pattern