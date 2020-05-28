`timescale 1ns/1ns
`define TESTBENCH

`include "spi/stimulus.v"
`include "spi/transmitter.v"


module test;

parameter bitcount = 8;
parameter ss_polarity = 0;
parameter sclk_polarity = 1;
parameter msb_first = 1;
parameter use_load_input = 1;


initial $dumpvars;

// Simulate 12 MHz quartz
reg clock = 0;
always #1 clock <= ~clock;

// Trigger a measurement
reg trigger = 0;
initial #3 trigger <= 1;
initial #7 trigger <= 0;
initial #65 trigger <= 1;
initial #69 trigger <= 0;

// End of test signal generation
initial #150 $finish;

reg[bitcount-1:0] testdata;
initial testdata <= 8'h3b;
initial #60 testdata <= 8'h8e;


/**
 * SPI stimulus with positive clock polarity
 * and non-inverted chip-select signal
 */
wire ss, sclk;

spi_stimulus
    #(
        .bitcount       (bitcount),
        .ss_polarity    (ss_polarity),
        .sclk_polarity  (sclk_polarity)
    )
    stimulus
    (
        .clock      (clock),
        .trigger    (trigger),
        .ss         (ss),
        .sclk       (sclk)
    );

/**
 * SPI transmitter
 */
spi_transmitter
    #(
        .ss_polarity    (ss_polarity),
        .sclk_polarity  (sclk_polarity),
        .sclk_phase     (1),
        .bitcount       (bitcount),
        .msb_first      (msb_first),
        .use_load_input (use_load_input)
    )
    mut
    (
        .clock      (clock),
        .ss         (ss),
        .sclk       (sclk),
        .load       (trigger),
        .data       (testdata)
    );


endmodule
