/**
 * This module concatenates a preconfigured number of
 * sliding average modules in an attempt to achieve a more noise-free signal.
 */

module average_sliding_iterative
    #(
        parameter bitwidth_sample = 12,
        parameter initial_accumulator_value = 0,
        parameter iteration_count = 3
        )
    (
         // With every trigger cycle a new averaged value is calculated
         input trigger,

        // With the rising edge, the accumulator is set to it's initial value
        input reset,

        input  [bitwidth_sample-1:0] sample_value,
        output [bitwidth_sample-1:0] averaged_value
        );

// Define all the wires connecting the sliding average modules.
wire[bitwidth_sample-1:0] intermediate_value[0:iteration_count+1];

// The input bus of the first sliding average module is this module's input.
assign intermediate_value[0][bitwidth_sample-1:0] = sample_value[bitwidth_sample-1:0];

// The last bus is the output value.
assign averaged_value = intermediate_value[iteration_count][bitwidth_sample-1:0];

genvar i;
generate
    for (i=0; i<iteration_count; i=i+1)
    begin
        average_sliding #(
                .bitwidth_sample(bitwidth_sample),
                .initial_accumulator_value(initial_accumulator_value)
            ) average (
                .reset          (reset),
                .trigger        (trigger),
                .sample_value   (intermediate_value[i]   [bitwidth_sample-1:0]),
                .averaged_value (intermediate_value[i+1] [bitwidth_sample-1:0])
                );
    end
endgenerate


endmodule
