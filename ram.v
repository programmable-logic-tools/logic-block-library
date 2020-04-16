
`ifndef MEMORY_V
`define MEMORY_V

module memory(
    input clock,

    input perform_read,
    input [8:0] read_address,
    output reg[23:0] read_data,
    output reg read_data_ready,

    // Note: Holding perform_write low is obligatory, if the write port is not used, otherwise memory content may be overwritten.
    input perform_write,
    input [8:0] write_address,
    input [23:0] write_data
    );

// Dual-ported RAM, see also Silicon Blue iCE40 Technology Library
reg[7:0] mem0[0:511];
reg[7:0] mem1[0:511];
reg[7:0] mem2[0:511];

always @(posedge clock)
begin
    // Read
    if (perform_read)
    begin
        // read_data[23:0] <= 24'h808080;
        read_data[23:16] <= mem2[read_address];
        read_data[15:8] <= mem1[read_address];
        read_data[7:0] <= mem0[read_address];
    end

    // Write
    if (perform_write)
    begin
        mem2[write_address] <= write_data[23:16];
        mem1[write_address] <= write_data[15:8];
        mem0[write_address] <= write_data[7:0];
    end
end

// Assume, data from the RAM is available at the next clock
always @(posedge clock) read_data_ready <= perform_read;

endmodule

`endif
