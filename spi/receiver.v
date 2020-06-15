/**
 * This module implements a parameterizable SPI receiver.
 * Chip-select and clock signals are expected to be generated elsewhere.
 */

`ifndef SPI_RECEIVER_V
`define SPI_RECEIVER_V

module spi_receiver
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
         * CPHA = 0:
         *     The initial slave/chip-select edge has shifted out
         *     the first data bit. We start sampling with the first clock edge
         *     and every second clock edge after that.
         * CPHA = 1:
         *     Data bits are shifted out at the first clock edge.
         *     Accordingly, we sample the data input at the second clock edge.
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
         * 0 = Received data is written directly to the data output register
         * 1 = Received data is writte to the data output register at de-assertion of the slave-select signal
         */
        parameter use_gated_output = 1,

        /**
         * 0 = Pulsifiy slave-select signal internally (requires clock input)
         * 1 = Use trigger input to start a transfer (no clock required)
         */
        parameter use_external_trigger = 0
        )
    (
        /** Required for internal trigger signal generation */
        input clock,

        /** A positive pulse initiates a reception cycle */
        input trigger,

        /** Slave-select signal */
        input ss,

        /** The clock used for serial data input sampling */
        input sclk,

        /** Serial data input */
        input sdi,

        /** Acquired data value */
        output[bitcount-1:0] data,

        /** Transfer completion signal (active-high) */
        output reg complete
        );


/*
 * The internal select/chip-select signal is expected to be active-high.
 */
wire internal_ss;
if (ss_polarity == 0)
    assign internal_ss = ~ss;
else
    assign internal_ss = ss;


/*
 * The internal clock is expected to have CPOL = 1.
 */
wire internal_sclk;
if (sclk_polarity == 0)
    assign internal_sclk = ~sclk;
else
    assign internal_sclk = sclk;


/*
 * Select gated/un-gated data
 */
reg[bitcount-1:0] internal_data = 0;

// Declared here, because the switch is used for data gating:
reg internal_complete = 0;

if (use_gated_output == 0)
begin
    // Immediately pass received data downstream
    assign data = internal_data;
end
else begin
    // Receive to internal_data register first
    reg[bitcount-1:0] gated_data;
    initial gated_data <= 0;
    assign data = gated_data;

    /*
     * Copy internal to gated data when transfer is complete,
     * i.e. when the configured number of bits has been received
     */
    always @(posedge internal_complete)
        gated_data <= internal_data;
end


/*
 * The internal trigger signal is expected to be an active-high pulse
 */
wire internal_trigger;

if (use_external_trigger == 0)
begin
    // Generate trigger by pulsification of the initial slave-select edge
    reg internal_ss_pulsified = 0;
    reg previous_internal_ss = 0;
    always @(posedge clock)
    begin
        internal_ss_pulsified <= internal_ss && (~previous_internal_ss);
        previous_internal_ss <= internal_ss;
    end
    assign internal_trigger = internal_ss_pulsified;
end
else begin
    // Use the provided trigger input
    assign internal_trigger = trigger;
end


/*
 * Sample the data input
 */
reg[$clog2(bitcount):0] bitcounter = 0;
reg bitcounter_enable = 0;

always @(posedge internal_sclk or posedge internal_trigger)
begin
    if (internal_trigger)
    begin
        bitcounter <= 0;
        bitcounter_enable <= 1;
    end
    else begin
        if (bitcounter_enable)
        begin
            // Infer a shift register
            if (msb_first)
            begin
                // Shift new data bits into the register from the right
                internal_data[0] <= sdi;
                internal_data[bitcount-1:1] <= internal_data[bitcount-2:0];
            end
            else begin
                // Shift new data bits into the register from the left
                internal_data[bitcount-1] <= sdi;
                internal_data[bitcount-2:0] <= internal_data[bitcount-1:1];
            end

            // Increment number of received bits
            bitcounter <= bitcounter + 1;
        end

        // Stop receiving when the configured number of bits have arrived
        if (bitcounter >= bitcount-1)
            bitcounter_enable <= 0;
    end
end


/*
 * The complete signal is delayed
 * to make sure, the data is ready to be read
 */
initial complete <= 0;

always @(posedge clock or posedge internal_trigger)
begin
    if (internal_trigger)
    begin
        internal_complete <= 0;
        complete <= 0;
    end
    else begin
        // We assume, the transfer is complete as soon as the configured number of bits has been received
        if (((bitcounter >= bitcount)) && (~bitcounter_enable))
        begin
            internal_complete <= 1;
        end

        // The public complete signal is delayed after the internal one by one clock tick
        if (internal_complete)
            complete <= 1;
    end
end


endmodule

`endif
