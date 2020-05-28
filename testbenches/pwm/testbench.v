`timescale 1ns/1ns

`include "pwm.v"

module test;

initial $dumpvars;

// Simulate 12 MHz quartz
reg clock;
initial clock <= 0;
always #1 clock <= ~clock;

// The PWM outputs must remain low until reset is released
reg reset = 1;
initial #9 reset <= 0;

// End of test signal generation
initial #6000 $finish;


/*
 * Test the generation of all the trigger signals
 */
wire[7:0] count;
wire overflow;
counter #(
        .counter_overflow   (20),
        .autostart          (1),
        .autoreload         (1),
        .bitwidth           (8)
    )
    counter0 (
        .clock      (clock),
        .reset      (reset),
        .count      (count),
        .start      (1'b0),
        .stop       (1'b0),
        .overflow   (overflow)
        );

pwm #(
        .deadtime_hs_to_ls  (3),
        .deadtime_ls_to_hs  (2),
        .tick_count_period  (20),
        .bitwidth           (8)
    )
    pwm0 (
        .clock                  (clock),
        .reset                  (reset),

        .tick_counter           (count),

        .load_enable            (overflow),
        .tick_count_highside    (8'd2),
        .tick_count_lowside     (8'd3)
        );


endmodule
