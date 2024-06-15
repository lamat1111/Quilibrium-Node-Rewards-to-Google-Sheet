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

# Read configuration from the config file
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

def get_balance(node_exec_path):
    try:
        command = f"{node_exec_path} -balance"
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

def get_node_executable(service_file_path):
    try:
        with open(service_file_path, 'r') as file:
            for line in file:
                if line.startswith("ExecStart="):
                    return line.strip().split('/')[-1].strip()
    except Exception as e:
        print("Error occurred while extracting node executable:", e)
    return None

def find_next_empty_row(sheet, column, start_row):
    # Get all values in the column from the start row to the end
    values_list = sheet.col_values(gspread.utils.a1_to_rowcol(column + '1')[1])
    values_list = values_list[start_row - 1:]  # Adjust for 0-based index

    # Find the first empty cell
    for i, value in enumerate(values_list):
        if value == '':
            return i + start_row

    # If no empty cell found, return the next row after the last filled cell
    return len(values_list) + start_row

def update_google_sheet(balance, column, row):
    try:
        scope = ["https://spreadsheets.google.com/feeds", "https://www.googleapis.com/auth/drive"]
        creds = ServiceAccountCredentials.from_json_keyfile_name(AUTH_FILE_PATH, scope)
        client = gspread.authorize(creds)
        sheet = client.open(SHEET_NAME).worksheet(SHEET_TAB_NAME)

        empty_row = find_next_empty_row(sheet, column, row)
        cell = f"{column}{empty_row}"

        # Update the cell with the new balance
        sheet.update_acell(cell, balance)
        print(f"Balance updated successfully: {balance} at {cell}")

    except gspread.exceptions.APIError as e:
        print("API Error occurred while updating Google Sheet:", e)
        print("Response status code:", e.response.status_code)
        print("Response content:", e.response.content)
    except Exception as e:
        print("Error occurred while updating Google Sheet:", e)

if __name__ == "__main__":
    service_file_path = "/lib/systemd/system/ceremonyclient.service"
    node_executable = get_node_executable(service_file_path)
    if node_executable is None:
        print("Node executable filename not found or error occurred.")
        exit(1)

    command = f"cd ~/ceremonyclient/node && ./{node_executable} -balance"
    balance = get_balance(command)
    if balance is not None:
        update_google_sheet(balance, START_COLUMN, START_ROW)
