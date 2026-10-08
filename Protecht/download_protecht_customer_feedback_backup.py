from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import (StaleElementReferenceException, JavascriptException)
from selenium.webdriver.common.action_chains import ActionChains
import time



from datetime import datetime, date, timedelta

print(f"Run date : {datetime.now().strftime("%B %d, %Y")}")

#Protecht URL
url = "https://erm.protecht.com.au/cua/worms/client/app/widget.html?tablename=table_1050760&appId=1&widget=IncidentEntryPage"


options = webdriver.ChromeOptions()
options.add_argument("--log-level=3")
options.add_argument("--start-maximized")
options.add_experimental_option("detach", True)


driver = webdriver.Chrome(options = options)
driver.maximize_window()
driver.get(url)

driver.execute_script("""
    document.oncontextmenu = null;

    if (document.body) {
        document.body.oncontextmenu = null;
        }

    document.addEventListener(
    'contextmenu',
    function(e) {
    e.stopImmediatePropagation();
    },
    true);
    """)

driver.switch_to.default_content()

register = None

for i in range(120):       # try up to 120 seconds
    register = driver.execute_script("""
        return document.getElementById('menu-item-APP_INCIDENTS');
    """)

    if register:
        print(f"Register found after {i + 1} seconds")
        break

    print(f"Waiting... {i + 1}")
    time.sleep(1)

if register:
    driver.execute_script("""
        arguments[0].scrollIntoView({
            block: 'center',
            inline: 'center'
        });
    """, register)

    time.sleep(1)

    ActionChains(driver) \
        .move_to_element(register) \
        .pause(3) \
        .click() \
        .perform()

    print("Register clicked")
else:
    print("Register not found after 120 seconds")


## Review

def wait_query_selector(js, timeout=120):

    for i in range(timeout):

        element = driver.execute_script(js)

        if element:
            print(f"Found after {i + 1} seconds")
            return element

        print(f"Waiting... {i + 1}")
        time.sleep(1)

    return None

review_link = wait_query_selector("""
    const span =
        document.querySelector('#menu-item-APP_REVIEW_INCIDENTS');

    return span ? span.closest('a') : null;
""")

if review_link:
    driver.execute_script("arguments[0].click();", review_link)
    print("Review clicked")


customer_feedback = wait_query_selector("""
    const spans =
        document.querySelectorAll('span');

    for (const span of spans) {
        if (span.textContent.trim() === 'Customer Feedback') {
            return span.closest('div');
        }
    }

    return null;
""")

if customer_feedback:
    driver.execute_script("""
        arguments[0].scrollIntoView({block:'center'});
        arguments[0].click();
    """, customer_feedback)
    print("Customer feedback clicked")


driver.switch_to.default_content()

arrow = None

for i in range(120):

    arrow = driver.execute_script("""
        const view = document.querySelector(
            "[id$='-buttonBar-View']"
        );

        if (!view)
            return null;

        return view.querySelector(".split-arrow");
    """)

    if arrow:
        print("View arrow found")
        break

    time.sleep(1)

if arrow:
    ActionChains(driver) \
        .move_to_element(arrow) \
        .pause(3) \
        .click() \
        .perform()

    print("Physical View arrow clicked")
else:
    print("View arrow not found")

time.sleep(1)


show_all = None

for i in range(120):
    try:
        show_all = driver.execute_script("""
            return [...document.querySelectorAll('span')]
                .find(x => x.textContent.trim() === 'Show all') || null;
        """)

        if show_all:
            print(f"Show all found in {i + 1} seconds")
            break

    except Exception:
        pass

    print(f"Waiting for Show all... {i + 1}")
    time.sleep(1)

if show_all:
    driver.execute_script("""
        arguments[0].scrollIntoView({block:'center'});
        arguments[0].click();
    """, show_all)

    print("Show all clicked")
else:
    print("Show all not found")


export_button = wait_query_selector("""
    return [...document.querySelectorAll('div')]
                    .find(x => x.textContent.trim() === 'Export') || null;
            """)

if export_button:
    ActionChains(driver) \
            .move_to_element(export_button) \
            .pause(3) \
            .click() \
            .perform()
    print("Physical export button clicked")
else:
    print("export button not found")

#################################################

export_filtered = wait_query_selector("""
        return document.querySelector('i.fa-filter');
""")

if export_filtered:
     ActionChains(driver) \
            .move_to_element(export_filtered) \
            .pause(3) \
            .click() \
            .perform()
     print("Physical export filtered clicked")
else:
     print("export filtered not found")


print(f"Data Export")

ok_button = None

for i in range(120):

    ok_button = driver.execute_script("""
        const divs = document.querySelectorAll('div');

        for (const div of divs) {
            if (div.textContent.trim() === 'OK') {
                return div;
            }
        }

        return null;
    """)

    if ok_button:
        print(f"OK button found in {i + 1} seconds")
        break

    print(f"Waiting for OK... {i + 1}")
    time.sleep(1)

if ok_button:
    # print(ok_button.get_attribute("outerHTML"))

     ActionChains(driver) \
        .move_to_element(ok_button) \
        .pause(3) \
        .click() \
        .perform()

     print("Physical OK click performed")
else:
    print("OK not found")

    finish_download_button = None

for i in range(2400):

    finish_download_button = driver.execute_script("""
        const divs = document.querySelectorAll('div');

        for (const div of divs) {
            if (div.textContent.trim() === 'OK') {
                return div;
            }
        }

        return null;
    """)

    if finish_download_button:
        #print(f"Finish Download button found in {i + 1} seconds")
        break

    print(f"Waiting for Finish Download OK... {i + 1}")
    time.sleep(1)

if finish_download_button:
    # print(ok_button.get_attribute("outerHTML"))

     ActionChains(driver) \
        .move_to_element(finish_download_button) \
        .pause(5) \
        .click() \
        .perform()

     print("Physical Finish Download OK click performed")
else:
    print("Finish Download OK not found")



# wait = WebDriverWait(driver, 30)

# driver.quit()

# print(f"Browser closed.")


