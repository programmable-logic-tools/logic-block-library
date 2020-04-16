/**
 * This file implements a configurable clock divider
 */

module clock_divider
    #(
        parameter divisor = 2
        )
    (
        input clock_original,
        output reg clock_divided
        );

initial clock_divided <= 0;

// When to switch the output off again, half clock period
localparam period_half = divisor/2;

reg[$clog2(divisor):0] counter = 0;

always @(posedge clock_original)
begin
    counter <= counter + 1;
    if (counter == divisor-1)
        counter <= 0;

    if (counter == 0)
        clock_divided <= 1;

    if (counter == period_half)
        clock_divided <= 0;
end

endmodule
