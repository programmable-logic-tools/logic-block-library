/**
 * This module generates a configurable sequence of two pulses
 * for double pulse semiconductor testing.
 * It requires an external counter with matching bit width,
 * which starts upon a start signal and won't reload upon overflow.
 */

`ifndef DOUBLEPULSE_V
`define DOUBLEPULSE_V

`include "../pwm/pulse.v"

module doublepulse
    #(
        /**
         * Bit width of counter and tick numer registers
         */
        parameter bitwidth = 32
        )
    (
        input clock,
        input reset,

        // Input from external counter
        input [bitwidth-1:0] counter,

        // Pulse timings
        input [bitwidth-1:0] tick_number_on1,
        input [bitwidth-1:0] tick_number_off1,
        input [bitwidth-1:0] tick_number_on2,
        input [bitwidth-1:0] tick_number_off2,

        // Generated signal output
        output reg gate_signal
        );


/**
 * Generate the leading pulse
 */
wire pulse1;
pulse #(
        .bitwidth                   (bitwidth)
    )
    pulse_leading (
        .clock                      (clock),
        .reset                      (reset),
        .counter                    (counter[bitwidth-1:0]),
        .tick_number_rising_edge    (tick_number_on1 [bitwidth-1:0]),
        .tick_number_falling_edge   (tick_number_off1[bitwidth-1:0]),
        .generated_signal           (pulse1)
        );

/**
 * Generate the trailing pulse
 */
wire pulse2;
pulse #(
        .bitwidth                   (bitwidth)
    )
    pulse_trailing (
        .clock                      (clock),
        .reset                      (reset),
        .counter                    (counter[bitwidth-1:0]),
        .tick_number_rising_edge    (tick_number_on2 [bitwidth-1:0]),
        .tick_number_falling_edge   (tick_number_off2[bitwidth-1:0]),
        .generated_signal           (pulse2)
        );


/*
 * Combine the two pulses
 */
always @(clock)
begin
    if (reset == 1)
        gate_signal <= 0;
    else begin
        gate_signal <= pulse1 || pulse2;
    end
end


endmodule

`endif
