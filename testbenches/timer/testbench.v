
`timescale 1ns/1ns
`define TESTBENCH

`include "common/counter.v"
`include "common/timer.v"


module test;

initial $dumpvars;

// Simulate 12 MHz quartz
reg clock = 0;
always #1 clock <= ~clock;

// Trigger a measurement
reg trigger = 0;
initial #3 trigger <= 1;
initial #7 trigger <= 0;

// End of test signal generation
initial #150 $finish;


wire[7:0] count;
counter #(
    .counter_overflow   (20),
    .bitwidth           (8)
    )
    counter0 (
        .clock      (clock),
        .reset      (1'b0),
        .start      (trigger),
        .stop       (1'b0),
        .count      (count),
        .overflow   ()
        );

timer #(
    .bitwidth(8)
    )
    timer0 (
        .clock                      (clock),
        .reset                      (1'b0),
        .counter                    (count),
        .tick_number_rising_edge    (8'd10),
        .tick_number_falling_edge   (8'd15),
        .generated_signal           ()
        );

endmodule
