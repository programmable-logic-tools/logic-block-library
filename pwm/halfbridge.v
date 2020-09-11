/**
 * This module generates the pulse-width modulation (PWM) signals
 * for one half bridge i.e. one highside and one lowside gate signal.
 */

`ifndef PWM_HALFBRIDGE_V
`define PWM_HALFBRIDGE_V

`include "../counter/counter.v"
`include "pulse.v"
`include "../delay.v"

module pwm
    #(
        parameter deadtime_hs_to_ls = 12,
        parameter deadtime_ls_to_hs = 12,
        parameter tick_count_period = 100,
        parameter bitwidth = $clog2(tick_count_period+1)+1,

        /**
         * The minimal number of clock ticks a digital gate signal must remain high
         * in order to elicit a FET turn-on on the isolated side of the gate driver.
         */
        parameter minimum_driver_on_time = 8,

        /**
         * The number of clock ticks it takes for the on- and off-time
         * caluclations to complete after an update.
         */
        parameter tick_count_calculation_delay = 6,

        /**
         * With this parameter enabled, both outputs will stop switching
         * when one is set to an extreme value (0 respectively counter overflow-1).
         */
        parameter enable_flat_top = 1,

        /**
         * When the turn-on duration of a switch exceeds it's maximum,
         * such that it is no longer possible to turn on the corresponding complementary switch,
         * this parameter configures, whether the PWM should switch to flat-top mode
         * or try to switch the respective semiconductor intermittently.
         *
         * TODO:
         * When intermittent switching is enabled and one output is in flat-bottom state,
         * the complementary output still switches (with a very high duty cycle).
         */
        parameter enable_intermittent_switching = 0
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
         * After a rising edge on invalidate_input_values,
         * the tick_count input values are ignored
         * until the next rising edge on load_input_values.
         */
        input invalidate_input_values,
        input load_input_values,
        output calculation_complete,
        output reg calculation_error,
        output reg shortcircuit_error,

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
 * State machine to control the transitions from and to flat top
 *
 * We need to remember, whether the last state was flat top on the lowside switch,
 * because in that case a deadtime must be inserted before turning on the highside switch.
 */
localparam STATE_OFF = 0;
localparam STATE_REGULAR_PWM = 1;
localparam STATE_INTERMITTENT_HIGHSIDE = 2;
localparam STATE_INTERMITTENT_LOWSIDE = 3;
localparam STATE_FLAT_TOP_HIGHSIDE = 4;
localparam STATE_FLAT_TOP_LOWSIDE = 5;
localparam state_count = 6;

reg[$clog2(state_count):0] state = STATE_OFF;
reg[$clog2(state_count):0] previous_state = STATE_OFF;
reg[$clog2(state_count):0] suggested_state = STATE_OFF;


/*
 * Calculate dutycycle values
 */
reg[bitwidth-1:0] tick_number_rising_edge_highside  = 0;
reg[bitwidth-1:0] tick_number_falling_edge_highside = 0;
reg[bitwidth-1:0] tick_number_rising_edge_lowside   = 0;
reg[bitwidth-1:0] tick_number_falling_edge_lowside  = 0;

reg[bitwidth-1:0] t1 = 0;
reg[bitwidth-1:0] t2 = 0;
reg[bitwidth-1:0] t3 = 0;
reg[bitwidth-1:0] t4 = 0;

initial calculation_error <= 0;


localparam threshold1 = 1;
localparam threshold2 = minimum_driver_on_time;
localparam threshold3 = tick_count_period - deadtime_hs_to_ls - deadtime_ls_to_hs - minimum_driver_on_time - 1;
localparam threshold4 = tick_count_period - deadtime_hs_to_ls - deadtime_ls_to_hs - 2;

wire highside_is_minimal = (tick_count_highside < minimum_driver_on_time);
wire lowside_is_minimal  = (tick_count_lowside  < minimum_driver_on_time);
wire both_on_times_minimal =
        (
            (highside_is_minimal != 0)
         && (lowside_is_minimal  != 0)
         );

wire flat_bottom_highside, flat_bottom_lowside;
wire flat_top_highside, flat_top_lowside;
if (enable_flat_top == 0)
begin
    assign flat_bottom_highside = 0;
    assign flat_top_highside = 0;
    assign flat_bottom_lowside = 0;
    assign flat_top_lowside = 0;
end
else begin
    assign flat_bottom_highside = highside_is_minimal;
    assign flat_bottom_lowside = lowside_is_minimal;
    assign flat_top_highside = flat_bottom_lowside;
    assign flat_top_lowside = flat_bottom_highside;
end

wire switch_highside_intermittently, switch_lowside_intermittently;
if (enable_intermittent_switching == 0)
begin
    assign switch_highside_intermittently = 0;
    assign switch_lowside_intermittently = 0;
end
else begin
    assign switch_highside_intermittently = lowside_is_minimal && (tick_count_highside < threshold4);
    assign switch_lowside_intermittently = highside_is_minimal && (tick_count_lowside < threshold4);
end

wire disable_pwm_immediately =
           (reset == 1)
        || (calculation_error == 1)
        || (shortcircuit_error == 1)
        ;


/**
 * Calculate the on- and off-times
 */
always @(posedge clock)
begin
    if (both_on_times_minimal)
    begin
        suggested_state <= STATE_OFF;
        t1 <= 0;
        t2 <= 0;
        t3 <= 0;
        t4 <= 0;
    end
    else if (tick_count_highside < minimum_driver_on_time)
    begin
        /*
         * The high-side switch stays off.
         */
        t1 <= 0;
        t2 <= 0;

        if (tick_count_lowside >= tick_count_period-1)
        begin
            /*
             * The low-side switch stays on (flat top mode).
             */
            suggested_state <= STATE_FLAT_TOP_LOWSIDE;
            t3 <= 0;
            t4 <= tick_count_period;
        end
        else begin
            /*
             * The low-side switch switches intermittently.
             */
             suggested_state <= STATE_INTERMITTENT_LOWSIDE;
             t3 <= 0;
             t4 <= tick_count_lowside;
        end
    end
    else if (tick_count_lowside < minimum_driver_on_time)
    begin
        /*
         * The low-side switch stays off.
         */
        t3 <= 0;
        t4 <= 0;

        if (tick_count_highside >= tick_count_period-1)
        begin
            /*
             * The high-side switch stays on (flat top mode).
             */
            suggested_state <= STATE_FLAT_TOP_HIGHSIDE;
            t1 <= 0;
            t2 <= tick_count_period;
        end
        else begin
            /*
             * The high-side switch switches intermittently.
             */
             suggested_state <= STATE_INTERMITTENT_HIGHSIDE;
             t1 <= 0;
             t2 <= tick_count_highside;
        end
    end
    else if (
        // (previous_state == STATE_INTERMITTENT_HIGHSIDE) ||
        (previous_state == STATE_FLAT_TOP_LOWSIDE)
        )
    begin
        /*
         * Regular PWM, but a deadtime must be added between lowside turn-off to highside turn-on
         */
        suggested_state <= STATE_REGULAR_PWM;
        t1 = deadtime_ls_to_hs;
        t2 = t1 + tick_count_highside;
        t3 = t2 + deadtime_hs_to_ls;
        t4 = t3 + tick_count_lowside - deadtime_ls_to_hs;
    end
    else begin
        // Regular PWM with deadtimes
        suggested_state <= STATE_REGULAR_PWM;
        t1 = 0;
        t2 = tick_count_highside;
        t3 = t2 + deadtime_hs_to_ls;
        t4 = t3 + tick_count_lowside;
        // t4 <= t3 + deadtime_ls_to_hs;
    end
end


/**
 * After new duration values are received,
 * it takes a while for the on- and off-time calculations to complete.
 */
counter #(
        .bitwidth               ($clog2(tick_count_calculation_delay+1)+1),
        .enable_autostart_input (0),
        .enable_autoreload_input(0),
        .enable_reset_pulsifier (1),
        .reset_pulse_duration   (1),
        .enable_start_pulsifier (1),
        .start_pulse_duration   (1),
        .enable_stop_pulsifier  (0)
    )
    calculation_delay (
        .clock          (clock),
        .reset          (invalidate_input_values),
        .start          (load_input_values),
        .stop           (1'b0),
        .overflow_value (tick_count_calculation_delay),
        .overflow       (calculation_complete)
        );


/**
 * Update the internal PWM registers after the on- and off-time calculations are complete
 */
always @(posedge clock)
begin
    if (calculation_complete == 1)
    begin
        // Update highside registers
        tick_number_rising_edge_highside  <= t1;
        tick_number_falling_edge_highside <= t2;

        // Update lowside registers
        tick_number_rising_edge_lowside   <= t3;
        tick_number_falling_edge_lowside  <= t4;

        previous_state <= state;
        state <= suggested_state;
    end
end


pulse #(
        .bitwidth                   (bitwidth)
    )
    pulse_gate_highside (
        .clock                      (clock),
        .reset                      (disable_pwm_immediately),
        .counter                    (tick_counter[bitwidth-1:0]),
        .tick_number_rising_edge    (tick_number_rising_edge_highside[bitwidth-1:0]),
        .tick_number_falling_edge   (tick_number_falling_edge_highside[bitwidth-1:0]),
        .generated_signal           (highside_output)
        );

/**
 * Under no circumstances can highside and lowside be high at the same time.
 * This wire is a last line of protection.
 */
// wire lowside_output_unprotected;

pulse #(
        .bitwidth                   (bitwidth)
    )
    pulse_gate_lowside (
        .clock                      (clock),
        .reset                      (disable_pwm_immediately),
        .counter                    (tick_counter[bitwidth-1:0]),
        .tick_number_rising_edge    (tick_number_rising_edge_lowside[bitwidth-1:0]),
        .tick_number_falling_edge   (tick_number_falling_edge_lowside[bitwidth-1:0]),
        // .generated_signal           (lowside_output_unprotected)
        .generated_signal           (lowside_output)
        );

// assign lowside_output = lowside_output_unprotected & (~highside_output);

/*
 * The last line of protection
 */
initial shortcircuit_error <= 0;
// always @(posedge clock)
// begin
//     if (reset == 1)
//     begin
//         shortcircuit_error <= 0;
//     end
//
//     if (
//            (highside_output == 1)
//         && (lowside_output_unprotected == 1)
//         )
//     begin
//         shortcircuit_error <= 1;
//     end
// end


endmodule

`endif
