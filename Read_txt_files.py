"""
This program read 
Author : Margaret Woon
Version : 0.001
Date : 2026/8/31
"""
import os
import shutil
from datetime import datetime
import pandas as pd
from pathlib import Path
import time
import csv


# Load the Excel file
file_path = r"file:///C:\Users\miw\Downloads\110001-TRANSACTION_DATA-20260827130748.txt"


try :# Read the excel file
    with open(file_path, mode="r", newline="", encoding="utf-8") as file:
        
        for line in file:
            print(line)
            
except FileNotFoundError:
    print("Error : The file was not found")

except csv.Error as e:
    print(f"CSV error : {e}")