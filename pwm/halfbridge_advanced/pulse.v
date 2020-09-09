/**
 * This module generates a pulse which is characterized
 * by the tick numbers of it's rising and falling edges respectively.
 */


`ifndef PULSE_V
`define PULSE_V

module pulse
    #(
        parameter bitwidth = 10
        )
    (
        input clock,
        input reset,

        input [bitwidth-1:0] counter_value,
        input [bitwidth-1:0] tick_number_rising_edge,
        input [bitwidth-1:0] tick_number_falling_edge,

        output reg generated_signal
        );

initial generated_signal <= 0;

always @(posedge clock)
begin
    if ((counter_value == tick_number_rising_edge) && (reset == 0))
        generated_signal <= 1;
    if ((counter_value == tick_number_falling_edge) || (reset == 1))
        generated_signal <= 0;
end

endmodule

`endif
