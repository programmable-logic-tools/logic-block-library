
`ifndef TIMER_V
`define TIMER_V

module timer
    #(
        parameter bitwidth = 10
        )
    (
        input clock,
        input reset,
        input [bitwidth-1:0] counter,
        input [bitwidth-1:0] tick_number_rising_edge,
        input [bitwidth-1:0] tick_number_falling_edge,

        output reg generated_signal
        );

initial generated_signal <= 0;

always @(posedge clock)
begin
    if ((counter == tick_number_rising_edge) && (reset == 0))
        generated_signal <= 1;
    if ((counter == tick_number_falling_edge) || (reset == 1))
        generated_signal <= 0;
end

endmodule

`endif
