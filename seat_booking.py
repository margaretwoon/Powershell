from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import (StaleElementReferenceException, JavascriptException)
import win32com.client
import random
import os
import getpass

from datetime import datetime, date, timedelta

print(f"Today's date : {datetime.now().strftime("%B %d, %Y")}")

booking_date = (date.today() + timedelta(days = 14))

seat_choices = ["W 24.05", "W 24.08", "W 24.161", "W 24.162", "W 24.165", "W 24.169", "W 24.170", "W 24.177"]

booking_seat = random.choice(seat_choices)

url = "https://app14.cloud.appspace.com/signin/#/login?ReturnUrl=%2Fconsole%2F%23%21%2Fbrowse%2Fplaces%2Fworkspaces%3Fbuildingid%3Dff38e4a1-fc09-419d-9ebc-d4a64910911a%26start%3D2026-02-13T06%3A00%3A00.000Z%26duration%3D600&username=margaret.woon%40gsb.com.au"

username = getpass.getuser()
print(f"Logged-in user : {username}")

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
        return f"Could not retreive email : {e}"


print("Logged-in Email:", get_window_ad_email())

options = webdriver.ChromeOptions()
options.add_argument("--log-level=3")
options.add_argument("--start-maximized")
options.add_experimental_option("detach", True)


driver = webdriver.Chrome(options = options)
driver.maximize_window()
driver.get(url)


wait = WebDriverWait(driver, 30)
continue_btn = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[normalize-space()='Continue']")))

continue_btn.click()

# response page

wait = WebDriverWait(driver, 30)
continue_btn = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[normalize-space()='Continue']")))

continue_btn.click()

wait = WebDriverWait(driver, 100)

date_box = wait.until(EC.element_to_be_clickable((By.XPATH, "//input[@placeholder ='mm dd, yyyy']")))
date_box.click()

print(f"Booking_date {booking_date}")

wait.until(EC.visibility_of_element_located((By.CLASS_NAME, "react-calendar")))

target_day = str(booking_date.day)
if booking_date.month != date.today().month:
    next_arrow = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[contains(@class,'react-calendar__navigation__arrow react-calendar__navigation__next-button')]")))
    next_arrow.click()

day = wait.until(EC.element_to_be_clickable((By.XPATH, f"//button[not(contains(@class, 'neighboringMonth')) and normalize-space() = '{target_day}']")))
day.click()

print(f"Selected bookinge date....")

time_box_locator = (By.XPATH, "//*[normalize-space()='Time']/following::input[@role='combobox'][1]")

time_box = wait.until(EC.element_to_be_clickable(time_box_locator))


time_box.click()

wait.until(lambda d: d.find_element(*time_box_locator).get_attribute("aria-expanded") =="true")

time_box = driver.find_element(*time_box_locator)

listbox_id = time_box.get_attribute("aria-controls")

print(f"Clicked time....")

time_option = wait.until(EC.element_to_be_clickable((By.XPATH, f"//*[@id='{listbox_id}']//button[@role='option' and @id='8:00AM']")))


driver.execute_script("arguments[0].scrollIntoView({block: 'center'});", time_option)

driver.execute_script("arguments[0].click();", time_option)
#time_option.click()

print(f"Selected time....")

textbox = wait.until(EC.visibility_of_element_located((By.XPATH, "//input[@placeholder='Search workspaces']")))

textbox.clear()
textbox.send_keys({booking_seat})
print(f"Setup workspace....")

workspace = wait.until(EC.element_to_be_clickable((By.XPATH, f"//div[@class ='name' and normalize-space(.)='{booking_seat}']")))

workspace.click()
print(f"Clicked search workspace....")


reserve_button = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[normalize-space() = 'Reserve']")))

reserve_button.click()
print(f"Clicked Reserve button....")

confirm_locator = (By.XPATH, "//button[normalize-space() = 'CONFIRM']" )

def find_and_click_confirm(driver):
    try:
        buttons = driver.find_elements(*confirm_locator)

        for button in buttons:
            try:
                if button.is_displayed() and button.is_enabled():
                    driver.execute_script("arguments[0].click();", button)
                    return True
            except StaleElementReferenceException:
                continue
        return False
    except (StaleElementReferenceException, JavascriptException):
        return False


WebDriverWait(driver, 30, poll_frequency = 0.2, ignored_exceptions=(StaleElementReferenceException,)).until(find_and_click_confirm)

print(f"Clicked CONFIRM button....")

wait = WebDriverWait(driver, 30)

driver.quit()

print(f"Browser closed.")

