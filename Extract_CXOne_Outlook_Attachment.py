""" This script search for unread email from noreply@incontact.com and download the attachment and tag the email as Read
"""

import win32com.client
import os
from datetime import datetime

print(f"Today's date : {datetime.now().strftime("%B %d, %Y")}")

save_folder = r'S:\\Data Transfer\\databricks\\cxone\\prod\\in\\'
# save_folder = r'C:\\Users\\miw\\Downloads\\'

def get_window_ad_email():
    try:
        obj_net = win32com.client.Dispatch("WScript.Network")
        username = obj_net.UserName
        domain = obj_net.UserDomain

        ad_sys_info = win32com.client.Dispatch("ADSystemInfo")
        current_user_dn = ad_sys_info.UserName

        user_obj = win32com.client.GetObject(f"LDAP://{current_user_dn}")

        return user_obj.EmailAddress

    except Exception as e:
        return f"Could not retreive email address : {e}"


def get_sender_email(message):
    try:
        if message.SenderEmailType == "EX":

            sender = message.Sender
            print(f"sender {sender}")

            exchange_user = sender.GetExchaneUser()

            if exchange_user:
                return exchange_user.PrimarySmtpAddress

        return message.SenderEmailAddress
    except Exception as e:
        print(f"Error getter sender: {e}")
        return None

print("Logged-in Email:", get_window_ad_email())

outlook = win32com.client.Dispatch("Outlook.Application").getNamespace("MAPI")

# for i in range(1, outlook.Folders.Count + 1):
#     mailbox = outlook.Folders.Item(i)
#     print(f"Mailbox Name {mailbox.Name}")
#     for j in range(1, mailbox.Folders.Count + 1):
#         f = mailbox.Folders.Item(j)
#         print(f"Mailbox Item {f.Name}")

mailbox = outlook.Folders.Item(get_window_ad_email())

target_inbox_folder = mailbox.Folders.Item("CXOne")

messages = target_inbox_folder.items

target_sender = 'noreply@incontact.com'

for message in messages:
    try:
        sender_email = get_sender_email(message)

        print(f"sender_email {sender_email}")

        if sender_email and sender_email.lower() == target_sender.lower() and message.Unread:

            print("Found Unread email:", message.Subject)
            print("From sender", message.SenderName)
            print("From subject", message.Subject)
            print("Number of Attachments ", message.Attachments.Count)

            for i in range(1, message.Attachments.Count + 1):
                attachment = message.Attachments.Item(i)

                save_path = os.path.join(save_folder, attachment.FileName)

                print(f"save_path {save_path}")

                attachment.SaveAsFile(save_path)
        
        # mark the email as Read
        message.Unread = False
        message.Save()
    except Exception as e:
        print(f"Error : {e}")

datetime_now = datetime.now().strftime("%d/%m/%Y, %H:%M:%S")
                        
print(f"Job Completed at {datetime_now}\n")