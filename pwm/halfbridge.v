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
        parameter bitwidth = $clog2(tick_count_period)+1,

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
         * When the turn-on duration of a switch exceeds it's maximum,
         * such that it is no longer possible to turn on the corresponding complementary switch,
         * this parameter configures, whether the PWM should switch to flat-top mode
         * or try to switch the respective semiconductor intermittently.
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
localparam STATE_REGULAR_PWM = 0;
localparam STATE_INTERMITTENT_HIGHSIDE = 1;
localparam STATE_INTERMITTENT_LOWSIDE = 2;
localparam STATE_FLAT_TOP_HIGHSIDE = 3;
localparam STATE_FLAT_TOP_LOWSIDE = 4;
localparam state_count = 5;

reg[$clog2(state_count):0] state = STATE_REGULAR_PWM;
reg[$clog2(state_count):0] previous_state = STATE_REGULAR_PWM;


/*
 * Calculate dutycycle values
 */
reg[bitwidth:0] tick_number_rising_edge_highside  = 0;
reg[bitwidth:0] tick_number_falling_edge_highside = 0;
reg[bitwidth:0] tick_number_rising_edge_lowside   = 0;
reg[bitwidth:0] tick_number_falling_edge_lowside  = 0;

reg[bitwidth:0] t1 = 0;
reg[bitwidth:0] t2 = 0;
reg[bitwidth:0] t3 = 0;
reg[bitwidth:0] t4 = 0;

initial calculation_error <= 0;

/**
 * The maximum number of ticks a gate signal can be high,
 * before it doesn't make sense anymore
 * to turn on the respective complementary switch
 * (flat top mode or intermittent switching).
 */
localparam threshold_complementary_switch_turnon = tick_count_period - deadtime_hs_to_ls - deadtime_ls_to_hs - minimum_driver_on_time;
wire switch_highside_intermittently, switch_lowside_intermittently;
if (enable_intermittent_switching == 0)
begin
    /*
     * Switch to flat-top as soon as the complementary switch cannot be turned on anymore
     */
    localparam flat_top_threshold = threshold_complementary_switch_turnon;
    assign switch_highside_intermittently = 0;
    assign switch_lowside_intermittently = 0;
end
else begin
    localparam flat_top_threshold = tick_count_period - 1;
    assign switch_highside_intermittently =
               (tick_count_highside >= threshold_complementary_switch_turnon)
            && (tick_count_highside < flat_top_threshold);
    assign switch_lowside_intermittently =
               (tick_count_lowside >= threshold_complementary_switch_turnon)
            && (tick_count_lowside < flat_top_threshold);
end

wire highside_is_minimal = (tick_count_highside < minimum_driver_on_time);
wire lowside_is_minimal  = (tick_count_lowside  < minimum_driver_on_time);

wire flat_top_highside =
            (tick_count_highside >= flat_top_threshold)
        || ((highside_is_minimal == 0) && (lowside_is_minimal == 1))
        ;

wire flat_top_lowside =
            (tick_count_lowside >= flat_top_threshold)
        || ((highside_is_minimal == 1) && (lowside_is_minimal == 0))
         ;

wire both_on_times_minimal =
        (
            (highside_is_minimal == 1)
         && (lowside_is_minimal  == 1)
         );

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
        t1 <= 0;
        t2 <= 0;
        t3 <= 0;
        t4 <= 0;
    end
    else if ((enable_intermittent_switching == 1) && (switch_highside_intermittently == 1))
    begin
        t1 <= 0;
        t2 <= tick_count_highside;
        t3 <= 0;
        t4 <= 0;
    end
    else if ((enable_intermittent_switching == 1) && (switch_lowside_intermittently == 1))
    begin
        t1 <= 0;
        t2 <= 0;
        t3 <= 0;
        t4 <= tick_count_lowside;
    end
    else if (flat_top_highside == 1)
    begin
        t1 <= 0;
        t2 <= tick_count_period;
        t3 <= 0;
        t4 <= 0;
    end
    else if (flat_top_lowside == 1)
    begin
        t1 <= 0;
        t2 <= 0;
        t3 <= 0;
        t4 <= tick_count_period;
    end
    else if (previous_state == STATE_FLAT_TOP_LOWSIDE)
    begin
        /*
         * Regular PWM, but a deadtime must be added between lowside turn-off to highside turn-on
         */
        t1 <= deadtime_ls_to_hs;
        t2 <= t1 + tick_count_highside;
        t3 <= t2 + deadtime_hs_to_ls;
        t4 <= t3 + tick_count_lowside - deadtime_ls_to_hs;
    end
    else begin
        // Regular PWM with deadtimes
        t1 <= 0;
        t2 <= tick_count_highside;
        t3 <= t2 + deadtime_hs_to_ls;
        t4 <= t3 + tick_count_lowside;
        // t4 <= t3 + deadtime_ls_to_hs;
    end
