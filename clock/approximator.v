/**
 * Generates a not necessarily symmetrical clock
 * from an arbitrary (faster) clock
 */

module clock_approximator
    #(
        parameter actual_frequency = 50e6,
        parameter desired_frequency = 16e6
        )
    (
        input clock_original,
        output reg clock_generated
        );

// Skip every other HF clock period to achieve the LF clock
localparam skip_clocks = desired_frequency / actual_frequency;
reg[$clog2(skip_clocks):0] skip_counter = 0;

// Counts the number of elapsed HF clock periods
reg[$clog2(actual_frequency):0] high_frequency_period_counter = 0;
// Counts the number of elapsed LF clock periods
reg[$clog2(desired_frequency):0] low_frequency_period_counter = 0;

always @(posedge clock_original)
begin
    skip_counter <= skip_counter + 1;
    if (skip_counter == skip_clocks - 1)
        skip_counter <= 0;

    // TODO...
end

endmodule
