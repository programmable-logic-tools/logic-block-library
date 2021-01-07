/**
 * RS-232 Universal Asynchronous Receiver/Transmitter (UART)
 */

module uart(
    input  clock,

    input  rx,

    output has_received,
    output [7:0] rx_byte,
    );

// generate baud rate from main clock
// 12 MHz / 1250 = 9600
// 12 MHz / 104 = 115200
// 90 MHz / 781 = 115200
parameter divider = 104;
parameter half_tick = divider / 2;
reg[11:0] counter;
initial counter = divider;

// are we receiving bits just now
reg receiving;
initial receiving = 0;

// which bit we are receiving currently
reg[3:0] bit_counter;

// reset
//initial has_received = 0;
initial rx_byte = 8'b0;

// output buffering is obligatory,
// if we wish to use the signals again within this module
reg[7:0] buffer;

always @(posedge clock)
begin
    if ((!receiving)     // not yet receiving
     && (rx == 0))       // start bit
    begin
        // skip start bit and resume in the middle of the first bit
        counter = divider + half_tick;

        receiving = 1;
        buffer = 8'b0;
        bit_counter = 0;
    end

    if (receiving)
    begin
        counter = counter - 1;

        if (counter == 0)
        begin
            // This block is evaluated at 115200 Hz

            // reset clock division counter
            counter = divider;

            if (bit_counter < 8)
            begin
                // save incoming bit at corresponding position in vector
                buffer[bit_counter] = rx;
            end

            else if (bit_counter == 8)
            begin
                // 8 bits have been received
                rx_byte = buffer;
            end

            else if (bit_counter == 9)
            begin
                has_received = 1;
            end

            else if (bit_counter == 10)
            begin
                has_received = 0;
                receiving    = 0;
            end

            bit_counter = bit_counter + 1;

        end // UART clock

    end // start bit received
end

endmodule
