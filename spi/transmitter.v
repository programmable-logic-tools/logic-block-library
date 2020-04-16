/**
 * This module implements a parameterizable SPI transmitter.
 * Chip-select and clock signals are expected to be generated elsewhere.
 */

`ifndef SPI_TRANSMITTER_V
`define SPI_TRANSMITTER_V

module spi_transmitter
    #(
        /**
         * Number of bits to receive
         */
        parameter bitcount = 16,

        /**
         * Slave/chip-select polarity
         *  1 = Non-inverted / active high
         *  0 = Inverted / active low
         */
        parameter ss_polarity = 0,

        /**
         * CPOL = 0: The clock is low at the beginning of the transfer.
         * CPOL = 1: The clock is high at the beginning of the transfer.
         */
        parameter sclk_polarity = 1,

        /**
         * CPHA = 0: The initial slave/chip-select edge shifts out the first bit, sampling starts with the first clock edge.
         * CPHA = 1: Data is shifted out at the first clock edge, sampled at the second and so on.
         *
         * TODO: Implement...
         *       At the moment only CPHA = 1 is supported.
         */
        parameter sclk_phase = 1,

        /**
         * 0 = The least significant data bit is transmitted first.
         * 1 = The most significant data bit is transmitted first.
         */
        parameter msb_first = 1,

        /**
         * 0 = Data is transmitted without internal shadowing.
         * 1 = Data to be transmitted is loaded at the rising edge of the load input.
         */
        parameter use_load_input = 1
        )
    (
        /** Required for pulsification of the slave-select and load signals */
        input clock,

        /** Slave-select signal (generated elsewhere) */
        input ss,

        /** The serial clock used for shifting data bits out (generated elsewhere) */
        input sclk,

        /** Serial data output */
        output reg sdo,

        /** Data to be sent */
        input [bitcount-1:0] data,

        /** Load input data (active-high, edge or pulse) */
        input load,

        /** Active-high transfer complete signal */
        output reg complete
        );


/*
 * The internal slave/chip-select signal is expected active-low
 */
wire internal_ss;

if (ss_polarity == 0)
    assign internal_ss = ss;
else
    assign internal_ss = ~ss;


/*
 * The internal clock polarity is expected CPOL = 0
 */
wire internal_sclk;

if (sclk_polarity == 0)
    assign internal_sclk = sclk;
else
    assign internal_sclk = ~sclk;


/*
 * Pulsify the load input signal (active-high)
 */
reg load_pulsified = 0;
reg previous_load = 0;
always @(posedge clock)
begin
    load_pulsified <= (load && (~previous_load));
    previous_load <= load;
end


/*
 * Local copy of the data to be sent
 */
reg[bitcount-1:0] shadowed_data = 0;

always @(posedge load_pulsified)
begin
    shadowed_data <= data;
end


/*
 * Select shadowed or direct data source
 */
wire[bitcount-1:0] internal_data;
if (use_load_input)
    assign internal_data = shadowed_data;
else
    assign internal_data = data;


/*
 * Shift bits out
 */
initial sdo <= 0;
reg[$clog2(bitcount)-1:0] bitcounter = bitcount-1;

always @(posedge internal_sclk or posedge internal_ss)
begin
    // The internal slave-select signal is active-low.
    if (internal_ss)
    begin
        if (msb_first == 1)
            bitcounter <= bitcount-1;
        else
            bitcounter <= 0;

        sdo <= 0;
        complete <= 0;
    end
    else begin
        if (msb_first == 1)
        begin
            // Most significant bit first: Bitcounter is counting downwards
            if (bitcounter > 0)
            begin
                bitcounter <= bitcounter - 1;
            end
            else begin
                complete <= 1;
            end
        end
        else begin
            // Least significant bit first: Bitcounter is counting upwards
            if (bitcounter < bitcount-1)
            begin
                bitcounter <= bitcounter + 1;
            end
            else begin
                complete <= 1;
            end
        end

    sdo <= internal_data[bitcounter];
    end
end


endmodule

`endif
