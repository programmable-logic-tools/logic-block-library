
module ws2812(
    input clock,

    input[23:0] value,
    input trigger,

    output reg pin
    );


reg trigger_pulsified = 0;
reg trigger_previous = 0;

always @(posedge clock)
begin
    if (trigger && !trigger_previous)
        trigger_pulsified <= 1;
    else
        trigger_pulsified <= 0;

    trigger_previous <= trigger;
end


reg[(3*8*3)-1:0] shadow_value;

integer i=0;

reg[6:0] bit_counter = 0;

// The commented line part below caused problems during pnr: "'$_DFFSR_PPP_' is unsupported"
// always @*
// always @(posedge clock or posedge trigger_pulsified)
always @(posedge clock)
begin
    if (trigger_pulsified)
    begin
        // Load value
        for (i=0; i<24; i=i+1)
        begin
            shadow_value[72-(i*3)-1] <= 1;
            shadow_value[72-(i*3)-2] <= value[24-i-1];
            shadow_value[72-(i*3)-3] <= 0;
        end

        // Reset output pin
        pin <= 0;

        bit_counter <= 71;
    end
    else begin
        // Set pin output to most significant value bit
        // pin <= shadow_value[23];
        pin <= shadow_value[bit_counter];

        if (bit_counter > 0)
            bit_counter <= bit_counter - 1;

        // Shift data one bit to the left
        // shadow_value[23:0] <= {shadow_value[22:0], 1'b0};
    end
end

endmodule
