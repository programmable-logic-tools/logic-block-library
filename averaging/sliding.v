/**
 * This module implements a sliding average logic.
 * With every trigger cycle the average of the previous output value
 * and the sampled value is calculated:
 *   new_output <= (previous_output + sample_value)/2
 */

module average_sliding
    #(
        parameter bitwidth_sample = 12,
        parameter initial_accumulator_value = 0
        )
     (
         // With every trigger cycle a new averaged value is calculated
         input trigger,

         // With the rising edge, the accumulator is set to it's initial value
         input reset,

         input[bitwidth_sample-1:0]  sample_value,
         output[bitwidth_sample-1:0] averaged_value
         );

reg[bitwidth_sample:0] accumulator = initial_accumulator_value;
assign averaged_value[bitwidth_sample-1:0] = accumulator[bitwidth_sample-1:0];

// Add
wire[bitwidth_sample:0] sum;
assign sum = accumulator[bitwidth_sample:0] + sample_value;

always @(posedge trigger or posedge reset)
begin
    if (reset == 1)
    begin
        // Reset accumulator
        accumulator[bitwidth_sample:0] <= initial_accumulator_value;
    end
    else begin
        // Divide by two
        accumulator[bitwidth_sample-1:0] <= sum[bitwidth_sample:1];
    end
end

endmodule
