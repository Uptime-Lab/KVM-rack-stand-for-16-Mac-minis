#! /usr/bin/python

"""
The number of seconds the button 
will be pressed on each mac is taken as an argument.
Script turns the servo 120 degrees and then 80 degrees. 
Thus presses the buttons on both Mac Minis it serves.
"""

from adafruit_servokit import ServoKit
from sys import argv
import time
from servo_parameters import *
script, delay = argv
delay = float(delay)
print("delay: ", delay)
kit = ServoKit(channels=16)
for n, adj in zip(range(0, 8), servo_adjustment):
        kit.servo[n].angle = 120 + adj
        print("port ", n, " ; angle 120")
        time.sleep(delay)
        kit.servo[n].angle = 100 + adj
        time.sleep(0.50)
        kit.servo[n].angle = None

        kit.servo[n].angle = 80 + adj
        print("port ", n, " ; angle 80")
        time.sleep(delay)
        kit.servo[n].angle = 100 + adj
        time.sleep(0.50)
        kit.servo[n].angle = None
