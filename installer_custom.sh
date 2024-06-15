#!/bin/bash

echo ""
echo "This script will create an automation to populate your GSheet with QUIL hourly rewards for each node"
echo "This is a custom version and will not work for you unless you modify it"
echo ""
sleep 1


echo "Grabbing the script..."

sleep 1

echo "Changing permissions for the script..."
chmod +x ~/scripts/qnode_rewards_to_gsheet.py || { echo "❌ Failed to change permissions for the script."; exit 1; }
sleep 1

# Ask user for start column letter
read -p "Enter the start column letter to populate (e.g., A, B, C...): " START_COLUMN

# Create .config file
~/scripts/qnode_rewards_to_gsheet.config

with these contents
SHEET_NAME=Quilibrium nodes
SHEET_TAB_NAME=Rewards
START_COLUMN=$START_COLUMN
START_ROW=4

chmod +x ~/scripts/qnode_rewards_to_gsheet.config


sleep 1

echo "Running the script for testing..."
python3 ~/scripts/qnode_rewards_to_gsheet.py || { echo "❌ Script test run failed."; exit 1; }

echo "✅ Script setup and test run completed successfully."
