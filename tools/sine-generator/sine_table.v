
`ifndef SINE_TABLE_V
`define SINE_TABLE_V

module sine_table
    #(
        /*
         * Only certain combinations of address/data bitwidth are
         * supported by hardware. Please refer to the technology library.
         */
        parameter bitwidth_address = 9,
        parameter bitwidth_data = 8,

        // This must fit into the address space
        parameter table_entry_count = 560,

        // How many clock cycles to wait before accepting the yielded sine value
        parameter delay_counter_overflow = 4
        )
    (
        input clock,
        input trigger_read,
        input[bitwidth_address-1:0] address,
        output reg[bitwidth_data-1:0] value,
        output reg data_ready
        );

/*
 * Infer RAM blocks
 */
reg[bitwidth_data-1:0] sine_table[0:table_entry_count-1];

// Address updates are only accepted upon rising edge of the trigger
reg[bitwidth_address-1:0] shadow_address = 0;

/*
 * Import RAM content from file
 */
initial $readmemb("src/control/modes/u-to-f/sine_table.mem", sine_table);

/*
 * RAM access logic
 */
reg internal_data_ready = 0;
always @(posedge clock)
begin
    if (trigger_read)
    begin
        shadow_address <= address;
        internal_data_ready <= 0;
    end
    else begin
        value <= sine_table[shadow_address];
        internal_data_ready <= 1;
    end
end

/*
 * The data is only ready after a couple of clock cycles
 */
reg[$clog2(delay_counter_overflow):0] delay_counter = 0;

always @(posedge clock)
begin
    if (trigger_read)
    begin
        delay_counter <= 0;
        data_ready <= 0;
    end
    else begin
        if (delay_counter < delay_counter_overflow)
            delay_counter <= delay_counter + 1;
        if (delay_counter >= delay_counter_overflow)
            data_ready <= 1;
    end
end

endmodule

`endif
