`timescale 1ns/1ns
`define TESTBENCH

`include "counter/counter.v"


module test;

initial $dumpvars;

localparam bitwidth = 8;


/*
 * Generate test signals
 *
 * Verify:
 * 1. The counter shall not count, before being started.
 * 2. The counter shall starts counting, as soon as a high level occurs on the start signal.
 *  a) Being high for one clock period shall be sufficient.
 *  b) Being high for several clock periods shall not delay the startpoint of counting.
 * 3. The counter shall stop counting, as soon as a high level occurs on the stop signal.
 * 4. While the reset signal is high, the counter shall pause counting and reset the count value to zero.
 *    As soon as reset goes low again, the counter shall resume counting.
 * 5. When start_resets_counting (default is disabled) is enabled, it shall do as such.
 */
reg clock = 0;
always #1 clock <= ~clock;

reg start1 = 0;
initial #7 start1 <= 1;
initial #9 start1 <= 0;

reg start2 = 0;
initial #7 start2 <= 1;
initial #20 start2 <= 0;

reg stop3 = 0;
initial #19 stop3 <= 1;
initial #25 stop3 <= 0;

reg reset4 = 0;
initial #19 reset4 <= 1;
initial #25 reset4 <= 0;

reg start5 = 0;
initial #7 start5 <= 1;
initial #11 start5 <= 0;
initial #17 start5 <= 1;
initial #23 start5 <= 0;

reg start7 = 0;
initial #7 start7 <= 1;
initial #9 start7 <= 0;
initial #49 start7 <= 1;
initial #51 start7 <= 0;

reg stop7 = 0;
initial #91 stop7 <= 1;
initial #93 stop7 <= 0;

// End of test signal generation
initial #150 $finish;

reg[bitwidth-1:0] counter_overflow = 12;


/*
 * The effect of a short start signal
 */
counter #(
    .bitwidth       (bitwidth)
    )
    counter1 (
        .clock      (clock),
        .reset      (1'b0),
        .overflow_value (counter_overflow),
        .start      (start1),
        .stop       (1'b0)
        );

/*
 * The effect of a long start signal
 */
counter #(
    .bitwidth       (bitwidth)
    )
    counter2 (
        .clock      (clock),
        .reset      (1'b0),
        .overflow_value (counter_overflow),
        .start      (start2),
        .stop       (1'b0)
        );

/*
 * The effect of a stop signal
 */
counter #(
    .bitwidth       (bitwidth)
    )
    counter3 (
        .clock      (clock),
        .reset      (1'b0),
        .overflow_value (counter_overflow),
        .start      (start2),
        .stop       (stop3)
        );

/*
 * The effect of a reset signal
 */
counter #(
    .bitwidth       (bitwidth)
    )
    counter4 (
        .clock      (clock),
        .reset      (reset4),
        .overflow_value (counter_overflow),
        .start      (start2),
        .stop       (1'b0)
        );

/*
 * The effect of an untimely start signal
 */
counter #(
    .bitwidth               (bitwidth),
    .start_resets_counting  (0)
    )
    counter5 (
        .clock      (clock),
        .reset      (1'b0),
        .overflow_value (counter_overflow),
        .start      (start5),
        .stop       (1'b0)
        );

/*
 * Counter with start as counter reset
 */
counter #(
    .bitwidth               (bitwidth),
    .start_resets_counting  (1)
    )
    counter6 (
        .clock      (clock),
        .reset      (1'b0),
        .overflow_value (counter_overflow),
        .start      (start5),
        .stop       (1'b0)
        );

/*
 * Counter with autoreload enabled
 */
reg autoreload = 0;
initial #40 autoreload <= 1;
initial #100 autoreload <= 0;
counter #(
    .bitwidth                   (bitwidth),
    .enable_autoreload_input    (1)
    )
    counter7 (
        .clock      (clock),
        .reset      (1'b0),
        .autoreload (autoreload),
        .overflow_value (counter_overflow),
        .start      (start7),
        .stop       (stop7)
        );

/*
 * Counter with autostart enabled
 */
reg autostart = 0;
initial #60 autostart <= 1;
counter #(
    .bitwidth                   (bitwidth),
    .enable_autostart_input     (1),
    .enable_autoreload_input    (1)
    )
    counter8 (
        .clock      (clock),
        .reset      (1'b0),
        .autostart  (autostart),
        .autoreload (autoreload),
        .overflow_value (counter_overflow),
        .start      (1'b0),
        .stop       (1'b0)
        );

/*
 * Reloading the counter with different values
 */
reg[bitwidth-1:0] overflow_value = 12;
initial #70 overflow_value <= 8;
initial #90 overflow_value <= 5;
initial #110 overflow_value <= 1;
initial #130 overflow_value <= 0;
counter #(
    .bitwidth                   (bitwidth),
    .enable_autoreload_input    (1)
    )
    counter9 (
        .clock          (clock),
        .reset          (1'b0),
        .autoreload     (1'b1),
        .overflow_value (counter_overflow),
        .start          (start1),
        .stop           (1'b0)
        );


endmodule
