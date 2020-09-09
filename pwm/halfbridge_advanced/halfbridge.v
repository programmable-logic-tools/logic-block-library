/**
 * This module generates the pulse-width modulation (PWM) signals
 * for one half bridge i.e. one highside and one lowside gate signal.
 */

`ifndef PWM_V
`define PWM_V

`include "counter.v"
`include "pulse.v"
`include "polarity.v"

module pwm
    #(
        /**
         * Set this parameter to a non-zero value in order to disable
         * instantiation of an internal counter in favor of an external counter input.
         * Caveat: PWM and external counter must have the same bitwidth.
         */
        parameter use_external_counter = 0,

        parameter bitwidth = 8
        )
    (
        input clock,

        /**
         * While this input is high,
         * the internal counter is reset to zero
         * and the outputs remain low.
         */
        input reset,


        /**
         * A value from an external counter,
         * which counts from 0 to (tick_count_period-1).
         */
        input[bitwidth-1:0] external_counter_value,
        input external_counter_overflow,

        /**
         * Output the counter value in case another PWM shall use it as input.
         */
        output[bitwidth-1:0] counter_value,
        output counter_overflow,


        /**
         * The total number of ticks in one PWM period.
         */
        input[bitwidth-1:0] tick_count_period,

        /**
         * Configures, for how many ticks the highside output stays on.
         */
        input[bitwidth-1:0] tick_count_highside,

        /**
         * The number of ticks for which both outputs remain low between the
         * falling edge of the highside and the rising edge of the lowside.
         */
        input[bitwidth-1:0] deadtime_hs_to_ls,

        /**
         * Configures, for how many ticks the lowside output stays on.
         */
        input[bitwidth-1:0] tick_count_lowside,

        /**
         * The number of ticks for which both outputs remain low between the
         * falling edge of the lowside and the rising edge of the highside.
         */
        input[bitwidth-1:0] deadtime_ls_to_hs,

        /**
         * The configuration values below are only adopted, when this signal is high.
         * Leaving this input unconnected may render the PWM inactive.
         */
        input configuration_load_enable,

        /**
         * This signal indicates whether the tick calculations are complete.
         */
        output reg configuration_unchanged,

        /**
         * This signal indicates whether the tick counts are acceptable.
         * When the configuration is not valid, both PWM outputs remain low.
         */
        output reg configuration_valid,


        /**
         * List of generated gate signals
         */
        output highside_output,
        output lowside_output
        );


// Signal alias
wire update_event = counter_overflow;


/*
 * Calculate dutycycle values
 */
reg[bitwidth-1:0] tick_number_rising_edge_highside  = 0;
reg[bitwidth-1:0] tick_number_falling_edge_highside = 0;
reg[bitwidth-1:0] tick_number_rising_edge_lowside   = 0;
reg[bitwidth-1:0] tick_number_falling_edge_lowside  = 0;

wire[bitwidth-1:0] t1 = deadtime_ls_to_hs;
wire[bitwidth-1:0] t2 = t1 + tick_count_highside;
wire[bitwidth-1:0] t3 = t2 + deadtime_hs_to_ls;
wire[bitwidth-1:0] t4 = t3 + tick_count_lowside;

always @(posedge clock)
begin
    if (configuration_load_enable == 1)
    begin
        // Update highside registers
        tick_number_rising_edge_highside  <= t1;
        tick_number_falling_edge_highside <= t2;

        // Update lowside registers
        tick_number_rising_edge_lowside   <= t3;
        tick_number_falling_edge_lowside  <= t4;
    end
end


/*
 * Detect configuration changes
 */
reg[bitwidth-1:0] previous_tick_count_period = 0;
reg[bitwidth-1:0] previous_tick_number_rising_edge_highside  = 0;
reg[bitwidth-1:0] previous_tick_number_falling_edge_highside = 0;
reg[bitwidth-1:0] previous_tick_number_rising_edge_lowside   = 0;
reg[bitwidth-1:0] previous_tick_number_falling_edge_lowside  = 0;

/**
 * Configuration values are considered loadable,
 * when they remain unchanged for at least one clock cycle.
 */
initial configuration_unchanged <= 0;

always @(posedge clock)
begin
    configuration_unchanged <= (
            (tick_count_period                 == previous_tick_count_period)
         && (tick_number_rising_edge_highside  == previous_tick_number_rising_edge_highside)
         && (tick_number_falling_edge_highside == previous_tick_number_falling_edge_highside)
         && (tick_number_rising_edge_lowside   == previous_tick_number_rising_edge_lowside)
         && (tick_number_falling_edge_lowside  == previous_tick_number_falling_edge_lowside)
         );

    previous_tick_count_period                  <= tick_count_period;
    previous_tick_number_rising_edge_highside   <= tick_number_rising_edge_highside;
    previous_tick_number_falling_edge_highside  <= tick_number_falling_edge_highside;
    previous_tick_number_rising_edge_lowside    <= tick_number_rising_edge_lowside;
    previous_tick_number_falling_edge_lowside   <= tick_number_falling_edge_lowside;
end


/*
 * Update shadow configuration when ready
 */
always @(posedge update_event)
begin
    if (
           (configuration_unchanged == 1)
        && (configuration_valid == 1)
        )
    begin
        // internal_tick_count_period                 = tick_count_period - 1;
        internal_tick_count_period                 = tick_count_period;
        internal_tick_number_rising_edge_highside  = tick_number_rising_edge_highside;
        internal_tick_number_falling_edge_highside = tick_number_falling_edge_highside;
        internal_tick_number_rising_edge_lowside   = tick_number_rising_edge_lowside;
        internal_tick_number_falling_edge_lowside  = tick_number_falling_edge_lowside;
    end
end


/*
 * Internal counter
 */
if (use_external_counter == 0)
begin
    counter #(
            .bitwidth                   (bitwidth),
            .enable_start_pulsifier     (0),
            .enable_stop_pulsifier      (0),
            .enable_autostart_input     (1),
            .enable_autoreload_input    (1)
        )
        pwm_counter (
            .clock          (clock),
            .reset          (reset),

            // The counter starts automatically, unless held in reset.
            .start          (1'b0),
            .stop           (1'b0),
            .autostart      (1'b1),
            .autoreload     (1'b1),

            .reload_value   (internal_tick_count_period[bitwidth-1:0]),
            .value          (counter_value[bitwidth-1:0]),
            .overflow       (counter_overflow)
            );
end
else begin
    assign counter_value[bitwidth-1:0] = external_counter_value[bitwidth-1:0];
    assign counter_overflow = external_counter_overflow;
end


/*
 * The internally used configuration values
 */
reg[bitwidth-1:0] internal_tick_count_period                 = 0;
reg[bitwidth-1:0] internal_tick_number_rising_edge_highside  = 0;
reg[bitwidth-1:0] internal_tick_number_falling_edge_highside = 0;
reg[bitwidth-1:0] internal_tick_number_rising_edge_lowside   = 0;
reg[bitwidth-1:0] internal_tick_number_falling_edge_lowside  = 0;

// Invalid configuration disable the PWM outputs.
wire internal_reset = reset | (~configuration_valid);

pulse #(
        .bitwidth                   (bitwidth)
    )
    gate_highside (
        .clock                      (clock),
        .reset                      (internal_reset),
        .counter_value              (counter_value[bitwidth-1:0]),
        .tick_number_rising_edge    (internal_tick_number_rising_edge_highside[bitwidth-1:0]),
        .tick_number_falling_edge   (internal_tick_number_falling_edge_highside[bitwidth-1:0]),
        .generated_signal           (highside_output)
        );

pulse #(
        .bitwidth                   (bitwidth)
    )
    gate_lowside (
        .clock                      (clock),
        .reset                      (internal_reset),
        .counter_value              (counter_value[bitwidth-1:0]),
        .tick_number_rising_edge    (internal_tick_number_rising_edge_lowside[bitwidth-1:0]),
        .tick_number_falling_edge   (internal_tick_number_falling_edge_lowside[bitwidth-1:0]),
        .generated_signal           (lowside_output)
        );


endmodule

`endif
