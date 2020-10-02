/**
 * The output value of this module gradually changes with each clock cycle
 * in the direction of a given target value.
 */

`ifndef EMPE_FOLLOWER
`define EMPE_FOLLOWER

module follower #(
                parameter bitwidth = 8,
                parameter initial_value = 0
            ) (
                input clock,

                input  [bitwidth-1:0] target_value,
                output reg[bitwidth-1:0] output_value
            );

initial output_value <= initial_value;

always @(posedge clock)
begin
    if (output_value < target_value)
        output_value <= output_value + 1;
    else if (output_value > target_value)
        output_value <= output_value - 1;
end

endmodule

`endif
