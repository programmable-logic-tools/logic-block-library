`timescale 1ns/1ns
`define TESTBENCH

`include "spi/stimulus.v"


module test;


initial $dumpvars;

// Simulate 12 MHz quartz
reg clock = 0;
always #1 clock <= ~clock;

// Testbench stimulus signals
reg trigger = 0;
reg abort = 0;
reg invalidate = 0;

// One complete transfer
initial #3 trigger <= 1;
initial #5 trigger <= 0;

// One aborted transfer
initial #35 trigger <= 1;
initial #37 trigger <= 0;
initial #45 abort <= 1;
initial #47 abort <= 0;

// A complete but invalid transfer after an aborted transfer
initial #56 trigger <= 1;
initial #58 trigger <= 0;
initial #63 invalidate <= 1;
initial #65 invalidate <= 0;

// A complete transfer, which shall ignore an untimely trigger
initial #90 trigger <= 1;
initial #92 trigger <= 0;

// This trigger should be ignored
initial #96 trigger <= 1;
initial #98 trigger <= 0;

// End of test signal generation
initial #120 $finish;


/**
 * Test SPI stimulus generation
 */
spi_stimulus
    #(
        .bitcount       (4),
        .ss_polarity    (0),
        .sclk_polarity  (1),
        .tick_count_sclk_delay_leading  (1),
        .tick_count_sclk_delay_trailing (1)
    )
    spi_stimulus_mut
    (
        .clock      (clock),
        .trigger    (trigger),
        .abort      (abort),
        .invalidate (invalidate)
    );


endmodule
