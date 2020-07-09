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
         * Enabling this parameter disables instantiation of an internal counter
         * in favor of an external counter input.
         * PWM and external counter must have the same bitwidth.
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
         * The configuration values below are only adopted, when this signal is high.
         * Do not leave this input unconnected!
         */
        input load_enable,

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
    if (load_enable == 1)
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
reg configuration_loadable = 0;

always @(posedge clock)
begin
    configuration_loadable <= 1;
    if (
        (tick_count_period                 != previous_tick_count_period)
     || (tick_number_rising_edge_highside  != previous_tick_number_rising_edge_highside)
     || (tick_number_falling_edge_highside != previous_tick_number_falling_edge_highside)
     || (tick_number_rising_edge_lowside   != previous_tick_number_rising_edge_lowside)
     || (tick_number_falling_edge_lowside  != previous_tick_number_falling_edge_lowside)
     )
    begin
        configuration_loadable <= 0;
    end
end


/*
 * Update shadow configuration when ready
 */
always @(posedge update_event)
begin
    if (configuration_loadable == 1)
    begin
        shadow_tick_count_period                 = tick_count_period;
        shadow_tick_number_rising_edge_highside  = tick_number_rising_edge_highside;
        shadow_tick_number_falling_edge_highside = tick_number_falling_edge_highside;
        shadow_tick_number_rising_edge_lowside   = tick_number_rising_edge_lowside;
        shadow_tick_number_falling_edge_lowside  = tick_number_falling_edge_lowside;
    end
end


/*
 * Internal counter
 */
if (use_external_counter == 0)
begin
    counter #(
            .autostart          (1),
            .autoreload         (1),
            .bitwidth           (bitwidth)
        )
        pwm_counter (
            .clock      (clock),
            .reset      (reset),
            .period     (shadow_tick_count_period[bitwidth-1:0]),
            .count      (counter_value[bitwidth-1:0]),
            .start      (1'b0),
            .stop       (1'b0),
            .overflow   (counter_overflow)
            );
end
else begin
    assign counter_value[bitwidth-1:0] = external_counter_value[bitwidth-1:0];
    assign counter_overflow = external_counter_overflow;
end


/*
 * The actually used pulse configuration values
 */
reg[bitwidth-1:0] shadow_tick_count_period                 = 0;
reg[bitwidth-1:0] shadow_tick_number_rising_edge_highside  = 0;
reg[bitwidth-1:0] shadow_tick_number_falling_edge_highside = 0;
reg[bitwidth-1:0] shadow_tick_number_rising_edge_lowside   = 0;
reg[bitwidth-1:0] shadow_tick_number_falling_edge_lowside  = 0;

pulse #(
        .bitwidth                   (bitwidth)
    )
    gate_highside (
        .clock                      (clock),
        .reset                      (reset),
        .counter                    (tick_counter[bitwidth-1:0]),
        .tick_number_rising_edge    (shadow_tick_number_rising_edge_highside[bitwidth-1:0]),
        .tick_number_falling_edge   (shadow_tick_number_falling_edge_highside[bitwidth-1:0]),
        .generated_signal           (highside_output)
        );

pulse #(
        .bitwidth                   (bitwidth)
    )
    gate_lowside (
        .clock                      (clock),
        .reset                      (reset),
        .counter                    (tick_counter[bitwidth-1:0]),
        .tick_number_rising_edge    (shadow_tick_number_rising_edge_lowside[bitwidth-1:0]),
        .tick_number_falling_edge   (shadow_tick_number_falling_edge_lowside[bitwidth-1:0]),
        .generated_signal           (lowside_output)
        );


endmodule

`endif
