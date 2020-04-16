/**
 * This module generates the pulse-width modulation (PWM) signals
 * for one half bridge i.e. one highside and one lowside gate signal.
 */

`ifndef PWM_V
`define PWM_V

`include "counter.v"
`include "timer.v"

module pwm
    #(
        parameter deadtime_hs_to_ls = 12,
        parameter deadtime_ls_to_hs = 12,
        parameter tick_count_period = 100,
        parameter bitwidth = $clog2(tick_count_period)+1
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

        /*
         * While load_enable is low, new tick count values are not adpoted.
         */
        input load_enable,

        /*
         * List of generated gate signals
         *
         * The both_gates_off signal is required for DCM mode.
         */
        output highside_output,
        output lowside_output,
        output both_gates_off_output
        );


/*
 * Calculate dutycycle values
 */
reg[bitwidth-1:0] tick_number_rising_edge_highside  = 2;
reg[bitwidth-1:0] tick_number_falling_edge_highside = tick_count_period/2;
reg[bitwidth-1:0] tick_number_rising_edge_lowside   = tick_count_period/2 + 2;
reg[bitwidth-1:0] tick_number_falling_edge_lowside  = tick_count_period-1;

wire[bitwidth-1:0] t1 = deadtime_ls_to_hs;
wire[bitwidth-1:0] t2 = t1 + tick_count_highside;
wire[bitwidth-1:0] t3 = t2 + deadtime_hs_to_ls;
wire[bitwidth-1:0] t4 = t3 + tick_count_lowside;

always @(posedge clock)
begin
    if (load_enable == 1)
    begin
        if ((tick_counter == 0) || (tick_counter == tick_count_period-1))
        begin
            // Update highside registers
            tick_number_rising_edge_highside  <= t1;
            tick_number_falling_edge_highside <= t2;

            // Update lowside registers
            tick_number_rising_edge_lowside   <= t3;
            tick_number_falling_edge_lowside  <= t4;
        end
        // else if (tick_counter == tick_period-1)
        // begin
        // end
    end
end


timer #(
        .bitwidth                   (bitwidth)
    )
    timer_gate_highside (
        .clock                      (clock),
        .reset                      (reset),
        .counter                    (tick_counter[bitwidth-1:0]),
        .tick_number_rising_edge    (tick_number_rising_edge_highside[bitwidth-1:0]),
        .tick_number_falling_edge   (tick_number_falling_edge_highside[bitwidth-1:0]),
        .generated_signal           (highside_output)
        );

timer #(
        .bitwidth                   (bitwidth)
    )
    timer_gate_lowside (
        .clock                      (clock),
        .reset                      (reset),
        .counter                    (tick_counter[bitwidth-1:0]),
        .tick_number_rising_edge    (tick_number_rising_edge_lowside[bitwidth-1:0]),
        .tick_number_falling_edge   (tick_number_falling_edge_lowside[bitwidth-1:0]),
        .generated_signal           (lowside_output)
        );


endmodule

`endif
