`timescale 1ns/1ns
`define TESTBENCH
`define TOP_V

`include "averaging/stimulus.v"
`include "averaging/cycled.v"


module test;

initial $dumpvars;

// Test signals
reg clock = 0;
always #1 clock <= ~clock;

reg clock2 = 1;
always #30 clock2 <= ~clock2;

// End of test
initial #100 $finish;


/*
 * Here we generate the adder control signals
 */
wire clock_adder = clock;
wire clock_pi_control = clock2;

wire clear, add, show;

averaging_stimulus #(
        .sample_count(4)
        )
    stimulus (
        .reset(clock_pi_control),
        .clock(clock_adder),

        .clear(clear),
        .add(add),
        .show(show)
        );


/*
 * Here we calculate an example mean value
 */
reg[3:0] test_value;
initial #0  test_value = 4'b0101;
initial #8  test_value = 4'b0111;
initial #12 test_value = 4'b0001;
initial #16 test_value = 4'b0110;

average #(
        .bitwidth_sample(4),
        .bitwidth_accumulator(6)
        )
    average0 (
        .sample_value(test_value),
        // .mean_value(mean_value),

        .clear(clear),
        .add(add),
        .show(show)
        );


endmodule
