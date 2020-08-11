/**
 * This module judges, whether the current
 * half-bridge timing parameters are valid or invalid.
 */

module pwm_validator
    #(
        parameter bitwidth = 8
        )
    (
        input clock,

        /*
         * The timing parameters to check
         */
        input[bitwidth-1:0] tick_count_period,
        input[bitwidth-1:0] tick_number_rising_edge_lowside,
        input[bitwidth-1:0] tick_number_falling_edge_lowside,
        input[bitwidth-1:0] tick_number_rising_edge_highside,
        input[bitwidth-1:0] tick_number_falling_edge_highside,

        /*
         * The validation result:
         *  high = valid
         *  low = invalid
         */
        output reg configuration_valid
        );

initial configuration_valid <= 0;

always @(posedge clock)
begin
    configuration_valid <= (
            (tick_count_period > 0)
         && (tick_number_rising_edge_highside < tick_number_falling_edge_highside)
         && (tick_number_falling_edge_highside <= tick_number_rising_edge_lowside)
         && (tick_number_rising_edge_lowside < tick_number_falling_edge_lowside)
         && (tick_number_falling_edge_lowside <= tick_count_period)
         );
end

endmodule
