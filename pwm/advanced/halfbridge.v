/**
 * This module implements a half-bridge gate signal generator.
 */

`ifndef PWM_V
`define PWM_V

`include "../pulse.v"

module pwm_advanced_halfbridge
    #(
        parameter bitwidth = 8
        )
    (
        input clock,

        /**
         * While this input is high,
         * the outputs remain low.
         */
        input reset,

        /**
         * Output the counter value in case another PWM shall use it as input.
         */
        input[bitwidth-1:0] counter_value,

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


pulse #(
        .bitwidth                   (bitwidth),
        .enable_double_buffering    (1)
    )
    gate_highside (
        .clock                      (clock),
        .reset                      (reset),

        .load_enable                (load_enable),
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
        .reset                      (reset),

        .load_enable                (load_enable),
        .tick_number_rising_edge    (tick_number_rising_edge_lowside[bitwidth-1:0]),
        .tick_number_falling_edge   (tick_number_falling_edge_lowside[bitwidth-1:0]),

        .counter_value              (counter_value[bitwidth-1:0]),
        .generated_signal           (lowside_output)
        );


endmodule

`endif
