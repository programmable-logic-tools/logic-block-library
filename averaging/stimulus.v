/**
 * This module generates the stimulus signals for one or more average modules.
 */

`include "../pulsifier.v"


module averaging_stimulus
        #(
            parameter sample_count = 16
            )
        (
            input reset,
            input clock,

            output reg clear,
            output reg add,
            output reg show
            );


initial clear <= 0;
initial add <= 0;
initial show <= 0;


/*
 * In order to be able to use the complete PI control period
 * for sample acquisition, the reset signal must be a pulse.
 */
wire pulsified_reset;
pulsifier reset_pulsifier(
    .clock(clock),
    .signal(reset),
    .pulsified_signal(pulsified_reset)
    );


reg[$clog2(sample_count)+1:0] counter = 0;

always @(posedge pulsified_reset or posedge clock)
begin
    if (pulsified_reset == 1)
    begin
        counter <= 0;
        clear <= 0;
        add <= 0;
        show <= 0;
    end
    else begin
        if (counter == 0)
        begin
            clear <= 1;
        end
        else if (counter == 1)
        begin
            clear <= 0;
        end
        else if (counter < ((sample_count*2)+1))
        begin
            clear <= 0;
            add <= ~add;
        end
        else begin
            clear <= 0;
            add <= 0;
            show <= 1;
        end

        if (counter < ((sample_count*2)+1))
        begin
            counter <= counter + 1;
        end
    end
end


endmodule
