/**
 * This module does nothing more than invert a signal, if that is configured.
 * Using this module shall allow for more readable, cleaner code.
 */

module polarity
    #(
        parameter inverted = 0
    )
    (
        input  in,
        output out
    );

if (inverted == 0)
    assign out = in;
else
    assign out = ~in;

endmodule
