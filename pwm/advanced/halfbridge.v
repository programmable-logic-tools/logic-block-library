/**
 * This module implements a half-bridge gate signal generator.
 */

`ifndef PWM_V
`define PWM_V

`include "../pulse.v"
`include "../../control/follower.v"

module pwm_advanced_halfbridge
    #(
        parameter bitwidth = 8,

        /**
         * Selects whether to directly use setpoints or
         * to implement a value follower
         */
        parameter enable_ramping = 0
        )
    (
        input clock,

        /*
         * While these inputs are high,
         * the corresponding outputs remain low.
         *
         * CAVEAT:
         * They should explicitly be tied to low
         * if the outputs should be enabled permanently.
         */
        input disable_highside_output,
        input disable_lowside_output,

        /**
         * Output the counter value in case another PWM shall use it as input.
         */
        input[bitwidth-1:0] counter_value,

        /**
         * Provide a rising edge upon counter overflow here
         */
        input counter_overflow,

        /**
         * The configuration values below are only adopted, when this signal is high.
         * Leaving this input unconnected may render the PWM inactive.
         */
        input load_enable,

        input[bitwidth-1:0] tick_number_rising_edge_highside,
        input[bitwidth-1:0] tick_number_falling_edge_highside,
        input[bitwidth-1:0] tick_number_rising_edge_lowside,
        input[bitwidth-1:0] tick_number_falling_edge_lowside,

        /**
         * List of generated gate signals
         */
        output highside_output,
        output lowside_output
        );

wire [bitwidth-1:0]
    internal_tick_number_rising_edge_highside,
    internal_tick_number_falling_edge_highside,
    internal_tick_number_rising_edge_lowside,
    internal_tick_number_falling_edge_lowside;

wire internal_load_trigger;

if (enable_ramping == 0)
begin
        assign internal_tick_number_rising_edge_highside = tick_number_rising_edge_highside;
        assign internal_tick_number_falling_edge_highside = tick_number_falling_edge_highside;
        assign internal_tick_number_rising_edge_lowside = tick_number_rising_edge_lowside;
        assign internal_tick_number_falling_edge_lowside = tick_number_falling_edge_lowside;
        assign internal_load_trigger = load_enable;
end
else begin
    assign internal_load_trigger = load_enable & counter_overflow;

    follower #(
            .bitwidth       (bitwidth),
            .initial_value  (0)
        ) follower_rising_edge_highside (
            .clock          (internal_load_trigger),
            .target_value   (tick_number_rising_edge_highside),
            .output_value   (internal_tick_number_rising_edge_highside)
            );
    follower #(
            .bitwidth       (bitwidth),
            .initial_value  (0)
        ) follower_falling_edge_highside (
            .clock          (internal_load_trigger),
            .target_value   (tick_number_falling_edge_highside),
            .output_value   (internal_tick_number_falling_edge_highside)
            );
    follower #(
            .bitwidth       (bitwidth),
            .initial_value  (0)
        ) follower_rising_edge_lowside (
            .clock          (internal_load_trigger),
            .target_value   (tick_number_rising_edge_lowside),
            .output_value   (internal_tick_number_rising_edge_lowside)
            );
    follower #(
            .bitwidth       (bitwidth),
            .initial_value  (0)
        ) follower_falling_edge_lowside (
            .clock          (internal_load_trigger),
            .target_value   (tick_number_falling_edge_lowside),
            .output_value   (internal_tick_number_falling_edge_lowside)
            );
end


pulse #(
        .bitwidth                   (bitwidth),
        .enable_double_buffering    (1)
    )
    gate_highside (
        .clock                      (clock),
        .reset                      (disable_highside_output),

        .load_enable                (internal_load_trigger),
        .tick_number_rising_edge    (tick_number_rising_edge_highside[bitwidth-1:0]),
        .tick_number_falling_edge   (tick_number_falling_edge_highside[bitwidth-1:0]),

        .counter_value              (counter_value[bitwidth-1:0]),
        .generated_signal           (highside_output)
        );

pulse #(
        .bitwidth                   (bitwidth),
        .enable_double_buffering    (1)
    )
    gate_lowside (
        .clock                      (clock),
        .reset                      (disable_lowside_output),

        .load_enable                (internal_load_trigger),
        .tick_number_rising_edge    (tick_number_rising_edge_lowside[bitwidth-1:0]),
        .tick_number_falling_edge   (tick_number_falling_edge_lowside[bitwidth-1:0]),

        .counter_value              (counter_value[bitwidth-1:0]),
        .generated_signal           (lowside_output)
        );


endmodule

`endif
