import requests

import urllib3

from zeep import Client
from zeep.transports import Transport

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

wsdl = "https://gsb-test.archerirm.com.au/ws/search.asmx?WSDL"
#wsdl = "https://gsb-test.archerirm.com.au/ws/record.asmx?WSDL"

session = requests.Session()
session.verify = False

transport = Transport(session = session)

client = Client(wsdl=wsdl, transport=transport)


keywords = ["search", "record", "content", "report"]
for service in client.wsdl.services.values():
    for port in service.ports.values():
        # operations = port.binding._operations
        print("Port:", port.name)
        endpoint= port.binding_options["address"]

        for method_name, operation in port.binding._operations.items():
            print("+")
            print(method_name)
            print("endpoint :", endpoint)
            print("Soup Action :", operation.soapaction)
            print("INPUT", operation.input.signature())
            print("OUTPUT", operation.output.signature())



