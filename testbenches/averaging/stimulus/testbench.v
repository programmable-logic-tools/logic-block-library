`timescale 1ns/1ns
`define TESTBENCH
`define TOP_V

`include "averaging/stimulus.v"


module test;

initial $dumpvars;

// Test signals
reg clock = 0;
always #1 clock <= ~clock;

reg clock2 = 1;
always #30 clock2 <= ~clock2;

// End of test
initial #100 $finish;


wire clock_adder = clock;
wire clock_pi_control = clock2;

wire clear, add, show;

averaging_stimulus #(
        .sample_count(9)
        )
    stimulus (
        .reset(clock_pi_control),
        .clock(clock_adder),

        .clear(clear),
        .add(add),
        .show(show)
        );


endmodule
