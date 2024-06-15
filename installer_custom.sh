#!/bin/bash

echo ""
echo "This script will create an automation to populate your GSheet with QUIL hourly rewards for each node"
echo "Remember to upload your .json authentication file for this to work"
echo ""
sleep 3

echo "Installing Python 3 and pip3..."
sudo apt install -y python3 python3-pip || { echo "❌ Failed to install Python 3 and pip3."; exit 1; }
sleep 1

echo "Installing required Python packages..."
pip3 install gspread oauth2client || { echo "❌ Failed to install required Python packages."; exit 1; }
sleep 1

echo "Grabbing the script..."

sleep 1

echo "Changing permissions for the script..."
chmod +x ~/scripts/qnode_rewards_to_gsheet.py || { echo "❌ Failed to change permissions for the script."; exit 1; }
sleep 1

# Ask user for start column letter
read -p "Enter the start column letter to populate (e.g., A, B, C...): " START_COLUMN

# Update START_COLUMN in the script
sed -i "s/START_COLUMN = .*/START_COLUMN = \"$START_COLUMN\"/" ~/scripts/qnode_rewards_to_gsheet.py || { echo "❌ Failed to update the START_COLUMN in the script."; exit 1; }

# Function to handle errors
handle_error() {
    echo "❌ An error occurred while updating cron jobs."
    exit 1
}

# Cron command to execute
CRON_COMMAND="/usr/bin/python3 ~/scripts/qnode_rewards_to_gsheet.py"

# Check if a cron job containing the command exists
EXISTING_CRON_JOB=$(crontab -l | grep -F "$CRON_COMMAND")

# If it exists, delete the existing cron job
if [ -n "$EXISTING_CRON_JOB" ]; then
    echo "🔄 Deleting existing cron job..."
    (crontab -l | grep -vF "$CRON_COMMAND") | crontab - || handle_error
    echo "✅ Existing cron job deleted successfully."
fi

# Generate a random minute between 0 and 59
RANDOM_MINUTE=$(shuf -i 0-59 -n 1)

# New cron job with a random minute every hour
NEW_CRON_JOB="$RANDOM_MINUTE * * * * $CRON_COMMAND"

# Add the new cron job
echo "➕ Adding the new cron job..."
(crontab -l ; echo "$NEW_CRON_JOB") | crontab - || handle_error
echo "✅ New cron job added successfully:"
echo "$NEW_CRON_JOB"


sleep 1

echo "Running the script for testing..."
python3 ~/scripts/qnode_rewards_to_gsheet.py || { echo "❌ Script test run failed."; exit 1; }

echo "✅ Script setup and test run completed successfully."
