from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import (StaleElementReferenceException, JavascriptException)

import random

from datetime import datetime, date, timedelta

print(f"Today's date : {datetime.now().strftime("%B %d, %Y")}")

booking_date = (date.today() + timedelta(days = 14))

url = "https://login.clicktime.com"

user_id = "margaret.woon@cua.com.au"

pwd = "M0nday262728"

options = webdriver.ChromeOptions()
options.add_argument("--log-level=3")
options.add_argument("--start-maximized")
options.add_experimental_option("detach", True)


driver = webdriver.Chrome(options = options)
driver.maximize_window()
driver.get(url)


wait = WebDriverWait(driver, 30)

email_box = wait.until(EC.element_to_be_clickable((By.ID, "email")))

email_box.clear()
email_box.send_keys({user_id})

pwdbox = wait.until(EC.element_to_be_clickable((By.ID, "password")))

pwdbox.clear()
pwdbox.send_keys({pwd})

login_btn = wait.until(EC.element_to_be_clickable((By.ID, "loginbutton")))
login_btn.click()

print(f"Login submitted....")

wait = WebDriverWait(driver, 60)

project_row = wait.until(EC.presence_of_element_located((By.XPATH,"//tr[.//*[normalize-space()='5510 Enterprise Dat & Analytics']]"))
)

first_row_boxes = [
    box for box in project_row.find_elements(By.CSS_SELECTOR,"input.k-input-inner") if box.is_displayed() and box.is_enabled()
]

for box in first_row_boxes:   
    box.click()
    box.send_keys(Keys.CONTROL, "a")
    box.send_keys("7.5")
    box.send_keys(Keys.TAB)

print(f"Hours updated....")

wait = WebDriverWait(driver, 60)

submit_button = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[.//span[normalize-space()='Submit for Approval']]")))

submit_button.click()

wait = WebDriverWait(driver, 30)

# save_button = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[.//span[normalize-space()='Save']]")))

# save_button.click()

cc_email = wait.until(EC.element_to_be_clickable((By.ID, 'cc')))
cc_email.send_keys("margaret.woon@gsb.com.au")

#cc_email.send_keys("ENTER")

wait = WebDriverWait(driver, 30)
confirm_submission_button = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[.//span[normalize-space()='Confirm Submission']]")))

confirm_submission_button.click()

wait = WebDriverWait(driver, 60)

driver.quit()

print(f"Browser closed.")

