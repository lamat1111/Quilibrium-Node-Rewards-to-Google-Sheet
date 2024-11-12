#!/usr/bin/env python3

import subprocess
import re
import gspread
from oauth2client.service_account import ServiceAccountCredentials
import os
import sys
import time

# Define the paths to the config file and credentials file
CONFIG_FILE_PATH = os.path.expanduser("~/scripts/qnode_rewards_to_gsheet_2.config")
AUTH_FILE_PATH = os.path.expanduser("~/scripts/quilibrium_gsheet_auth.json")

def read_config(config_file):
    """Read and validate configuration from file."""
    config = {}
    try:
        with open(config_file, 'r') as f:
            for line in f:
                if '=' in line and not line.strip().startswith('#'):
                    key, value = line.strip().split('=', 1)
                    config[key.strip()] = value.strip()
        return config
    except Exception as e:
        print(f"Error reading config: {e}")
        sys.exit(1)

# Google Sheet settings from config
config = read_config(CONFIG_FILE_PATH)

# Sheet configuration
SHEET_NAME = config.get('SHEET_NAME')
SHEET_REWARDS_TAB_NAME = config.get('SHEET_REWARDS_TAB_NAME')
SHEET_RING_TAB_NAME = config.get('SHEET_RING_TAB_NAME')
SHEET_SENIORITY_TAB_NAME = config.get('SHEET_SENIORITY_TAB_NAME')
SHEET_TIME_TAKEN_TAB_NAME = config.get('SHEET_TIME_TAKEN_TAB_NAME')

# Sheet parameters
START_COLUMN = config.get('START_COLUMN')
START_ROW = max(2, int(config.get('START_ROW', '2')))

# Time tracking configuration
TRACK_TIME = config.get('TRACK_TIME', 'false').lower() == 'true'

# Node command
NODE_INFO_CMD = f"cd ~/ceremonyclient/node && ./{config['NODE_BINARY']} -node-info"

def get_node_output():
    try:
        print("Getting node info...")
        result = subprocess.run(NODE_INFO_CMD, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        direct_output = result.stdout
        
        # If we got direct output with the values we need, use it
        if "Prover Ring:" in direct_output and "Seniority:" in direct_output and "Owned balance:" in direct_output:
            return direct_output
            
        # Otherwise, try journalctl method
        print("Using journalctl method...")
        time.sleep(5)
        journal_result = subprocess.run(
            "journalctl -u ceremonyclient.service --no-hostname -o cat | tail -n 50",
            shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        return journal_result.stdout
    except Exception as e:
        print(f"Error getting node output: {e}")
        return None

def get_time_taken():
    try:
        command = "sudo journalctl -u ceremonyclient.service --no-hostname -o cat | grep \"\\\"msg\\\":\\\"completed duration proof\\\"\" | tail -n 1 | jq -r \".time_taken\""
        result = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return round(float(result.stdout.strip()), 2) if result.stdout.strip() else None
    except Exception as e:
        print(f"Error getting time taken: {e}")
        return None

def update_google_sheet(value, sheet_tab_name):
    try:
        scope = ["https://spreadsheets.google.com/feeds", "https://www.googleapis.com/auth/drive"]
        creds = ServiceAccountCredentials.from_json_keyfile_name(AUTH_FILE_PATH, scope)
        client = gspread.authorize(creds)
        sheet = client.open(SHEET_NAME).worksheet(sheet_tab_name)
        
        values_list = sheet.col_values(gspread.utils.a1_to_rowcol(START_COLUMN + '1')[1])
        next_row = max(len(values_list) + 1, START_ROW)
        
        cell = f"{START_COLUMN}{next_row}"
        sheet.update_acell(cell, value)
        print(f"Updated {sheet_tab_name} with value: {value}")
        return True
    except Exception as e:
        print(f"Error updating {sheet_tab_name}: {e}")
        return False

def main():
    success = False
    
    # Get node info
    output = get_node_output()
    
    if output:
        # Try to update each value independently
        ring_match = re.search(r'Prover Ring:\s*(\d+)', output)
        if ring_match:
            ring = int(ring_match.group(1))
            if update_google_sheet(ring, SHEET_RING_TAB_NAME):
                success = True
        
        seniority_match = re.search(r'Seniority:\s*(\d+)', output)
        if seniority_match:
            seniority = int(seniority_match.group(1))
            if update_google_sheet(seniority, SHEET_SENIORITY_TAB_NAME):
                success = True
        
        balance_match = re.search(r'Owned balance:\s*([\d.]+)', output)
        if balance_match:
            balance = float(balance_match.group(1))
            if update_google_sheet(balance, SHEET_REWARDS_TAB_NAME):
                success = True
    
    # Get time taken if enabled
    if TRACK_TIME:
        time_taken = get_time_taken()
        if time_taken is not None:
            if update_google_sheet(time_taken, SHEET_TIME_TAKEN_TAB_NAME):
                success = True
    
    if success:
        print("Successfully updated Google Sheet")
    else:
        print("No values were successfully updated")
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())