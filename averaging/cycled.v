
/**
 * This module calculates the average over incoming values.
 * It adds a predefined number of values (which must be a power of 2)
 * to an internal accumulator register and divides it
 * to output an average value.
 */

module average
    #(
        parameter bitwidth_sample = 12,
        parameter bitwidth_accumulator = 16
        )
    (
        input clock,

        /*
         * Value input and output
         */
        input      [bitwidth_sample-1:0] sample_value,
        output reg [bitwidth_sample-1:0] mean_value,

        /*
         * Averaging cycle control
         */
        input clear,
        input add,
        input show
        );


/**
 * Number of lesser significat bits discarded from the accumulator through the division
 */
localparam bitshift_division = bitwidth_accumulator - bitwidth_sample;


/*
 * Add the sampled value to the accumulator register
 */
reg[bitwidth_accumulator-1:0] accumulator = 0;
initial mean_value <= 0;

always @(posedge clear or posedge add)
begin
    if (clear == 1)
    begin
        accumulator <= 0;
    end
    else begin
        // Is this sufficient to synthesize a ripple carry adder?
        accumulator <= accumulator + sample_value;
    end
end


/*
 * Publish the averaged value to the output register
 */
initial mean_value <= 0;

always @(posedge show)
begin
    // Use bitwise right shift to divide by a power of 2
    mean_value[bitwidth_sample-1:0] <= accumulator[bitwidth_accumulator-1:bitwidth_accumulator-bitwidth_sample];
end


endmodule
