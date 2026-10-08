import requests

from zeep import Client
from zeep.transports import Transport

import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

base_url = "https://gsb-test.archerirm.com.au/platformapi/core/security/login"

wsdl = "https://gsb-test.archerirm.com.au/ws/search.asmx?WSDL"


payload = {
    "InstanceName": "710144",
    "Username": "databricks_service_test",
    "UserDomain": "Test",
    "Password": "Archer@123!!"
}
response = requests.post(base_url, json=payload, verify=False)

print(response.status_code)
print(response.text)

login_json = response.json()

session_token = login_json["RequestedObject"]["SessionToken"]

print("Login successful")
print("Session token obtained")


session = requests.Session()
session.verify = False

transport = Transport(session=session)

client = Client(
    wsdl=wsdl,
    transport=transport
)

# --------------------------------
# 3. Call GetReports
# --------------------------------

result = client.service.GetReports(
    sessionToken=session_token
)

# print(result)

output_path = f"C:\\Users\\miw\\OneDrive - Great Southern Bank\\Documents\\py3\\DataProgram\\output\\output.xml"
with open(output_path, "w", encoding="utf-8") as f:
    f.write(result)

# client = Client(
#     wsdl=wsdl,
#     transport=transport
# )

result2=client.service.SearchRecordsByReport(
    sessionToken=session_token,
    reportIdOrGuid="4f4d4d68-0caf-4c94-b07a-65156c9c594a",
    pageNumber=20
)

print(result2)

output_path = f"C:\\Users\\miw\\OneDrive - Great Southern Bank\\Documents\\py3\\DataProgram\\output\\output2.xml"
with open(output_path, "w", encoding="utf-8") as f:
    f.write(result2)
