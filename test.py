
"""
Convert PDF into csv

Step 1/5

"""

FileName = 'ACCTREAD'

# from docx import Document

# from docx.shared import Inches


import tabula

### scrap PDF file pages 30-51 into an csv output file

if FileName == 'ACCTREAD':
    pages_no = '91-93'
elif FileName == 'STMTEMAIL':
    pages_no = '30-51'
    
tabula.convert_into("file:///C:/Users/miw/Desktop/py3/DataProgram/CDE754_File_Formats_Issuing_TRG_01_18_CUS.pdf",\
                         "Cadencie_File_Definitions.csv", output_format ="csv", pages =pages_no, stream = True)

