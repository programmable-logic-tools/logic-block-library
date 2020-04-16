/**
 * This module converts a given signal into a pulse using a given clock
 */

`ifndef PULSIFIER_V
`define PULSIFIER_V

`include "delay.v"

module pulsifier #(
        parameter pulse_duration = 1
    )
    (
        input clock,
        input original_signal,
        output pulsified_signal
        );

/*
 * Use flip-flops to delay the inverted input signal
 */
wire original_signal_inverted_delayed;
delay #(
        .tick_count         (pulse_duration)
    )
    delay_original_signal (
        .clock              (clock),
        .original_signal    (~original_signal),
        .delayed_signal     (original_signal_inverted_delayed)
        );

/*
 * Imply a 2-input lookup table with 3x 0 and 1x 1,
 * in order to reduce the likeliness of glitches.
 */
assign pulsified_signal = original_signal & original_signal_inverted_delayed;

endmodule

`endif