end


/**
 * After new duration values are received,
 * it takes a while for the on- and off-time calculations to complete.
 */
counter #(
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
        .reload_value   (tick_count_calculation_delay),
        .overflow       (calculation_complete)
        );


/**
 * Update the internal PWM registers after the on- and off-time calculations are complete
 */
reg disable_highside = 0;
reg disable_lowside = 0;
always @(posedge clock)
begin
    if (
         (calculation_complete == 1)
     && ((tick_counter == 0) || (tick_counter == tick_count_period-1))
     )
    begin
        // Update highside registers
        tick_number_rising_edge_highside  <= t1;
        tick_number_falling_edge_highside <= t2;

        // Update lowside registers
        tick_number_rising_edge_lowside   <= t3;
        tick_number_falling_edge_lowside  <= t4;

        previous_state <= state;

        if (switch_highside_intermittently == 1)
        begin
            state <= STATE_INTERMITTENT_HIGHSIDE;
            disable_highside <= 0;
            disable_lowside <= 1;
        end
        else if (switch_lowside_intermittently == 1)
        begin
            state <= STATE_INTERMITTENT_LOWSIDE;
            disable_highside <= 1;
            disable_lowside <= 0;
        end
        else if (flat_top_highside == 1)
        begin
            state <= STATE_FLAT_TOP_HIGHSIDE;
            disable_highside <= 0;
            disable_lowside <= 1;
        end
        else if (flat_top_lowside == 1)
        begin
            state <= STATE_FLAT_TOP_LOWSIDE;
            disable_highside <= 1;
            disable_lowside <= 0;
        end
        else begin
            state <= STATE_REGULAR_PWM;
            disable_highside <= 0;
            disable_lowside <= 0;
        end
    end

    /*
     * Check, if the sum of all times - without the deadtimes because of the DCM mode -
     * exceeds the period duration.
     */
    if (tick_count_highside + tick_count_lowside > tick_count_period)
    begin
        calculation_error <= 1;
    end

    if (calculation_error == 1)
    begin
        // Disable highside
        tick_number_rising_edge_highside  <= 0;
        tick_number_falling_edge_highside <= 0;

        // Disable lowside
        tick_number_rising_edge_lowside   <= 0;
        tick_number_falling_edge_lowside  <= 0;
    end
end


pulse #(
        .bitwidth                   (bitwidth)
    )
    pulse_gate_highside (
        .clock                      (clock),
        .reset                      (disable_pwm_immediately | disable_highside),
        .counter                    (tick_counter[bitwidth-1:0]),
        .tick_number_rising_edge    (tick_number_rising_edge_highside[bitwidth-1:0]),
        .tick_number_falling_edge   (tick_number_falling_edge_highside[bitwidth-1:0]),
        .generated_signal           (highside_output)
        );

/**
 * Under no circumstances can highside and lowside be high at the same time.
 * This wire is a last line of protection.
 */
wire lowside_output_unprotected;

pulse #(
        .bitwidth                   (bitwidth)
    )
    pulse_gate_lowside (
        .clock                      (clock),
        .reset                      (disable_pwm_immediately | disable_lowside),
        .counter                    (tick_counter[bitwidth-1:0]),
        .tick_number_rising_edge    (tick_number_rising_edge_lowside[bitwidth-1:0]),
        .tick_number_falling_edge   (tick_number_falling_edge_lowside[bitwidth-1:0]),
        .generated_signal           (lowside_output_unprotected)
        );

assign lowside_output = lowside_output_unprotected & (~highside_output);

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
