#!/usr/bin/env python3

import subprocess
import re
import gspread
from oauth2client.service_account import ServiceAccountCredentials
import os

# Define the paths to the config file and credentials file
CONFIG_FILE_PATH = "~/scripts/qnode_rewards_to_gsheet.config"
AUTH_FILE_PATH = "~/scripts/quilibrium_gsheet_auth.json"

# Expand the paths
CONFIG_FILE_PATH = os.path.expanduser(CONFIG_FILE_PATH)
AUTH_FILE_PATH = os.path.expanduser(AUTH_FILE_PATH)

# Function to read configuration from the config file
def read_config(config_file):
    config = {}
    with open(config_file, 'r') as f:
        for line in f:
            key, value = line.strip().split('=')
            config[key.strip()] = value.strip()
    return config

# Google Sheet settings
config = read_config(CONFIG_FILE_PATH)
SHEET_NAME = config.get('SHEET_NAME', 'Quilibrium nodes')
SHEET_REWARDS_TAB_NAME = config.get('SHEET_REWARDS_TAB_NAME', 'Rewards')
SHEET_INCREMENT_TAB_NAME = config.get('SHEET_INCREMENT_TAB_NAME', 'Increment')
SHEET_TIME_TAKEN_TAB_NAME = config.get('SHEET_TIME_TAKEN_TAB_NAME', 'Time taken')
START_COLUMN = config.get('START_COLUMN', 'B')

def get_balance(command):
    try:
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            shell=True
        )
        stdout, _ = process.communicate()
        output = stdout.decode('utf-8')
        match = re.search(r'Unclaimed balance:\s*([\d.]+)', output)
        if match:
            return float(match.group(1))
    except Exception as e:
        print("Error occurred while fetching balance:", e)
    return None

def get_increment():
    command = "sudo journalctl -u ceremonyclient.service --no-hostname -o cat | grep \"\\\"msg\\\":\\\"completed duration proof\\\"\" | tail -n 1 | jq -r \".increment\""
    try:
        result = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return int(result.stdout.strip())
    except subprocess.CalledProcessError as e:
        print(f"Error occurred while fetching increment: {e}")
        return None

def get_time_taken():
    command = "sudo journalctl -u ceremonyclient.service --no-hostname -o cat | grep \"\\\"msg\\\":\\\"completed duration proof\\\"\" | tail -n 1 | jq -r \".time_taken\""
    try:
        result = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return round(float(result.stdout.strip()), 2)
    except subprocess.CalledProcessError as e:
        print(f"Error occurred while fetching time taken: {e}")
        return None

def find_next_empty_row(sheet, column):
    values_list = sheet.col_values(gspread.utils.a1_to_rowcol(column + '1')[1])
    return len(values_list) + 1

def update_google_sheet(value, sheet_tab_name, column):
    try:
        scope = ["https://spreadsheets.google.com/feeds", "https://www.googleapis.com/auth/drive"]
        creds = ServiceAccountCredentials.from_json_keyfile_name(AUTH_FILE_PATH, scope)
        client = gspread.authorize(creds)
        sheet = client.open(SHEET_NAME).worksheet(sheet_tab_name)

        empty_row = find_next_empty_row(sheet, column)
        cell = f"{column}{empty_row}"
        sheet.update_acell(cell, value)
        print(f"Value updated successfully: {value} at {cell} in {sheet_tab_name}")

    except gspread.exceptions.APIError as e:
        print(f"API Error occurred while updating Google Sheet ({sheet_tab_name}):", e)
        print("Response status code:", e.response.status_code)
        print("Response content:", e.response.content)
    except Exception as e:
        print(f"Error occurred while updating Google Sheet ({sheet_tab_name}):", e)

if __name__ == "__main__":
    config = read_config(CONFIG_FILE_PATH)
    
    # Get balance
    command = f"cd ~/ceremonyclient/node && ./{config['NODE_BINARY']} -balance"
    balance = get_balance(command)
    if balance is not None:
        update_google_sheet(balance, SHEET_REWARDS_TAB_NAME, START_COLUMN)

    # Get increment
    increment = get_increment()
    if increment is not None:
        update_google_sheet(increment, SHEET_INCREMENT_TAB_NAME, START_COLUMN)

    # Get time taken
    time_taken = get_time_taken()
    if time_taken is not None:
        update_google_sheet(time_taken, SHEET_TIME_TAKEN_TAB_NAME, START_COLUMN)