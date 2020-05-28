`timescale 1ns/1ns
`define TESTBENCH

`include "spi/stimulus.v"
`include "spi/receiver.v"


module test;

parameter bitcount = 4;
parameter ss_polarity = 1;
parameter sclk_polarity = 0;
parameter sclk_phase = 1;
parameter msb_first = 1;
parameter use_gated_output = 1;


initial $dumpvars;

// Simulate 12 MHz quartz
reg clock = 0;
always #1 clock <= ~clock;
reg clock_1_2 = 0;
always #2 clock_1_2 <= ~clock_1_2;

// Trigger a measurement
reg trigger = 0;
initial
begin
    #3 trigger <= 1;
    #4 trigger <= 0;
    #60 trigger <= 1;
    #4 trigger <= 0;
end
// initial #5 trigger <= 0;

// End of test signal generation
initial #150 $finish;


/**
 * SPI stimulus with positive clock polarity
 * and non-inverted chip-select signal
 */
wire ss, sclk;
reg mosi;
initial mosi <= 1;
initial #60 mosi <= 0;

spi_stimulus
    #(
        .bitcount       (bitcount),
        .ss_polarity    (ss_polarity),
        .sclk_polarity  (sclk_polarity)
    )
    stimulus
    (
        .clock      (clock_1_2),
        .trigger    (trigger),
        .ss         (ss),
        .sclk       (sclk)
    );

/**
 * SPI receiver as slave
 */
spi_receiver
    #(
        .ss_polarity            (ss_polarity),
        .sclk_polarity          (sclk_polarity),
        .sclk_phase             (sclk_phase),
        .bitcount               (bitcount-1),
        .msb_first              (msb_first),
        .use_gated_output       (1),
        .use_external_trigger   (0)
    )
    mut
    (
        .clock      (clock),
        .ss         (ss),
        .sclk       (sclk),
        .sdi        (mosi)
    );


endmodule
