`timescale 1ns/1ns
`define TESTBENCH

`include "common/counter.v"


module test;

initial $dumpvars;

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

reg stop7 = 0;
initial #91 stop7 <= 1;
initial #93 stop7 <= 0;

// End of test signal generation
initial #150 $finish;

localparam counter_overflow = 12;

/*
 * The effect of a short start signal
 */
counter #(
    .counter_overflow(counter_overflow)
    )
    counter1 (
        .clock      (clock),
        .reset      (1'b0),
        .start      (start1),
        .stop       (1'b0)
        );

/*
 * The effect of a long start signal
 */
counter #(
    .counter_overflow(counter_overflow)
    )
    counter2 (
        .clock      (clock),
        .reset      (1'b0),
        .start      (start2),
        .stop       (1'b0)
        );

/*
 * The effect of a stop signal
 */
counter #(
    .counter_overflow(counter_overflow)
    )
    counter3 (
        .clock      (clock),
        .reset      (1'b0),
        .start      (start2),
        .stop       (stop3)
        );

/*
 * The effect of a reset signal
 */
counter #(
    .counter_overflow(counter_overflow)
    )
    counter4 (
        .clock      (clock),
        .reset      (reset4),
        .start      (start2),
        .stop       (1'b0)
        );

/*
 * The effect of an untimely start signal
 */
counter #(
    .counter_overflow(counter_overflow),
    .start_resets_counting(0)
    )
    counter5 (
        .clock      (clock),
        .reset      (1'b0),
        .start      (start5),
        .stop       (1'b0)
        );

/*
 * Counter with start as counter reset
 */
counter #(
    .counter_overflow(counter_overflow),
    .start_resets_counting(1)
    )
    counter6 (
        .clock      (clock),
        .reset      (1'b0),
        .start      (start5),
        .stop       (1'b0)
        );

/*
 * Counter with autoreload enabled
 */
counter #(
    .counter_overflow(counter_overflow),
    .autoreload(1)
    )
    counter7 (
        .clock      (clock),
        .reset      (1'b0),
        .start      (start1),
        .stop       (stop7)
        );

/*
 * Counter with autostart enabled
 */
counter #(
    .counter_overflow(counter_overflow),
    .autostart(1),
    .autoreload(1)
    )
    counter8 (
        .clock      (clock),
        .reset      (1'b0),
        .start      (start1),
        .stop       (stop7)
        );


endmodule
