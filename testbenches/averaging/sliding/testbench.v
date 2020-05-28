`timescale 1ns/1ns
`define TESTBENCH
`define TOP_V

`include "averaging/sliding.v"


module test;

initial $dumpvars;

// Test signals
reg clock = 0;
always #1 clock <= ~clock;

reg reset = 0;
initial #1 reset <= 1;
initial #2 reset <= 0;

reg[11:0] value = 0;
initial #1 value <= 12'd256;

// End of test
initial #100 $finish;


average_sliding #(
        .bitwidth_sample(12),
        .initial_accumulator_value()
        )
    average (
        .reset(reset),
        .trigger(clock),

        .sample_value(value),
        .averaged_value()
        );


endmodule
