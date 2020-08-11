/**
 * The watchdog monitors a register of parameterizeable width for changes.
 * Depending on it configuration, it can either alert upstream modules
 * as soon as the register changes it's value or
 * when the register hasn't changed it's value for a configurable number of clock cycles.
 */

module watchdog
    #(
        parameter bitwidth = 8,

        /**
         * Set to non-zero value in order to monitor the input register for changes
         */
        parameter enable_alert_on_value_change = 1,

        /**
         * Set to non-zero value in order to alert as soon as the input register remains unchanged
         */
        parameter enable_alert_on_value_unchanged = 0,

        /**
         * The number of clock cycles to wait before raises the value unchanged flag
         * when the input register has stopped changing.
         * Requires the corresponding alert to be enabled.
         */
        parameter value_change_timeout = 1
        )
    (
        input clock,

        /*
         * The watchdog alert outputs can only be reset using this signal.
         */
        input reset,

        /**
         * The monitored input register
         */
        input[bitwidth-1:0] monitored_value,

        /**
         * This output is initially 0 and rises to 1 as soon as the input register value changes.
         * After that the output can only be reset using the reset input.
         */
        output reg alert_value_changed,

        /**
         * This output is initially 0 and rises to 1 once the input register hasn't changed
         * it's value for the configured number of clock cycles.
         * After that the output can only be reset using the reset input.
         */
        output reg alert_value_unchanged
        );


initial alert_value_changed <= 0;
initial alert_value_unchanged <= 0;

reg[bitwidth-1:0] reference_value = 0;
reg value_changed = 0;

always @(posedge clock)
begin
    if (reset == 1)
    begin
        alert_value_changed <= 0;
        alert_value_unchanged <= 0;
    end
    else begin
        if (value_changed)
        begin
            alert_value_changed <= 1;
        end
        else begin
            alert_value_unchanged <= 1;
            // TODO: Wait for configured number of clock cycles
        end
    end

    value_changed <= (monitored_value != reference_value);
    reference_value <= monitored_value;
end


endmodule
