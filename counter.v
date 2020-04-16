/**
 * This module counts upwards from zero with the given clock and
 * provides an overflow signal, when the given overflow value is reached.
 *
 * Please note:
 * In order to avoid unexpected behaviour when instantiating this module,
 * the inputs start, stop and reset should always be connected or tied to a defined level.
 */
`ifndef COUNTER_V
`define COUNTER_V

`include "pulsifier.v"

module counter #(
            /** The counter_overflow parameter configures the number of clock ticks before a counter overflow occurs. */
            parameter counter_overflow = 8,
            parameter bitwidth = $clog2(counter_overflow),

            /**
             * When this parameter is 1, the counter begins counting from zero immediately after startup.
             * autostart does NOT imply autoreload.
             */
            parameter autostart = 0,

            /**
             * When this parameter is 1, the counter does not stop when it overflows, but instead continues counting from zero.
             */
            parameter autoreload = 0,

            /**
             * This parameter configures, whether the counter is reset when receiving start signals while counting (parameter=1),
             * or whether untimely start signals are ignored (parameter=0).
             */
            parameter start_resets_counting = 0,

            /**
             * This parameter configures, whether the start signal is used as is or pulsified internally.
             */
            parameter enable_start_pulsifier = 1,
            parameter start_pulse_duration = 1,

            /**
             * This parameter configures, whether the stop signal is used as is or pulsified internally.
             */
            parameter enable_stop_pulsifier = 1,
            parameter stop_pulse_duration = 1
            )
        (
            /** The clock at which the counter increments */
            input clock,

            /** A high level on the reset signal prevents counting and resets the counter to zero. */
            input reset,

            /** A high level on the start signal for at least one clock tick starts the counter. */
            input start,

            /** A high level on the start signal for at least one clock tick stops the counter. */
            input stop,

            /** A high level on the counting signal indicates, that the counter is currently counting. */
            output reg counting,

            /** For use in other modules or for debugging, the internal counter registers are exposed. */
            output reg[bitwidth-1:0] count,

            /** A rising edge on the overflow signal indicates, that the parameterized number of ticks have elapsed. */
            output reg overflow
            );

initial count <= 0;
initial counting <= 0;
initial overflow <= 0;

/*
 * Pulsify the start signal, if this is configured
 */
wire internal_start;
if (enable_start_pulsifier == 0)
begin
    assign internal_start = start;
end
else begin
    pulsifier #(
        .pulse_duration     (start_pulse_duration)
        )
        pulsify_start (
        .clock              (clock),
        .original_signal    (start),
        .pulsified_signal   (internal_start)
        );
end

/*
 * Pulsify the stop signal, if this is configured
 */
wire internal_stop;
if (enable_stop_pulsifier == 0)
begin
    assign internal_stop = stop;
end
else begin
    pulsifier #(
        .pulse_duration     (stop_pulse_duration)
        )
        pulsify_stop (
        .clock              (clock),
        .original_signal    (stop),
        .pulsified_signal   (internal_stop)
        );
end

/*
 * Decide, whether to count or not
 */
reg autostart_expired = 0;
always @(posedge clock)
begin
    if (counting == 0)
    begin
        if (autostart == 0)
        begin
            if (internal_start == 1)
                counting <= 1;
        end
        else begin
            if (autostart_expired == 0)
            begin
                autostart_expired <= 1;
                counting <= 1;
            end
        end
    end
    else begin
        if (internal_stop == 1)
            counting <= 0;
        if ((autoreload == 0) && (count >= counter_overflow-1))
            counting <= 0;
    end
end

/*
 * The actual counting:
 */
always @(posedge clock or posedge reset)
begin
    if (reset == 1)
    begin
        /*
         * A rising edge or high level on the reset signal resets the counter value.
         * If counting was previously enabled, it will resume as soon as the reset signal returns to low.
         */
        count <= 0;
        overflow <= 0;
    end
    else begin
        // While enabled (started and not stopped), the counter counts.
        if (counting)
        begin
            count <= count + 1;
            overflow <= 0;
        end

        // With count reaching the value of counter_overflow, the overflow signal goes high.
        if (count >= counter_overflow-1)
        begin
            overflow <= 1;

            if (autoreload != 0)
                count <= 0;
        end

        // The restart behaviour is governed by a module parameter:
        if (start_resets_counting == 0)
        begin
            // It is possible to restart the counter, after it has overflown (or using the reset signal).
            if (overflow & internal_start)
            begin
                count <= 0;
                overflow <= 0;
            end
        end
        else begin
            // A rising edge on the start signal restarts counting.
            if (internal_start)
            begin
                count <= 0;
                overflow <= 0;
            end
        end
    end
end

endmodule

`endif
