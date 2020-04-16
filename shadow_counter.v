/**
 * This file implements a simple counter
 * with shadowed overflow register
 * (updated only at counter overflow and at reset)
 */

`ifndef SHADOW_COUNTER_V
`define SHADOW_COUNTER_V

module shadow_counter
    #(
        parameter bit_width = 32
        )
    (
        input reset,
        input clock,

        input[bit_width-1:0] overflow_value,

        output reg[bit_width-1:0] counter_value,
        output reg counter_overflow
        );

reg[bit_width-1:0] shadow_overflow_value = 0;

initial
begin
    counter_value <= 0;
    counter_overflow <= 0;
end

always @(posedge clock)
begin
    if (reset)
    begin
        counter_value <= 0;
        counter_overflow <= 0;
        shadow_overflow_value <= overflow_value;
    end
    else begin
        counter_value <= counter_value + 1;
        counter_overflow <= 0;
        if (counter_value == overflow_value-1)
        begin
            counter_overflow <= 1;
            counter_value <= 0;
            shadow_overflow_value <= overflow_value;
        end
    end
end

endmodule

`endif
