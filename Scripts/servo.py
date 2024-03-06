#! /usr/bin/python

"""
The number of Mac mini (from 1 to 16) and 
the number of seconds for which the button
will be pressed on each mac are taken as arguments
"""

from sys import argv
import time
from adafruit_servokit import ServoKit
from servo_parameters import *
script, mac, delay = argv
mac = int(mac)
delay = float(delay)
port = mac // 2 + mac % 2 - 1 # for macs 1,2 servoHAT port is 0; 2,3 = 1; 3,4 = 2; etc..
zero_angle = 100
adj = servo_adjustment[port]
kit = ServoKit(channels=16)
print("Mac: ", mac, "; Delay: ", delay)
if mac % 2 != 0:
    angle = 80
else:
    angle = 120
print("Port: ", port, " ; Angle: ", angle)
kit.servo[port].angle = angle + adj
time.sleep(delay)
kit.servo[port].angle = zero_angle + adj - 8 #Dirty hack to get a stable servo position
time.sleep(0.3)
kit.servo[port].angle = zero_angle + adj + 8 #Dirty hack to get a stable servo position
time.sleep(0.3)
kit.servo[port].angle = zero_angle + adj
time.sleep(0.3)
kit.servo[port].angle = None

