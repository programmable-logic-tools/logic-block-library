/**
 * This module generates the SPI stimulus signals
 * chip/slave select (ss) and seriel clock (sclk).
 *
 * The number of clock cycles as well as the
 * polarity of both signals are parameterizable.
 * A rising edge on the complete output indicates,
 * that the configured number of clocks has been shifted out and
 * that the slave select signal has returned to it's inactive value.
 * The complete signal maybe be delayed by a parameterizable number of ticks.
 *
 * A rising edge on the trigger input initiates stimulus generation and
 * clears both, complete and aborted signals, but only if no
 * stimulus generation is currently ongoing.
 * In the latter case, the trigger input is ignored.
 *
 * A rising edge on the abort input stops possible ongoing transfers,
 * clears the complete signal and rises the aborted signal.
 *
 * A rising edge on the aborted output indicates,
 * that the stimulus generation was stopped using the abort input.
 * Slave select and clock output will return to their respective inactive values.
 */

`ifndef SPI_STIMULUS_V
`define SPI_STIMULUS_V

module spi_stimulus
    #(
        /**
         * Number of clock cycles to generate
         */
        parameter bitcount = 16,

        /**
         * Slave/chip-select polarity
         *  1 = Slave-select signal is active-high
         *  0 = Slave-select signal is active-low
         */
        parameter ss_polarity = 0,

        /**
         * CPOL = 0: The clock is low at beginning and end of the transfer.
         * CPOL = 1: The clock is high at beginning and end of the transfer.
         *
         * Source: https://upload.wikimedia.org/wikipedia/commons/6/6b/SPI_timing_diagram2.svg
         */
        parameter sclk_polarity = 0,

        /**
         * Number of clock ticks after the activation of the slave-select signal,
         * before the first clock edge is generated.
         */
        parameter tick_count_sclk_delay_leading = 0,

        /**
         * Number of clock ticks after the last edge of SCLK,
         * before the SPI slave-select signal shall be deactivated.
         */
        parameter tick_count_sclk_delay_trailing = 0,

        /**
         * Number of clock ticks at the trailing edge of the slave-select signal,
         * after which the completion indicating signal shall change.
         */
        parameter tick_count_complete_delay_trailing = 0
        )
    (
        input clock,
        input trigger,
        input abort,
        input invalidate,

        output ss,
        output sclk,

        output reg complete,
        output reg aborted,
        output reg valid
        );


initial complete <= 0;
initial aborted <= 0;
initial valid <= 0;


/**
 * The internal slave/chip-select signal
 * is active-high (polarity 1).
 *
 * Depending on the module's parametrization the
 * published slave-select signal may be inverted.
 */
reg internal_ss = 0;
if (ss_polarity == 0)
    assign ss = ~internal_ss;
else
    assign ss = internal_ss;


/**
 * The internal clock has polarity 0.
 *
 * Depending on the module's parametrization the
 * published serial clock may be inverted.
 */
reg internal_sclk = 0;
if (sclk_polarity == 0)
    assign sclk = internal_sclk;
else
    assign sclk = ~internal_sclk;


/*
 * State machine
 */
localparam STATE_IDLE = 0;
localparam STATE_SLAVE_SELECT = 1;
localparam STATE_CLOCK = 2;
localparam STATE_POST_CLOCK = 3;
localparam STATE_COMPLETE = 4;

reg[$clog2(STATE_COMPLETE):0] state = STATE_IDLE;


/*
 * A sclk_edge_counter controls the flow of SPI states
 */
localparam sclk_edge_sclk_edge_counter_overflow = 2*bitcount;
reg[$clog2(sclk_edge_sclk_edge_counter_overflow):0] sclk_edge_counter = 0;

// The $max() system function is non-standard. It requires Icarus Verilog and/or a patched version of Yosys.
localparam sclk_delay_counter_max = $max(tick_count_sclk_delay_leading, tick_count_sclk_delay_trailing);
reg[$clog2(sclk_delay_counter_max):0] sclk_delay_counter = 0;

always @(posedge clock)
begin
    case (state)
        STATE_IDLE:
        begin
            internal_ss <= 0;
            sclk_delay_counter <= 0;

            // Wait for activation
            if (trigger == 1)
            begin
                complete <= 0;
                aborted <= 0;
                internal_ss <= 1;
                valid <= 1;
                if (tick_count_sclk_delay_leading > 0)
                    state <= STATE_SLAVE_SELECT;
                else
                    state <= STATE_CLOCK;
            end
        end

        STATE_SLAVE_SELECT:
        begin
            // Wait the parameterized number of ticks before clocking
            sclk_delay_counter <= sclk_delay_counter + 1;
            if (sclk_delay_counter >= tick_count_sclk_delay_leading-1)
                state <= STATE_CLOCK;
            sclk_edge_counter <= 0;
        end

        STATE_CLOCK:
        begin
            // Generate the parameterized number of clock pulses
            internal_sclk <= ~internal_sclk;
            sclk_delay_counter <= 0;
            sclk_edge_counter <= sclk_edge_counter + 1;
            if (sclk_edge_counter >= sclk_edge_sclk_edge_counter_overflow-1)
            begin
                if (tick_count_sclk_delay_trailing > 0)
                    state <= STATE_POST_CLOCK;
                else
                    state <= STATE_COMPLETE;
            end
        end

        STATE_POST_CLOCK:
        begin
            // Wait the parameterized number of ticks before deactivating slave-select
            sclk_delay_counter <= sclk_delay_counter + 1;
            if (sclk_delay_counter >= tick_count_sclk_delay_trailing-1)
            begin
                state <= STATE_COMPLETE;
                sclk_delay_counter <= 0;
            end
        end

        STATE_COMPLETE:
        begin
            internal_ss <= 0;
            sclk_edge_counter <= 0;
            sclk_delay_counter <= sclk_delay_counter + 1;
            if (sclk_delay_counter >= tick_count_complete_delay_trailing)
            begin
                sclk_delay_counter <= 0;
                state <= STATE_IDLE;
                complete <= valid;
            end
        end

        default:
        begin
            // Other states than the ones defined above should not be reachable.
            state <= STATE_IDLE;
        end
    endcase

    if (abort == 1)
    begin
        internal_ss <= 0;
        internal_sclk <= 0;
        aborted <= 1;
        sclk_delay_counter <= 0;
        sclk_edge_counter <= 0;
        state <= STATE_IDLE;
    end

    if (invalidate == 1)
        valid <= 0;
end


endmodule

`endif
