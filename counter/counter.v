/**
 * This module counts upwards from zero with the given clock and
 * provides an overflow signal, when the given overflow value is reached.
 *
 * Please note:
 * In order to avoid unexpected behaviour when instantiating this module,
 * the inputs start, stop and reset should always be connected
 * or, respectively, be assigned a constant value.
 */

`ifndef COUNTER_V
`define COUNTER_V

`include "../pulsifier.v"

module counter #(
            /**
             * The number of bits reserved for the counter value.
             * The maximum allowed auto-reload value is (2^bitwidth)-2,
             * i.e. bitwidth must be chosen, such that (2^bitwidth)-1 <= (overflow_value+1),
             * because without auto-reload enabled the counter value reaches (overflow_value+1).
             */
            parameter bitwidth = 8,

            /**
             * A non-zero value enables the evaluation of the autostart input.
             */
            parameter enable_autostart_input = 0,

            /**
             * A non-zero value enables the evaluation of the auto-reload input.
             */
            parameter enable_autoreload_input = 0,

            /**
             * When this parameter is zero,
             * all start signals are ignored if the counter is already counting.
             * When this parameter is non-zero,
             * the counter resets when receiving start signals while counting,
             */
            parameter start_resets_counting = 0,

            /**
             * This parameter configures, whether the reset signal is used as is or pulsified internally.
             */
            parameter enable_reset_pulsifier = 0,
            parameter reset_pulse_duration = 1,

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

            /**
             * With a non-zero value on this input
             * the counter begins counting without waiting for a start signal.
             * autostart does NOT imply autoreload though,
             * meaning that the counter stops when the overflow value is reached.
             * With autostart, when the counter is reset (by the reset signal),
             * it will immediately begin counting again.
             * When start_resets_counting is enabled,
             * a start signal still resets the counter.
             * Requires enable_autostart_input.
             */
            input autostart,

            /**
             * With a non-zero value on this input
             * the counter does not stop when it overflows,
             * but instead continues counting from zero.
             * Requires enable_autoreload_input.
             */
            input autoreload,

            /**
             * The counter value after(!) which the
             * counter overflows and resets to zero
             */
            input[bitwidth-1:0] overflow_value,

            /**
             * The internally used reload value is only updated
             * upon an update i.e. counter overflow event.
             */
            output reg[bitwidth-1:0] active_overflow_value,

            /** A high level on the counting signal indicates, that the counter is currently counting. */
            output reg counting,

            /** For use in other modules or for debugging, the internal counter registers are exposed. */
            output reg[bitwidth-1:0] value,

            /** A rising edge on the overflow signal indicates, that the parameterized number of ticks have elapsed. */
            output reg overflow
            );

initial value <= 0;
initial counting <= 0;
initial overflow <= 0;

/*
 * Pulsify the reset signal, if this is configured
 */
wire internal_reset;
if (enable_reset_pulsifier == 0)
begin
    assign internal_reset = reset;
end
else begin
    pulsifier #(
        .pulse_duration     (reset_pulse_duration)
        )
        pulsify_reset (
        .clock              (clock),
        .original_signal    (reset),
        .pulsified_signal   (internal_reset)
        );
end

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
 * Update internally used reload value
 */
initial active_overflow_value <= 0;
wire illegal_overflow_value = (overflow_value == 0);
wire reload_trigger = (counting == 0) || (overflow == 1);
always @(posedge clock)
begin
    if (reload_trigger)
        active_overflow_value[bitwidth-1:0] <= overflow_value[bitwidth-1:0];
end

/*
 * Decide, whether to count or not
 */
wire overflow_latch = (value >= active_overflow_value);
always @(posedge clock)
begin
    if (counting == 0)
    begin
        if (illegal_overflow_value)
            counting <= 0;

        // The counter is inactive
        else if (enable_autostart_input > 0)
        begin
            // The autostart input shall be evaluated
            if (autostart == 0)
            begin
                if (internal_start == 1)
                    counting <= 1;
            end
            else begin
                if ((value == 0) && (internal_reset == 0))
                    counting <= 1;
            end
        end
        else begin
            // The autostart input shall be disregarded
            if (internal_start == 1)
                counting <= 1;
        end
    end
    else begin
        // Always respect the stop input
        if (internal_stop == 1)
            counting <= 0;

        if (enable_autoreload_input > 0)
        begin
            // The autoreload input shall be evaluated
            if ((overflow_latch == 1) && ((autoreload == 0) || (illegal_overflow_value == 1)))
                counting <= 0;
        end
        else begin
            // The autoreload input shall be disregarded
            if (overflow_latch == 1)
                counting <= 0;
        end
    end

    // When the reload value is zero the counter is blocked.
    if (active_overflow_value == 0)
        counting <= 0;
end

/*
 * The actual counting:
 */
always @(posedge clock or posedge internal_reset)
begin
    if (internal_reset == 1)
    begin
        /*
         * A rising edge or high level on the reset signal resets the counter value.
         * If counting was previously enabled, it will resume as soon as the reset signal returns to low.
         */
        value <= 0;
        overflow <= 0;
    end
    else begin
        // While enabled (started and not stopped), the counter counts.
        if (counting)
        begin
            value <= value + 1;
            overflow <= 0;
        end

        // When reaching the value of period, the overflow signal goes high.
        if (overflow_latch)
        begin
            overflow <= 1;

            if (autoreload != 0)
                value <= 0;
        end

        // The restart behaviour is governed by a module parameter:
        if (start_resets_counting == 0)
        begin
            // It is possible to restart the counter, after it has overflown (or using the reset signal).
            if (overflow & internal_start)
            begin
                value <= 0;
                overflow <= 0;
            end
        end
        else begin
            // A rising edge on the start signal restarts counting.
            if (internal_start)
            begin
                value <= 0;
                overflow <= 0;
            end
        end
    end
end

endmodule

`endif
