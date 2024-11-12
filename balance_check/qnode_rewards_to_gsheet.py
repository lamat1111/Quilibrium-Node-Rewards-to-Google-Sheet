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
SHEET_TAB_NAME = config.get('SHEET_TAB_NAME', 'Rewards')
START_COLUMN = config.get('START_COLUMN', 'B')
START_ROW = int(config.get('START_ROW', 4))

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

def find_next_empty_row(sheet, column, start_row):
    # Find the first empty cell in the specified column and start row
    values_list = sheet.col_values(gspread.utils.a1_to_rowcol(column + '1')[1])
    values_list = values_list[start_row - 1:]  # Adjust for 0-based index

    for i, value in enumerate(values_list):
        if value == '':
            return i + start_row

    # If no empty cell found, return the next row after the last filled cell
    return len(values_list) + start_row

def update_google_sheet(balance, column, row):
    try:
        # Authenticate Google Sheets API
        scope = ["https://spreadsheets.google.com/feeds", "https://www.googleapis.com/auth/drive"]
        creds = ServiceAccountCredentials.from_json_keyfile_name(AUTH_FILE_PATH, scope)
        client = gspread.authorize(creds)
        sheet = client.open(SHEET_NAME).worksheet(SHEET_TAB_NAME)

        # Find the next empty row and update the balance
        empty_row = find_next_empty_row(sheet, column, row)
        cell = f"{column}{empty_row}"
        sheet.update_acell(cell, balance)
        print(f"Balance updated successfully: {balance} at {cell}")

    except gspread.exceptions.APIError as e:
        print("API Error occurred while updating Google Sheet:", e)
        print("Response status code:", e.response.status_code)
        print("Response content:", e.response.content)
    except Exception as e:
        print("Error occurred while updating Google Sheet:", e)

if __name__ == "__main__":
    # Load configuration from file
    config = read_config(CONFIG_FILE_PATH)
    
    # Construct command using NODE_VERSION, OS, and ARCH from config
    command = f"cd ~/ceremonyclient/node && ./{config['NODE_BINARY']} -balance"

    # Get balance from the command
    balance = get_balance(command)
    if balance is not None:
        update_google_sheet(balance, START_COLUMN, START_ROW)
