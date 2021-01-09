`timescale 1ns/1ns

`include "counter.v"
`include "doublepulse.v"

module test;

initial $dumpvars;
localparam bitwidth = 32;
localparam counter_overflow = 1000;

// Simulate 12 MHz quartz
reg clock;
initial clock <= 0;
always #1 clock <= ~clock;

// The PWM outputs must remain low until reset is released
reg reset = 1;
initial #2 reset <= 0;

// End of test signal generation
initial #6000 $finish;


/*
 * Doublepulse configuration
 */
reg[bitwidth-1:0] doublepulse1_on1  = 3;
reg[bitwidth-1:0] doublepulse1_off1 = 10;
reg[bitwidth-1:0] doublepulse1_on2  = 15;
reg[bitwidth-1:0] doublepulse1_off2 = 30;

reg doublepulse_start = 0;
always #20 doublepulse_start <= ~doublepulse_start;

wire[bitwidth-1:0] doublepulse_counter_value;
wire doublepulse_active;
wire doublepulse_complete;


counter #(
        .bitwidth                   (bitwidth),
        .enable_autostart_input     (0),
        .enable_autoreload_input    (0),
        .enable_reset_pulsifier     (0),
        .enable_start_pulsifier     (1),
        .start_resets_counting      (1),
        .enable_stop_pulsifier      (0)
    )
    doublepulse_counter
    (
        .clock      (clock),
        .reset      (1'b0),
        .start      (doublepulse_start),
        .stop       (1'b0),

        .overflow_value (counter_overflow),
        .value          (doublepulse_counter_value),
        .counting       (doublepulse_active),
        .overflow       (doublepulse_complete)
        );


doublepulse #(
        .bitwidth   (bitwidth)
    )
    doublepulse_instance
    (
        .clock      (clock),
        .reset      (reset),

        .counter            (doublepulse_counter_value),
        .tick_number_on1    (doublepulse1_on1),
        .tick_number_off1   (doublepulse1_off1),
        .tick_number_on2    (doublepulse1_on2),
        .tick_number_off2   (doublepulse1_off2),

        .gate_signal    (doublepulse_gate_signal)
        );


endmodule
