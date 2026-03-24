`default_nettype none

module Comparator
  # (parameter WIDTH=4)
  (input logic [WIDTH-1:0] A, B,
  output logic AeqB);

  assign AeqB = A == B;

endmodule: Comparator

module MagComp
  # (parameter WIDTH=4)
  (input logic [WIDTH-1:0] A, B,
  output logic AltB, AeqB, AgtB);

   assign AltB = A < B;
   assign AeqB = A == B;
   assign AgtB = A > B;

endmodule: MagComp

module Adder
  # (parameter WIDTH=4)
  (input logic cin,
  input logic [WIDTH-1:0] A, B,
  output logic cout,
  output logic [WIDTH-1:0] sum);

  assign {cout, sum} = A + B + cin;

endmodule: Adder

module Subtracter
  # (parameter WIDTH=4)
  (input logic bin,
  input logic [WIDTH-1:0] A, B,
  output logic bout,
  output logic [WIDTH-1:0] diff);

  assign {bout, diff} = A - B - bin;

endmodule: Subtracter

module Multiplexer
  # (parameter WIDTH=8)
  (input logic [WIDTH-1:0] I,
  input logic [$clog2(WIDTH)-1:0] S,
  output logic Y);

   assign Y = I[S];

endmodule: Multiplexer

module Mux2to1
  # (parameter WIDTH=8)
  (input logic [WIDTH-1:0] I0, I1,
  input logic S,
  output logic [WIDTH-1:0] Y);

  assign Y = (S) ? I1 : I0;

endmodule: Mux2to1

module Decoder
  # (parameter WIDTH=8)
  (input logic [$clog2(WIDTH)-1:0] I,
  input logic en,
  output logic [WIDTH-1:0] D);

  always_comb begin
    D = 'b0;
    if (en == 1'b1)
      D[I] = 1'b1;
  end

endmodule: Decoder

module BarrelShifter
  (input logic [15:0] V,
  input logic [3:0] by,
  output logic [15:0] S);

   assign S = V << by;

endmodule: BarrelShifter

module DFlipFlop
  (input logic D, clock, reset_L, preset_L,
  output logic Q);

  always_ff @(posedge clock, negedge reset_L, negedge preset_L)
    if (~reset_L)
      Q <= 1'b0;
    else if(~preset_L)
      Q <= 1'b1;
    else
      Q <= D;

endmodule: DFlipFlop

module Register
  # (parameter WIDTH = 8)
  (input logic en, clear, clock,
  input logic [WIDTH-1:0] D,
  output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if(en)
      Q <= D;
    else if(clear)
      Q <= 0;  

endmodule: Register

module Counter
  # (parameter WIDTH = 8)
  (input logic en, clear, load, up, clock,
  input logic [WIDTH-1:0] D,
  output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if(clear)
      Q <= 0;
    else if(load)
      Q <= D;
    else if(en)
      if(up) Q <= Q + 1'b1;
      else Q <= Q - 1'b1;

endmodule: Counter

module Synchronizer
(input logic async, clock,
  output logic sync);

  logic metastable;

  //preset and reset both high for hold
  DFlipFlop one(.D(async), .clock, .reset_L(1'b1), 
                .preset_L(1'b1), .Q(metastable));
  DFlipFlop two(.D(metastable), .clock, .reset_L(1'b1), 
                .preset_L(1'b1), .Q(sync));

endmodule: Synchronizer

module ShiftRegisterPIPO
  # (parameter WIDTH=8)
  (input logic en, left, load, clock,
  input logic [WIDTH-1:0] D, 
  output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if(load)
      Q <= D;
    else if(en)
      if(left) Q <= Q << 1;
      else Q <= Q >> 1;

endmodule: ShiftRegisterPIPO

module ShiftRegisterSIPO
  # (parameter WIDTH=8)
  (input logic en, left, serial, clock,
  output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if(en)
      if(left) Q <= {Q[WIDTH-2:0], serial};
      else Q <= {serial, Q[WIDTH-1:1]};

endmodule: ShiftRegisterSIPO

module BarrelShiftRegister
  # (parameter WIDTH=8)
  (input logic en, load, clock,
  input logic [1:0] by,
  input logic [WIDTH-1:0] D,
  output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if(load)
      Q <= D;
    else if(en)
      Q <= Q << by;

endmodule: BarrelShiftRegister

module BusDriver
  # (parameter WIDTH=16)
  (input logic en,
  input logic [WIDTH-1:0] data,
  output logic [WIDTH-1:0] buff,
  inout tri logic [WIDTH-1:0] bus);

  assign buff = bus;
  assign bus = (en) ? data : 'bz;

endmodule: BusDriver

module Memory
  # (parameter WIDTH = 256, AW = $clog2(WIDTH), DW = 16)
  (input logic re, we, clock,
  input logic [AW-1:0] addr,
  inout tri logic [DW-1:0] data);
  
  //memory array
  logic [DW-1:0] M[WIDTH];
  logic [DW-1:0] rData;

  assign rData = M[addr];
  /*
  is this the same as 
  always_comb rData = M[addr]?
  */
  assign data = (re) ? rData : 'bz;

  always_ff @(posedge clock)
    if(we)
      M[addr] <= data;

endmodule: Memory



