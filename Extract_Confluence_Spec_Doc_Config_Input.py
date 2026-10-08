#!/usr/bin/env python
# coding: utf-8

# In[ ]:


"""
  Working copy to extract confluence spec doc columns table
  Pre-cursor : "confluenceSpecDocConfig.txt" must present where this program is run
  Step 1 : Ask the user the target url in which SPEC DOC columns table needs to be extracted
  Step 2 : Job proceed....
  Step 3 : Output - confluence_extract0011.xlsx is created
  
"""

import requests 
import pandas as pd
from bs4 import BeautifulSoup
from requests.auth import HTTPBasicAuth
from datetime import datetime
import json
import os


#####


class HTMLTableParser:
    
    def __init__(self, url, my_config_js) :
        self.url = url
        self.config_js = my_config_js
        
        
    ### this function is being called within the class    
    

        
    def parse_url(self):
        
        
        ### this function is being called within the class    
        def create_df(table_in):

            n_columns = 0
            n_rows=0
            column_names = []

            # Find number of rows and columns
            # we also find the column titles if we can
            for row in table_in.find_all('tr'):

                # Determine the number of rows in the table
                td_tags = row.find_all('td')
                if len(td_tags) > 0:
                    n_rows+=1
                    if n_columns == 0:
                        # Set the number of columns for our table
                        n_columns = len(td_tags)

                # Handle column names if we find them
                th_tags = row.find_all('th') 
                if len(th_tags) > 0 and len(column_names) == 0:
                    for th in th_tags:
                        column_names.append(th.get_text())

            # Safeguard on Column Titles
            if len(column_names) > 0 and len(column_names) != n_columns:
                raise Exception("Column titles do not match the number of columns")

            columns = column_names if len(column_names) > 0 else range(0,n_columns)
            df = pd.DataFrame(columns = columns,
                              index= range(0,n_rows))
            row_marker = 0
            for row in table_in.find_all('tr'):
                column_marker = 0
                columns = row.find_all('td')
                for column in columns:
                    df.iat[row_marker,column_marker] = column.get_text()
                    #print("columns text nnnnnnnnnnnnnnnnn ",column.get_text() )
                    column_marker += 1
                if len(columns) > 0:
                    row_marker += 1

            # Convert to float if possible
            for col in df:
                try:
                    df[col] = df[col].astype(float)
                except ValueError:
                    pass

            return df
    
        
        ## retrieve the proxy from the configuration file
        http_proxy = self.config_js['proxy']
        
        https_proxy = self.config_js['proxy']
        
        

    
        proxyDict ={"http": http_proxy,"https": https_proxy, "authenticate":True,"href": self.config_js['href']}

        # retrieve the email from the configuration file
        EMAIL = self.config_js['email']
              

        my_auth = HTTPBasicAuth(EMAIL, self.config_js['api_token'])
        
        try :
            response = requests.get(self.url, auth=my_auth, proxies=proxyDict)
        except :
            print("Error requesting for url : ", self.url)
        else :
            print(f"Request to url {self.url} succeeded")
        
        ### replace <br> tag with carriage return "\n"
        ### Calling soup
        soup = BeautifulSoup(response.text.replace("<br/>","\n"), 'lxml')
        
        cnt = 0
        for table in soup.find_all('table'):
            cnt += 1
            #print(f"table {cnt} &&&&&&&&&&&&&       ", table, "\n\n\n\n")
            
            ### confluence table number 5 is the data dictionary data due to the of the template; this is configurable in config file
            if cnt == self.config_js['confluence_table']: 
                
                #print("table  data @@@@@@@@@  ", table )
                df = create_df(table)
                print("\nSpec Doc Dataframe creation successed.\n")
                try :
                    df.to_excel("confluence_extract001.xlsx", index = None)
                except :
                    print("Excel file fail to create")
                else :
                    print("Excel file created!")
                    
                    

 
    
##############################
###### Main Program
##############################

### setup the url to scrap
#my_url ="https://cua.atlassian.net/wiki/spaces/DP/pages/1842511873/Draft+CUSC"

## Ask the user the target confluence url to extract
target_url = input("Enter target confluence url to extract the columns table?")

## Play back the target confluence url to extract
print(f"Please confirm this is the url you meant? {target_url}")

my_url = target_url

## Open the configuration file in the current directory as read mode
with open(os.getcwd()+"\\confluenceSpecDocConfig.txt", "r") as f:
    confg_data = f.read()
    
f.close()

#### Load the json file into a dictionary
my_config_js = json.loads(confg_data)
    
print("loaded data from config")    
tp = HTMLTableParser(my_url, my_config_js)
tp.parse_url()

              

