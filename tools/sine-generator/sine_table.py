#!/usr/bin/python3

import math
import sys

def frequency2string(f):
    if f >= 1e6:
        return "{:d} MHz".format(int(f/1e6))
    if f >= 1e3:
        return "{:d} kHz".format(int(f/1e3))
    return "{:d} Hz".format(int(f))


# Desired RAM configuration
bitwidth_data = 16
bitwidth_address = 8
print("// Desired RAM configuration: abits={:d}, dbits={:d}".format(bitwidth_address, bitwidth_data))

# Primary clock frequency
f_clock = 80e6
print("// FPGA clock frequency: {:s}".format(frequency2string(f_clock)))

# Switching frequency
f_switching = 140e3
print("// Switching frequency: {:s}".format(frequency2string(f_switching)))

# PWM period tick count
tick_count_period = int(f_clock / f_switching)
print("// Ticks per switching period: {:d}".format(tick_count_period))

if math.ceil(math.log(tick_count_period, 2)) > bitwidth_data:
    print("Error: {:d} ticks per period are not achievable with {:d} data bits.".format(tick_count_period, bitwidth_data))
    sys.exit(1)

# Desired sine frequency
f_sine = 50
print("// Desired sine frequency: {:s}".format(frequency2string(f_sine)))

# Frequency of duty cycle updates
f_timer = 10e3
print("// Duty cycle update frequency: {:s}".format(frequency2string(f_timer)))

# Required sine table length
sine_table_length = int(f_timer/f_sine)
print("// Sine table has {:d} entries.".format(sine_table_length))

if math.ceil(math.log(sine_table_length, 2)) > bitwidth_address:
    print("Error: Sine table with {:d} entries doesn't fit into {:d} bit address space.".format(sine_table_length, bitwidth_address))
    sys.exit(2)

amplitude = tick_count_period-1
offset = amplitude/2.0

for row in range(sine_table_length):
    sine = math.sin(2*math.pi*row/(sine_table_length-1))
    dutycycle = int(sine * amplitude/2.0 + offset)
    if dutycycle < 0:
        dutycycle = 0
    if dutycycle > amplitude:
        dutycycle = amplitude
    binary = bin(int(dutycycle))[2:].zfill(bitwidth_data)
    print("{:s}    // Table entry # {:d}, sine value: {:.2f}, dutycycle: {:d}".format(binary, row, sine, dutycycle))
