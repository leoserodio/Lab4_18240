`default_nettype none

// =============================================================================
// Top-level DUT wrapper — exposes all stimulus signals as proper ports
// so the testbench can drive them cleanly without forcing internal nets.
// =============================================================================
module top (
  input  logic        clock,
  input  logic        reset,
  // coin interface
  input  logic [1:0]  cv,
  input  logic        coinInserted,
  // game control
  input  logic        startGame,
  // pattern loading
  input  logic [1:0]  ShapeLocation,
  input  logic [2:0]  LoadShape,
  input  logic        loadShapeNow,
  // grader
  input  logic [11:0] guess,
  input  logic        gradeIt,
  // observability outputs
  output logic [11:0] masterPattern_obs,  // probe — driven from internal wire
  output logic        master_ready,
  output logic [3:0]  credit,
  output logic        enough,
  output logic        space,
  output logic        max_rounds,
  output logic        more_rounds,
  output logic        correct,
  output logic [3:0]  znarly,
  output logic [3:0]  zood,
  output logic        round_clear,
  output logic        cl_all,
  output logic        inc_game,
  output logic        adding,
  output logic        cl_z,
  output logic        round_en,
  output logic        gameWon
);

  // -------------------------------------------------------------------------
  // inc_game and adding: only FSM CONTROL drives these.
  // coinFSM receives them as inputs so it knows when credit is consumed —
  // it must NOT output them, which would create a multi-driver conflict.
  // -------------------------------------------------------------------------

  // masterPattern must be an internal wire so both Select_Pattern (driver)
  // and grader (reader) can connect to it. The output port is a probe copy.
  logic [11:0] masterPattern;
  assign masterPattern_obs = masterPattern;

  // grader needs masterPattern to compare guess against the secret pattern
  grader GRADER (
    .guess         (guess),
    .masterPattern (masterPattern),
    .znarly        (znarly),
    .zood          (zood),
    .GradeIt       (gradeIt),
    .reset         (reset),
    .clock         (clock)
  );

  Select_Pattern SELECT (
    .ShapeLocation (ShapeLocation),
    .LoadShape     (LoadShape),
    .guess         (guess),
    .cl_all        (cl_all),
    .LoadShapeNow  (loadShapeNow),
    .clock         (clock),
    .reset         (reset),
    .master_ready  (master_ready),
    .masterPattern (masterPattern)
  );

  gameCounter GAME_COUNTER (
    .clock       (clock),
    .inc_game    (inc_game),
    .game_clear  (cl_all),
    .inc_round   (round_en),
    .round_clear (round_clear),
    .num_rounds  (4'd4),
    .znarly      (znarly),
    .enough      (enough),
    .space       (space),
    .max_rounds  (max_rounds),
    .more_rounds (more_rounds),
    .correct     (correct)
  );

  // FSM is the sole driver of inc_game and adding
  FSM CONTROL (
    .clock        (clock),
    .reset        (reset),
    .startGame    (startGame),
    .enough       (enough),
    .master_ready (master_ready),
    .gradeIt      (gradeIt),
    .correct      (correct),
    .more_rounds  (more_rounds),
    .max_rounds   (max_rounds),
    .round_clear  (round_clear),
    .cl_all       (cl_all),
    .inc_game     (inc_game),
    .adding       (adding),
    .cl_z         (cl_z),
    .round_en     (round_en),
    .gameWon      (gameWon)
  );

  // coinFSM has its OWN output ports for inc_game and adding.
  // Connecting them to the same nets as FSM CONTROL causes a multi-driver
  // conflict.  Give coinFSM dedicated sink wires — FSM CONTROL remains the
  // sole driver of the shared inc_game / adding signals used by the rest of
  // the design.
  logic coin_inc_game_nc;   // nc = "not connected to shared net"
  logic coin_adding_nc;

  coinFSM COIN_FSM (
    .credit       (credit),
    .inc_game     (coin_inc_game_nc),
    .adding       (coin_adding_nc),
    .cv           (cv),
    .coinInserted (coinInserted),
    .clock        (clock),
    .reset        (reset)
  );

endmodule : top


// =============================================================================
// Testbench
// =============================================================================
module ultimate_tb;

  // -------------------------------------------------------------------------
  // Testbench signals
  // -------------------------------------------------------------------------
  logic        clock, reset;

  logic [1:0]  cv;
  logic        coinInserted;
  logic        startGame;

  logic [1:0]  ShapeLocation;
  logic [2:0]  LoadShape;
  logic        loadShapeNow;

  logic [11:0] guess;
  logic        gradeIt;

  // observability
  logic [11:0] masterPattern_obs;   // probe output from top
  logic        master_ready;
  logic [3:0]  credit;
  logic        enough, space, max_rounds, more_rounds, correct;
  logic [3:0]  znarly, zood;
  logic        round_clear, cl_all, inc_game, adding, cl_z, round_en, gameWon;

  // -------------------------------------------------------------------------
  // DUT instantiation
  // -------------------------------------------------------------------------
  top dut (
    .clock        (clock),
    .reset        (reset),
    .cv           (cv),
    .coinInserted (coinInserted),
    .startGame    (startGame),
    .ShapeLocation(ShapeLocation),
    .LoadShape    (LoadShape),
    .loadShapeNow (loadShapeNow),
    .guess        (guess),
    .gradeIt      (gradeIt),
    .masterPattern_obs(masterPattern_obs),
    .master_ready (master_ready),
    .credit       (credit),
    .enough       (enough),
    .space        (space),
    .max_rounds   (max_rounds),
    .more_rounds  (more_rounds),
    .correct      (correct),
    .znarly       (znarly),
    .zood         (zood),
    .round_clear  (round_clear),
    .cl_all       (cl_all),
    .inc_game     (inc_game),
    .adding       (adding),
    .cl_z         (cl_z),
    .round_en     (round_en),
    .gameWon      (gameWon)
  );

  // -------------------------------------------------------------------------
  // Clock — 10 ns period
  // -------------------------------------------------------------------------
  initial clock = 1'b0;
  always #5 clock = ~clock;

  // -------------------------------------------------------------------------
  // Monitor
  // -------------------------------------------------------------------------
  initial begin
    $monitor(
      "%0t rst=%b | cv=%b coin=%b start=%b grade=%b | loc=%b shape=%b lsn=%b guess=%12b | MP=%12b mp_ready=%b | credit=%0d enough=%b space=%b maxr=%b morer=%b correct=%b | zn=%0d zo=%0d | round_cl=%b cl_all=%b inc_game=%b adding=%b cl_z=%b round_en=%b gameWon=%b",
      $time,
      reset,
      cv, coinInserted, startGame, gradeIt,
      ShapeLocation, LoadShape, loadShapeNow, guess,
      masterPattern_obs, master_ready,
      credit, enough, space, max_rounds, more_rounds, correct,
      znarly, zood,
      round_clear, cl_all, inc_game, adding, cl_z, round_en, gameWon
    );
  end

  // -------------------------------------------------------------------------
  // Tasks
  // -------------------------------------------------------------------------

  // Insert one coin with value coin_val; pulse lasts one clock cycle
  task automatic pulse_coin (input logic [1:0] coin_val);
    cv          <= coin_val;
    coinInserted <= 1'b1;
    @(posedge clock);
    coinInserted <= 1'b0;
    @(posedge clock);
  endtask

  // Assert startGame for one clock cycle
  task automatic pulse_start;
    startGame <= 1'b1;
    @(posedge clock);
    startGame <= 1'b0;
    @(posedge clock);
  endtask

  // Load a shape into the pattern register at a given location
  task automatic load_shape_at (
    input logic [1:0] loc,
    input logic [2:0] shape
  );
    ShapeLocation <= loc;
    LoadShape     <= shape;
    loadShapeNow  <= 1'b1;
    @(posedge clock);
    loadShapeNow  <= 1'b0;
    @(posedge clock);
  endtask

  // Present shape/location without asserting loadShapeNow (negative test)
  task automatic try_shape_without_load (
    input logic [1:0] loc,
    input logic [2:0] shape
  );
    ShapeLocation <= loc;
    LoadShape     <= shape;
    // loadShapeNow deliberately left de-asserted
    @(posedge clock);
    @(posedge clock);
  endtask

  // Submit a guess and pulse gradeIt for one cycle
  task automatic grade_guess (input logic [11:0] g);
    guess   <= g;
    gradeIt <= 1'b1;
    @(posedge clock);
    gradeIt <= 1'b0;
    @(posedge clock);
  endtask

  // -------------------------------------------------------------------------
  // Stimulus
  // -------------------------------------------------------------------------
  initial begin
    // Initialise all driven signals before reset releases
    guess         <= 12'b0;
    cv            <= 2'b00;
    coinInserted  <= 1'b0;
    startGame     <= 1'b0;
    ShapeLocation <= 2'b00;
    LoadShape     <= 3'b000;
    loadShapeNow  <= 1'b0;
    gradeIt       <= 1'b0;

    // ---- Reset sequence ----
    reset <= 1'b1;
    #2;
    reset <= 1'b0;
    @(posedge clock);

    // ---- Build credit (3 coins: 1-credit, 1-credit, 2-credit) ----
    pulse_coin(2'b01);   // +1 credit
    pulse_coin(2'b01);   // +1 credit
    pulse_coin(2'b10);   // +2 credit  → total = 4, but one used per game

    // ---- Start first game ----
    pulse_start;

    // ---- Load master pattern ----
    load_shape_at(2'b00, 3'b001);          // slot 0 = 001
    load_shape_at(2'b01, 3'b010);          // slot 1 = 010
    load_shape_at(2'b00, 3'b110);          // overwrite slot 0 attempt
    load_shape_at(2'b10, 3'b101);          // slot 2 = 101
    load_shape_at(2'b11, 3'b100);          // slot 3 = 100

    // ---- Negative test: no load ----
    try_shape_without_load(2'b01, 3'b011);

    // ---- Grading rounds ----
    grade_guess(12'b110110110110);
    grade_guess(12'b001010011100);
    grade_guess(12'b110001110001);

    // ---- Second game ----
    pulse_coin(2'b11);   // +3 credit
    pulse_start;

    load_shape_at(2'b11, 3'b110);
    load_shape_at(2'b01, 3'b011);
    load_shape_at(2'b00, 3'b001);
    load_shape_at(2'b10, 3'b101);

    grade_guess(12'b001011101110);
    grade_guess(12'b101101101101);

    repeat (4) @(posedge clock);
    $finish;
  end

endmodule : ultimate_tb
