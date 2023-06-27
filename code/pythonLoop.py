import sys
from time import time
from typing import Callable
import logging
import datetime
from pathlib import Path

#pass an argument of folder you wish to write to such as c:\\temp\\

myfile = Path(__file__).stem

logfile = "c:\\temp\\" + myfile + "_log.txt"

logging.basicConfig(filename=logfile, level=logging.DEBUG)
freq = 40000
secs = str(int(freq/1000))



class Timer:
    def __init__(self):
        self.last_milliseconds = 0

    def set(self, interval: int, function: Callable) -> None:
        milliseconds = round(time() * 1000)

        if milliseconds - self.last_milliseconds >= interval:
            function()
            self.last_milliseconds = milliseconds
           
def main():
    timer = Timer()
    while True:
        now = datetime.datetime.now()
        date_time = now.strftime("%m/%d/%Y, %H:%M:%S")
        # timer.set(5000, lambda: print("set_timer called."))
        message = date_time + ":" + "Test to see if " + myfile + " is running" + " every " + secs + " seconds"
        timer.set(freq, lambda: logging.debug(message))
       
main()
