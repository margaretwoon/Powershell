import os
import time
from datetime import datetime
import win32com.client



def wait_for_refresh_complete(workbook, timeout = 600, check_interval=2):

    start_time = time.time()
    while True:
        still_refreshing = False

        for connection in workbook.Connections:

            try:
                if connection.OLEDBCConnection.Refreshing:
                    print(f"Refreshing connection: {connection.Name}")
                    still_refreshing = True
            except Exception:
                pass

            try:
                if connection.ODBCCConnection.Refreshing:
                    print(f"Refreshing connection: {connection.Name}")
                    still_refreshing = True
            except Exception:
                pass

        for worksheet in workbook.Worksheets:
            try:
                for query_table in worksheet.QueryTables:
                    if query_table.Refreshing:
                        print(f"Refreshing query: {worksheet.Name}/{query_table.Name}")
                        still_refreshing = True
            except Exception:
                pass
        try:
            for table in worksheet.ListObject:
                try:
                    if table.QueryTable.Refreshing:
                        print(f"Refreshing table {worksheet.Name}/{table.Name}")
                        still_refreshing = True
                except Exception:
                    pass
        except Exception:
            pass

        if not still_refreshing:
            print("All connections have finished refreshing")
            break

        if time.time() - start_time > timeout:
            raise TimeoutError("Excel refreshed exceeded timeout")

        time.sleep(check_interval)

source_file = r"S:\Projects\Data Program\0. General Information\Data Sharing\jjh\AD_users.xlsx"
output_folder = r"S\Projects\Data Program\0. General Information\Data Sharing\jjh"

today = datetime.now().strftime("%Y%m%d")

base_name, extension =os.path.splitext(os.path.basename(source_file))

output_file= os.path.join(output_folder, f"{base_name}_{today}.{extension}")

print(f"output_file {output_file}")

excel = None

workbook = None

try:
    excel = win32com.client.DispatchEx("Excel.Application")
    excel.Visible = True
    excel.DisplayAlerts = True

    print("Opening workbook....")
    workbook = excel.Workbooks.Open(source_file)

    print("Starting refresh......")
    workbook.RefreshAll()

    excel.CalculateUntilAsyncQueriesDone()

    wait_for_refresh_complete(
        workbook,
        timeout = 600,
        check_interval = 2)

    print("Saving refreshed workbook...")
    workbook.SaveAs(output_file)

    print(f"Successfully created\n {output_file}")

finally:
    if workbook is not None:
        workbook.Close(SaveChanges = False)

    if excel is not None:
        excel.Quit()