#!/usr/bin/env python3

import subprocess
import re
import gspread
from oauth2client.service_account import ServiceAccountCredentials
import os
import logging

# Set up logging - only INFO and ERROR levels
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Define the paths and expand them
CONFIG_FILE_PATH = os.path.expanduser("~/scripts/qnode_rewards_to_gsheet.config")
AUTH_FILE_PATH = os.path.expanduser("~/scripts/quilibrium_gsheet_auth.json")

def read_config(config_file):
    try:
        if not os.path.exists(config_file):
            logging.error(f"Config file not found: {config_file}")
            raise FileNotFoundError(f"Config file not found: {config_file}")
            
        config = {}
        with open(config_file, 'r') as f:
            for line in f:
                key, value = line.strip().split('=')
                config[key.strip()] = value.strip()
        return config
    except Exception as e:
        logging.error(f"Error reading config: {str(e)}")
        raise

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
        stdout, stderr = process.communicate()
        output = stdout.decode('utf-8')
        
        match = re.search(r'Owned balance:\s*([\d.]+)', output)
        if match:
            return float(match.group(1))
        else:
            logging.error("Could not find balance in command output")
            return None
    except Exception as e:
        logging.error(f"Error getting balance: {str(e)}")
        return None

def find_next_empty_row(sheet, column, start_row):
    try:
        col_idx = gspread.utils.a1_to_rowcol(column + '1')[1]
        values_list = sheet.col_values(col_idx)
        values_list = values_list[start_row - 1:]

        for i, value in enumerate(values_list):
            if value == '':
                return i + start_row
        return len(values_list) + start_row
    except Exception as e:
        logging.error(f"Error finding empty row: {str(e)}")
        raise

def update_google_sheet(balance, column, row):
    try:
        if not os.path.exists(AUTH_FILE_PATH):
            logging.error(f"Auth file not found: {AUTH_FILE_PATH}")
            raise FileNotFoundError(f"Auth file not found: {AUTH_FILE_PATH}")

        scope = ["https://spreadsheets.google.com/feeds", "https://www.googleapis.com/auth/drive"]
        creds = ServiceAccountCredentials.from_json_keyfile_name(AUTH_FILE_PATH, scope)
        client = gspread.authorize(creds)
        sheet = client.open(SHEET_NAME).worksheet(SHEET_TAB_NAME)

        empty_row = find_next_empty_row(sheet, column, row)
        cell = f"{column}{empty_row}"
        sheet.update_acell(cell, balance)
        logging.info(f"Balance {balance} QUIL updated at {cell}")

    except gspread.exceptions.APIError as e:
        logging.error(f"Google Sheets API error: {str(e)}")
    except Exception as e:
        logging.error(f"Error updating sheet: {str(e)}")

if __name__ == "__main__":
    try:
        config = read_config(CONFIG_FILE_PATH)
        command = f"cd ~/ceremonyclient/node && ./{config['NODE_BINARY']} -balance"
        
        balance = get_balance(command)
        if balance is not None:
            update_google_sheet(balance, START_COLUMN, START_ROW)
        else:
            logging.error("Failed to get balance")
    except Exception as e:
        logging.error(f"Script failed: {str(e)}")