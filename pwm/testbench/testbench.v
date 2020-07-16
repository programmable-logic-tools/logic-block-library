`timescale 1ns/1ns

`include "pwm/advanced.v"

module test;

initial $dumpvars;

// Simulate 12 MHz quartz
reg clock;
initial clock <= 0;
always #1 clock <= ~clock;

// The PWM outputs must remain low until reset is released
reg reset = 1;
initial #9 reset <= 0;

// End of test signal generation
initial #6000 $finish;



localparam bitwidth = 8;
reg[bitwidth-1:0] tick_count_period = 20;
reg[bitwidth-1:0] tick_count_highside = 7;
reg[bitwidth-1:0] tick_count_lowside = 8;
reg[bitwidth-1:0] deadtime_hs_to_ls = 3;
reg[bitwidth-1:0] deadtime_ls_to_hs = 2;


pwm #(
        .use_external_counter   (0),
        .bitwidth               (bitwidth)
    )
    pwm0 (
        .clock                  (clock),
        .reset                  (reset),

        .tick_count_period      (tick_count_period),
        .tick_count_highside    (tick_count_highside),
        .tick_count_lowside     (tick_count_lowside),
        .deadtime_hs_to_ls      (deadtime_hs_to_ls),
        .deadtime_ls_to_hs      (deadtime_ls_to_hs),

        .configuration_load_enable  (1'b1)
        );


endmodule
