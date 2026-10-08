""" This script start outlook if it is not running, search for unread email from noreply@incontact.com and download the attachment and tag the email as Read
"""

import win32com.client
import os
from datetime import datetime, timedelta
import time
import subprocess

print(f"Today's date : {datetime.now().strftime("%B %d, %Y")}")

save_folder = r'S:\\Data Transfer\\databricks\\cxone\\prod\\in\\'
# save_folder = r'C:\\Users\\miw\\Downloads\\'

def get_window_ad_email():
    try:

        ad_sys_info = win32com.client.Dispatch("ADSystemInfo")
        current_user_dn = ad_sys_info.UserName

        user_obj = win32com.client.GetObject(f"LDAP://{current_user_dn}")

        return user_obj.EmailAddress

    except Exception as e:
        print(f"Could not retreive email address : {e}")
        return None


def get_sender_email(message):
    try:
        if message.SenderEmailType == "EX":

            sender = message.Sender
            print(f"sender {sender}")

            exchange_user = sender.GetExchangeUser()

            if exchange_user:
                return exchange_user.PrimarySmtpAddress

        return message.SenderEmailAddress
    except Exception as e:
        print(f"Error getting sender: {e}")
        return None


def connect_to_outlook():
    outlook_started_by_script = False

    try:
        outlook_app = win32com.client.GetActiveObject("Outlook.Application")

        print("Outlook is already running.")
    except Exception:
        subprocess.Popen([r"C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"])
        #subprocess.Popen([r"C:\Program Files\WindowsApps\Microsoft.OutlookForWindows_1.2026.818.100_x64__8wekyb3d8bbwe\olk.exe"])
        outlook_started_by_script = True

        time.sleep(10)

        outlook_app = win32com.client.Dispatch(
           "Outlook.Application"
       )

    namespace = outlook_app.GetNamespace("MAPI")

    # Wait until MAPI/mailbox is ready
    for attempt in range(500):

        try:
            inbox = namespace.GetDefaultFolder(6)

            # Force Outlook to access MAPI
            _ = inbox.Items.Count

            print("Outlook MAPI is ready.")

            return (
               outlook_app,
               namespace,
               outlook_started_by_script
            )

        except Exception as e:

            print(
               f"Waiting for Outlook/MAPI "
               f"({attempt + 1}/500)..."
            )

            time.sleep(10)

    raise RuntimeError(
       "Outlook started but MAPI did not become ready.")

logged_in_email = get_window_ad_email()
print("Logged-in Email:", logged_in_email)

if not logged_in_email:
    raise RuntimeError("Unable to determine logged-in email address")

outlook_app, outlook, outlook_started_by_script = (
   connect_to_outlook()
)
#outlook = win32com.client.Dispatch("Outlook.Application").getNamespace("MAPI")

for i in range(1, outlook.Folders.Count + 1):
    mailbox = outlook.Folders.Item(i)
    print(f"Mailbox Name {mailbox.Name}")
    for j in range(1, mailbox.Folders.Count + 1):
        f = mailbox.Folders.Item(j)
        print(f"Mailbox Item {f.Name}")

mailbox = outlook.Folders.Item(logged_in_email)

target_inbox_folder = mailbox.Folders.Item("CXOne")

messages = target_inbox_folder.Items
target_sender = 'noreply@incontact.com'


yesterday = datetime.now() - timedelta(days=1)
yesterday_date = yesterday.strftime("%d/%m/%Y %I:%M %p")

filter_string = f"[ReceivedTime] >= '{yesterday_date}'"

filtered_messages = messages.Restrict(filter_string)

print(f"Processing emails received since : {yesterday_date}")

print(f"Found {filtered_messages.count} emails to check.")


for message in filtered_messages:
    try:
        sender_email = get_sender_email(message)
        
        if not sender_email:
            continue

        if sender_email.lower() != target_sender.lower():
            continue

        print("Read status:", message.UnRead)
        print("Sender_email:", sender_email)
        print("From sender:", message.SenderName)
        print("From subject:", message.Subject)
        print("Number of Attachments:", message.Attachments.Count)
        print(f"Processing....")

        if message.Attachments.Count == 0:
            print("No attachment found in email")
            continue

        all_saved = True

        for i in range(1, message.Attachments.Count + 1):
            
            attachment = message.Attachments.Item(i)

            save_path = os.path.join(save_folder, attachment.FileName)

            print(f"Saving attachment to: {save_path}")

            try:
                attachment.SaveAsFile(save_path)
                print("Saved successfully")
            except Exception as e:
                print(f"Failed to save attachment: {e}")
                all_saved = False
        
    except Exception as e:
        print(f"Error : {e}")

datetime_now = datetime.now().strftime("%d/%m/%Y, %H:%M:%S")
                        
print(f"Job Completed at {datetime_now}\n")