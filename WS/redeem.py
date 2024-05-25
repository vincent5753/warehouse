import argparse
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
import time

# python3 this.py -u=93437634 -c=g3r7H2
description = "你應該要告訴我兌換碼和你要幫誰換"
parser = argparse.ArgumentParser(description=description)
parser.add_argument('--user', '-u', type=str, required=True,  help='你沒告訴我要幫誰換')
parser.add_argument('--code', '-c', type=str, required=True, help='你沒給我兌換碼')
args = parser.parse_args()

#print("User: " + args.user)
#print("Redeem Code: " + args.code)

url="https://wos-giftcode.centurygame.com/"

options = Options()
#options.add_experimental_option("detach", True)

# 操作 Chrome
driver = webdriver.Chrome(options=options)

# 開啟網頁
driver.get(url)
time.sleep(3)

# 尋找角色ID輸入匡
uidinput = driver.find_element("xpath", "/html/body/div/div/div/div[3]/div[2]/div[1]/div[1]/div[1]/input")
# 輸入角色ID
uidinput.send_keys(args.user)
# 尋找並點擊登入
uidsendbutton = driver.find_element("xpath", "/html/body/div/div/div/div[3]/div[2]/div[1]/div[1]/div[2]")
uidsendbutton.click()
time.sleep(3)

# 尋找並輸入兌換碼輸入匡
redeeminput = driver.find_element("xpath", "/html/body/div/div/div/div[3]/div[2]/div[2]/div[1]/input")
redeeminput.send_keys(args.code)

# 尋找並點擊兌換按鈕
redeembutton = driver.find_element("xpath", "/html/body/div/div/div/div[3]/div[2]/div[3]")
redeembutton.click()
# 關掉
time.sleep(3)
driver.close
