#!/bin/bash

echo
echo "This script will create an automation to populate your GSheet with QUIL hourly rewards for each node"
echo
echo "Remember to upload your .json authentication file for this to work"
echo "You have to create your Google Sheet and setup your authentication credentials before running this installer"
sleep 5

# User inputs
read -p "Enter the Google Sheet Doc name (e.g. Quilibrium Nodes): " GSHEET_DOC_NAME
echo
read -p "Enter the Google Sheet individual sheet/tab name (e.g. Rewards): " GSHEET_SHEET_NAME
echo
# Ask user for start column letter
read -p "Enter the start column letter to populate (e.g., A, B, C...): " START_COLUMN
echo
# Convert value to uppercase
START_COLUMN=$(echo "$START_COLUMN" | tr '[:lower:]' '[:upper:]')
read -p "Enter the row number you want to begin populating (e.g. 2): " START_ROW
echo

echo "Installing Python 3 and pip3..."
sudo apt-get update > /dev/null
sudo apt-get install -y python3 python3-pip > /dev/null || { echo "❌ Failed to install Python 3 and pip3."; exit 1; }
sleep 1

echo "Installing required Python packages..."
pip3 install gspread oauth2client > /dev/null || { echo "❌ Failed to install required Python packages."; exit 1; }
sleep 1

# Download the script from GitHub
echo "Grabbing the script..."
wget -q -O ~/scripts/qnode_rewards_to_gsheet.py https://github.com/lamat1111/Quilibrium-Node-Rewards-to-Google-Sheet/raw/main/qnode_rewards_to_gsheet.py

# Ensure script is executable
echo "Changing permissions for the script..."
chmod +x ~/scripts/qnode_rewards_to_gsheet.py 
sleep 1

# Create .config file
echo "Creating configuration file..."
cat <<EOF > ~/scripts/qnode_rewards_to_gsheet.config
SHEET_NAME=$GSHEET_DOC_NAME
SHEET_TAB_NAME=$GSHEET_SHEET_NAME
START_COLUMN=$START_COLUMN
START_ROW=$START_ROW
EOF

# Ensure config file is executable (not necessary for config files, but keeping for consistency)
chmod +x ~/scripts/qnode_rewards_to_gsheet.config

sleep 1

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


# Run the script for testing
echo "Running the script for testing..."
python3 ~/scripts/qnode_rewards_to_gsheet.py || { echo "❌ Script test run failed."; exit 1; }

echo "✅ Script setup and test run completed successfully."