"""
This program move Cusomter Feedback files from source directory to a target network directory
Author : Margaret Woon
Version : 0.001
Date : 2026/09/14
"""
import os
import csv
import shutil
from datetime import datetime
import re
import pandas as pd

def move_files(from_directory, to_directory):
    files_processed = []
    print(f"source_directory --> {from_directory}")
    print(f"target_directory --> {to_directory}")
    for root, dirs, files in os.walk(from_directory):  
  
        #if os.path.basename(root).startswith(f"{date_now}"):
        #print(f"dir_name : {os.path.basename(root)}")
        for file in files:
            #print(f"file name  {file}")
            if file.startswith('Customer_Feedback_'):

                df = pd.read_csv(os.path.join(root, file))

                # rename columns
                df.rename(columns={"Cost Centre":"AFCA Cost Centre"}, inplace = True)

                #rename the second Resolution Outcome to AFCA Resolution Outcome

                df.rename(columns={"Resolution Outcome.1":"AFCA Resolution Outcome"}, inplace = True)

                df.rename(columns={"Complaint Summary – Underlying Issue":"Complaint Summary - Underlying Issue"}, inplace = True)

                old_name_str = str(file)

                int_file_name_str1 = re.sub(r"(\d{4})-(\d{2})-(\d{2})", r"\1\2\3", old_name_str)

                int_file_name_str2 = re.sub(r"_\d+(?=\.csv$)", datetime.now().strftime('%H%M%S'), int_file_name_str1)

                new_file_name_str = int_file_name_str2

                target_path = os.path.join(to_directory, new_file_name_str)
                print(f"target_path :{target_path}")
                try:
                    df.to_csv(target_path, index=False, quoting = csv.QUOTE_ALL)
                    os.remove(os.path.join(root, file))
                    files_processed.append(os.path.join(root, file))
                except PermissionError:
                    print("Permission denied. Check file locks or folder write-rights.")
                except OSError as e:
                    print(f"Filesystem or metadata error occurred: {e}")

    return files_processed


date_now = datetime.now().strftime("%Y%m%d")
print(f"Today's date : {date_now}")

datetime_now = datetime.now().strftime("%d/%m/%Y, %H:%M:%S")
                        
print(f"Job Started at {datetime_now}\n")
      
source_directory = r'C:\\Users\\miw\\Downloads\\'

target_directory = r'S:\\Data Transfer\\databricks\\protecht\\prod\\in\\'

# Initialize the output file

outputfile = f'customer_feedback_copied_output.txt'

if __name__ == "__main__":   

    files_copied = move_files(source_directory, target_directory)

   
datetime_now = datetime.now().strftime("%d/%m/%Y, %H:%M:%S")
                        
print(f"Job Completed at {datetime_now}\n")