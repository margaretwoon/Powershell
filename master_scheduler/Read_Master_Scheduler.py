"""
This program search through the master scheduler and display the rows of where target search string is found
Author : Margaret Woon
Version : 0.001
Date : 2026/07/03
"""
import os
import shutil
from datetime import datetime
import pandas as pd
from pathlib import Path


# Load the Excel file
file_path = r"file:///S:\GoAnywhere\Backup\Production\Current\Scheduler\Scheduler%20Specification_MASTER.xlsx"

# Read the excel file
xls = pd.ExcelFile(file_path)


# replace the target search string here
#search_string = r"\\\\cua.com.au\\CORP\\shared\\BusinessDropZone\\PRD\\Bancs Files\\"
search_string = r"resource:s3://data-platform-storage-prod/iChris/prod/in/"
#search_string = r"iChris"
#s3://edp-prod-raw-cua-com-au-ap-southeast-2-563366309653/constantinople/prod/
#search_string = r"constantinople"

#search_string = "resource:s3://data-platform-storage-prod/sbb_customer_matching/prod/out"

"""
virwsapp253/sasmetaprd002
virwsapp257/sascompprd002
virwsweb024/infomgmtprd002
virwsapp259/sasnasprd001

"""

file_name = 'output'
 
output_path = r"C:\\Users\\miw\\OneDrive - Great Southern Bank\\Documents\\py3\\DataProgram\\output\\master_scheduler_targeted_search_output.txt"

print(f"output_path {output_path}")

with open(output_path, "w", encoding="utf-8") as file:

    clean_search_string = search_string.replace("\\\\", "\\")
    print(f"clean_search_string : {clean_search_string}\n")

    datetime_now = datetime.now().strftime("%d/%m/%Y, %H:%M:%S")
                                
    file.write(f"Job Started at {datetime_now}\n")

    for sheet in xls.sheet_names:
        
        #print(f"sheet : {sheet}")
        df = pd.read_excel(file_path, sheet_name = sheet)
        # find the search string and the Trigger_State is "A"
        #mask = (df.astype(str).apply(lambda row : row.str.contains(search_string, case = False, na=False)).any(axis = 1)) & (df["Trigger_State"].astype(str).str.upper().str.strip() == "A")

        mask = (df.astype(str).apply(lambda row : row.str.contains(search_string, case = False, na=False)).any(axis = 1))

        matching_rows = df[mask]

        #print(f'matching_rows {matching_rows}')

        for index, row in matching_rows.iterrows():
            file.write(f"search string :: {clean_search_string}\n")

            result_df = row.to_dict()
            for k, v in result_df.items():
                file.write(f"Sheet Name : {sheet}, Row : {index + 2}, {k} : {v}\n")

            file.write(f"="*150)
            file.write("\n")


    datetime_now = datetime.now().strftime("%d/%m/%Y, %H:%M:%S")

    file.write(f"Job completed at {datetime_now}\n")
                        
file.close()

output_path = r"C:\\Users\\miw\\OneDrive - Great Southern Bank\\Documents\\py3\\DataProgram\\output\\master_scheduler_full_list.txt"
with open(output_path, "w", encoding="utf-8") as file:

    datetime_now = datetime.now().strftime("%d/%m/%Y, %H:%M:%S")
                                
    file.write(f"Job Started at {datetime_now}\n")

    for sheet in xls.sheet_names:
        df = pd.read_excel(file_path, sheet_name = sheet)
        matching_rows = df

        for index, row in matching_rows.iterrows():

            result_df = row.to_dict()
            for k, v in result_df.items():
                file.write(f"Sheet Name : {sheet}, Row : {index + 2}, {k} : {v}\n")

            file.write(f"="*150)
            file.write("\n")


    datetime_now = datetime.now().strftime("%d/%m/%Y, %H:%M:%S")

    file.write(f"Job completed at {datetime_now}\n")
                        
file.close()
