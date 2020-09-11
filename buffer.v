`ifndef BUFFER_V
`define BUFFER_V

module buffer #(
        parameter bitwidth = 8
    ) (
        input clock,
        input load_enable,
        input [bitwidth-1:0] value_in,
        output reg [bitwidth-1:0] value_out
        );

initial value_out <= 0;

always @(posedge clock)
begin
    if (load_enable == 1)
    begin
        value_out[bitwidth-1:0] <= value_in[bitwidth-1:0];
    end
end

endmodule

`endif
