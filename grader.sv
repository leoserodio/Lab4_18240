`default_nettype none

module grader
  (input  logic [11:0] guess, masterPattern,
   output logic [3:0]  znarly,
   output logic [3:0]  zood,
   input  logic cl_z, clock);

   // constant masterPattern value
   

   // Comparator C (A, B, AeqB)                  
   // Adder      A (A, B, cin, sum, cout) 

   logic       match1, match2, match3, match4;
   logic [3:0] sum_1, sum_2, znarly_count;

   // *****************************  Znarly Logic  ***************************** \\        
   // Start with 4 3-bit comparators:
   // This logic will check if guess has the same shape 
   // in the same position as masterPattern for each shape
   // match 1
   Comparator #(3) MATCH1 (.A(masterPattern[11:9]), .B(guess[11:9]), .AeqB(match1));
   // match 2
   Comparator #(3) MATCH2 (.A(masterPattern[8:6]), .B(guess[8:6]), .AeqB(match2));
   // match 3
   Comparator #(3) MATCH3 (.A(masterPattern[5:3]), .B(guess[5:3]), .AeqB(match3));
   // match 4
   Comparator #(3) MATCH4 (.A(masterPattern[2:0]), .B(guess[2:0]), .AeqB(match4));

   // Add the number of equal shapes in equal positions
   // sum 1
   Adder #(4) SUM1 (.A({3'b000, match1}), .B({3'b000, match2}), .cin(1'b0), .sum(sum_1), .cout());
   // sum 2
   Adder #(4) SUM2 (.A({3'b000, match3}), .B({3'b000, match4}), .cin(1'b0), .sum(sum_2), .cout());
   // znarly_count
   Adder #(4) ZNARLY (.A(sum_1), .B(sum_2), .cin(1'b0), .sum(znarly_count), .cout());
   
   // **************************  End of Znarly Logic  ************************** \\  


   // ******************************  Zood Logic  ******************************* \\  
   // 16 comparators
   // Visual representation of the comparisons:
   // M1-M2-M3-M4 (masterPattern)
   // G1-G2-G3-G4 (guess)
   // We will compare G1 with M1 then G1 with M2 etc...

   logic g1m1, g1m2, g1m3, g1m4;
   logic g2m1, g2m2, g2m3, g2m4;
   logic g3m1, g3m2, g3m3, g3m4;
   logic g4m1, g4m2, g4m3, g4m4;

   Comparator #(3) G1M1 (.A(guess[11:9]), .B(masterPattern[11:9]), .AeqB(g1m1));
   Comparator #(3) G1M2 (.A(guess[11:9]), .B(masterPattern[8:6]),  .AeqB(g1m2));
   Comparator #(3) G1M3 (.A(guess[11:9]), .B(masterPattern[5:3]),  .AeqB(g1m3));
   Comparator #(3) G1M4 (.A(guess[11:9]), .B(masterPattern[2:0]),  .AeqB(g1m4));

   Comparator #(3) G2M1 (.A(guess[8:6]),  .B(masterPattern[11:9]), .AeqB(g2m1));
   Comparator #(3) G2M2 (.A(guess[8:6]),  .B(masterPattern[8:6]),  .AeqB(g2m2));
   Comparator #(3) G2M3 (.A(guess[8:6]),  .B(masterPattern[5:3]),  .AeqB(g2m3));
   Comparator #(3) G2M4 (.A(guess[8:6]),  .B(masterPattern[2:0]),  .AeqB(g2m4));

   Comparator #(3) G3M1 (.A(guess[5:3]),  .B(masterPattern[11:9]), .AeqB(g3m1));
   Comparator #(3) G3M2 (.A(guess[5:3]),  .B(masterPattern[8:6]),  .AeqB(g3m2));
   Comparator #(3) G3M3 (.A(guess[5:3]),  .B(masterPattern[5:3]),  .AeqB(g3m3));
   Comparator #(3) G3M4 (.A(guess[5:3]),  .B(masterPattern[2:0]),  .AeqB(g3m4));

   Comparator #(3) G4M1 (.A(guess[2:0]),  .B(masterPattern[11:9]), .AeqB(g4m1));
   Comparator #(3) G4M2 (.A(guess[2:0]),  .B(masterPattern[8:6]),  .AeqB(g4m2));
   Comparator #(3) G4M3 (.A(guess[2:0]),  .B(masterPattern[5:3]),  .AeqB(g4m3));
   Comparator #(3) G4M4 (.A(guess[2:0]),  .B(masterPattern[2:0]),  .AeqB(g4m4));

   logic usedm1, usedm2, usedm3, usedm4;
   logic z1, z2, z3, z4;
   logic [3:0] zood_sum1, zood_sum2, zood_count;

   always_comb begin
      usedm1 = match1;
      usedm2 = match2;
      usedm3 = match3;
      usedm4 = match4;

      z1 = 1'b0;
      z2 = 1'b0;
      z3 = 1'b0;
      z4 = 1'b0;

      // handle guess 1 for Zood
      // only if not already Znarly
      // try m2, then m3, then m4 (priority)
      // only one match per guess slot
      // master slots get locked after use
      if (!match1) begin
         if (!usedm2 && g1m2) begin
            z1 = 1'b1;
            usedm2 = 1'b1;
         end
         else if (!usedm3 && g1m3) begin
            z1 = 1'b1;
            usedm3 = 1'b1;
         end
         else if (!usedm4 && g1m4) begin
            z1 = 1'b1;
            usedm4 = 1'b1;
         end
      end

      // handle guess 2 for Zood
      // skip if already Znarly
      // try m1, then m3, then m4
      // only one match per guess slot
      // master slots get locked after use
      if (!match2) begin
         if (!usedm1 && g2m1) begin
            z2 = 1'b1;
            usedm1 = 1'b1;
         end
         else if (!usedm3 && g2m3) begin
            z2 = 1'b1;
            usedm3 = 1'b1;
         end
         else if (!usedm4 && g2m4) begin
            z2 = 1'b1;
            usedm4 = 1'b1;
         end
      end
      // handle guess 3 for Zood
      // only if not Znarly
      // try m1, then m2, then m4
      // only one match per guess slot
      // master slots get locked after use
      if (!match3) begin
         if (!usedm1 && g3m1) begin
            z3 = 1'b1;
            usedm1 = 1'b1;
         end
         else if (!usedm2 && g3m2) begin
            z3 = 1'b1;
            usedm2 = 1'b1;
         end
         else if (!usedm4 && g3m4) begin
            z3 = 1'b1;
            usedm4 = 1'b1;
         end
      end
      // handle guess 4 for Zood
      // skip if already Znarly
      // try m1, then m2, then m3
      // only one match per guess slot
      // master slots get locked after use
      if (!match4) begin
         if (!usedm1 && g4m1) begin
            z4 = 1'b1;
            usedm1 = 1'b1;
         end
         else if (!usedm2 && g4m2) begin
            z4 = 1'b1;
            usedm2 = 1'b1;
         end
         else if (!usedm3 && g4m3) begin
            z4 = 1'b1;
            usedm3 = 1'b1;
         end
      end
   end

   Adder #(4) ZOOD1 (.A({3'b000, z1}), .B({3'b000, z2}), .cin(1'b0), .sum(zood_sum1), .cout());
   Adder #(4) ZOOD2 (.A({3'b000, z3}), .B({3'b000, z4}), .cin(1'b0), .sum(zood_sum2), .cout());
   Adder #(4) ZOOD3 (.A(zood_sum1), .B(zood_sum2), .cin(1'b0), .sum(zood_count), .cout());

   // **************************  End of Zood Logic  **************************** \\  

   // Return Znarly and Zood
   //assign znarly = GradeIt ? znarly_count : 4'b0000;
   //assign zood   = GradeIt ? zood_count   : 4'b0000;

   Register #(4) ZOOD_REG (.D(zood_count), .Q(zood), .clock, .en(1), .clear(cl_z));
   Register #(4) ZNARLY_REG (.D(znarly_count), .Q(znarly), .clock, .en(1), .clear(cl_z));
endmodule : grader



// ****************************  grader testbench  ****************************** \\

module grader_test;

  logic [11:0] guess;
  logic [11:0] masterPattern;
  logic [3:0]  znarly;
  logic [3:0]  zood;
  logic        clock;
  logic        cl_z;

  grader dut(.guess, .masterPattern, .znarly, .zood, .cl_z, .clock);

  initial clock = 0;
  always #5 clock = ~clock;

  initial begin
    $monitor($time,,
             "cl_z=%b master=%b guess=%b znarly=%0d zood=%0d",
             cl_z, masterPattern, guess, znarly, zood);

    masterPattern = 12'b001010011100;
    guess = 0;
    cl_z = 1;

    #10 cl_z = 0;

    @(negedge clock) guess = 12'b001010011100; #1; // exact
    @(posedge clock);

    @(negedge clock) guess = 12'b010001100011; #1; // all wrong place
    @(posedge clock);

    @(negedge clock) guess = 12'b001010100011; #1; // 2/2 split
    @(posedge clock);

    @(negedge clock) guess = 12'b001100010110; #1; // mixed
    @(posedge clock);

    @(negedge clock) guess = 12'b001001001001; #1; // duplicates
    @(posedge clock);

    @(negedge clock) guess = 12'b110110110110; #1; // no match
    @(posedge clock);

    @(negedge clock) guess = 12'b010010010010; #1; // repeat symbol
    @(posedge clock);

    @(negedge clock) guess = 12'b100011010001; #1; // reverse-ish
    @(posedge clock);

    @(negedge clock) guess = 12'b001011011100; #1; // 3 correct positions
    @(posedge clock);

    @(negedge clock) guess = 12'b000010011100; #1; // 3 correct + 1 off
    @(posedge clock);

    @(negedge clock) guess = 12'b001111011100; #1; // 3 correct + junk
    @(posedge clock);

    @(negedge clock) guess = 12'b011010001100; #1; // shuffled
    @(posedge clock);

    @(negedge clock) cl_z = 1; #1; // clear
    @(posedge clock);

    @(negedge clock) cl_z = 0; guess = 12'b001010011100; #1;
    @(posedge clock);

    @(negedge clock) masterPattern = 12'b101110001011;
                     guess         = 12'b101110001011; #1; // exact new
    @(posedge clock);

    @(negedge clock) guess = 12'b110101011001; #1;
    @(posedge clock);

    @(negedge clock) guess = 12'b101110011000; #1;
    @(posedge clock);

    @(negedge clock) guess = 12'b011001110101; #1;
    @(posedge clock);

    @(negedge clock) guess = 12'b111111111111; #1; // all same
    @(posedge clock);

    @(negedge clock) guess = 12'b000000000000; #1; // all zero
    @(posedge clock);

    #1 $finish;
  end

endmodule : grader_test

// ***********************  end of grader testbench  ************************* \\
