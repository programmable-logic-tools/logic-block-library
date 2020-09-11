/**
 * This module generates a pulse with rising and falling
 * edges at the configured counter vales.
 */

`ifndef PWM_PULSE_V
`define PWM_PULSE_V

`include "../buffer.v"

module pulse
    #(
        parameter bitwidth = 10,
        parameter enable_double_buffering = 0
        )
    (
        input clock,
        input reset,
        input load_enable,
        input [bitwidth-1:0] counter,
        input [bitwidth-1:0] tick_number_rising_edge,
        input [bitwidth-1:0] tick_number_falling_edge,

        output reg generated_signal
        );


wire[bitwidth-1:0] internal_tick_number_rising_edge;
wire[bitwidth-1:0] internal_tick_number_falling_edge;

if (enable_double_buffering == 0)
begin
    assign internal_tick_number_rising_edge[bitwidth-1:0] = tick_number_rising_edge[bitwidth-1:0];
    assign internal_tick_number_falling_edge[bitwidth-1:0] = tick_number_falling_edge[bitwidth-1:0];
end
else begin
    buffer #(
            .bitwidth       (bitwidth)
        )
        buffer_rising_edge(
            .clock          (clock),
            .load_enable    (load_enable),
            .value_in       (tick_number_rising_edge[bitwidth-1:0]),
            .value_out      (internal_tick_number_rising_edge[bitwidth-1:0])
            );

    buffer #(
            .bitwidth       (bitwidth)
        )
        buffer_falling_edge(
            .clock          (clock),
            .load_enable    (load_enable),
            .value_in       (tick_number_falling_edge[bitwidth-1:0]),
            .value_out      (internal_tick_number_falling_edge[bitwidth-1:0])
            );
end


initial generated_signal <= 0;

always @(posedge clock)
begin
    if (reset == 1)
    begin
        generated_signal <= 0;
    end
    else begin
        if ((counter < internal_tick_number_rising_edge) || (counter >= internal_tick_number_falling_edge))
            generated_signal <= 0;
        else //if (counter >= internal_tick_number_rising_edge)
            generated_signal <= 1;
    end
end

endmodule

`endif
