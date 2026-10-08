import pyodbc

import sqlalchemy

class NewServerName:
    
   
    def __init__(self):
        self.server_name   =  'VIRWSDBS051\v051_01'
        self.database_instance = 'EDH_PSA_PRD'
        
        
    def sql_connect(self):
        
        return pyodbc.connect('Driver={SQL Server};'
                      'Server='+self.server_name+';'
                      'Database='+self.database_instance+';'
                      'Trusted_Connection=yes;')
        