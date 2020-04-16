/**
 * This module introduces a preconfigured number of
 * delay ticks into a given signal.
 */

`ifndef DELAY_V
`define DELAY_V

module delay
    #(
        parameter tick_count = 1
        )
    (
        input clock,
        input original_signal,
        output delayed_signal
        );

wire intermediate_signal[0:tick_count];

assign intermediate_signal[0] = original_signal;
assign delayed_signal = intermediate_signal[tick_count];

genvar i;
generate
    if (tick_count > 0)
    begin
        reg delay_register[0:tick_count-1];

        for (i=0; i<tick_count; i=i+1)
        begin
            // Infer a DFF with the previous intermediate signal as input...
            initial delay_register[i] <= 0;
            always @(posedge clock)
                #2 delay_register[i] <= intermediate_signal[i];

            // ...and the next intermediate signal as output
            assign intermediate_signal[i+1] = delay_register[i];
        end
    end
endgenerate

endmodule

`endif
