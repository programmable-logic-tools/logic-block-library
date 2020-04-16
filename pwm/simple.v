/**
 * This module generates the pulse-width modulation (PWM) signals
 * for one half bridge i.e. one highside and one lowside gate signal.
 */

`ifndef PWM_V
`define PWM_V

`include "../control/pwm.vh"


module pwm
    #(
        parameter bitwidth = `BITWIDTH_PWM_COUNTER
        )
    (
        input reset,
        input clock,

        input[bitwidth-1:0] tick_counter,

        /*
         * Both, highside and lowside tick counts can be specified,
         * because the DCM mode allows for a third part of the period
         * in which both gates are off.
         */
        input[bitwidth-1:0] tick_count_highside,
        input[bitwidth-1:0] tick_count_lowside,
        input load_enable,

        /*
         * List of generated gate signals
         *
         * The both_gates_off signal is required for DCM mode.
         */
        output reg highside_output,
        output reg lowside_output,
        output reg both_gates_off_output
        );


/*
 * To make sure the runtime parameters are loaded at least once
 * upon startup, there is a guaranteed internal reset signal.
 */
reg internal_reset = 1;
always @(posedge clock)
    internal_reset <= reset;


/*
 * Local duty cycle variables
 *
 * Copied here in order to prevent update to a
 * tick value which the counter has already passed.
 */
reg[bitwidth-1:0]
    tick_count_highside_shadow = 0,
    tick_count_lowside_shadow = 0;

initial highside_output <= 0;
initial lowside_output <= 0;
initial both_gates_off_output <= 0;

always @(posedge clock or posedge internal_reset)
begin
    if (internal_reset)
    begin
        highside_output <= 0;
        lowside_output <= 0;
        both_gates_off_output <= 1;

        // Load runtime parameters
        // tick_count_highside_shadow <= tick_count_highside;
        // tick_count_lowside_shadow <= tick_count_highside + tick_count_lowside;
    end
    else begin
        // Begin new cycle for phase U
        if ((tick_counter == 0) && (load_enable == 1))
        begin
            // Load shadow registers
            tick_count_highside_shadow <= tick_count_highside;
            tick_count_lowside_shadow <= tick_count_highside + tick_count_lowside;
        end

        if (tick_counter == 0)
        begin
            // Activate highside gate signal
            highside_output <= 1;
            lowside_output <= 0;
            both_gates_off_output <= 0;
        end

        // Reached end of highside gate on-time
        if (tick_counter >= tick_count_highside_shadow)
        begin
            // Activate lowside gate signal
            highside_output <= 0;
            lowside_output <= 1;
            both_gates_off_output <= 0;
        end

        if (tick_counter >= tick_count_lowside_shadow)
        begin
            // Reset lowside gate signal output
            highside_output <= 0;
            lowside_output <= 0;
            // Enter discontinuous current mode
            both_gates_off_output <= 1;
        end
    end
end

endmodule

`endif
