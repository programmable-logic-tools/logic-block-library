`timescale 1ns/1ns
`define TESTBENCH

`include "../follower.v"


module test;

parameter bitwidth= 8;

initial $dumpvars;

// Simulate 12 MHz quartz
reg clock = 0;
always #1 clock <= ~clock;
reg clock_1_2 = 0;
always #2 clock_1_2 <= ~clock_1_2;

reg[bitwidth-1:0] value = 5;
initial #16 value <= 12;
initial #32 value <= 2;

// End of test signal generation
initial #60 $finish;


follower #(
    .bitwidth(bitwidth),
    .initial_value(0)
    ) mut (
        .clock(clock),
        .target_value(value)
        );


endmodule
