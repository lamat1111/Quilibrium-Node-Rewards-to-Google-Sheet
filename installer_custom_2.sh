#!/bin/bash

NODE_BINARY="node-1.4.21-linux-amd64"

echo ""
echo "This script will create an automation to populate your GSheet with QUIL hourly rewards for each node."
echo "This is a custom version and will not work for you unless you modify it."
echo ""
sleep 1

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Python 3 and pip3 are installed
if ! command_exists python3 || ! command_exists pip3; then
    echo "Python 3 and/or pip3 are not installed. Installing them..."
    
    # Update package lists and install Python 3 and pip3
    sudo apt-get update > /dev/null
    sudo apt-get install -y python3 python3-pip > /dev/null || { echo "❌ Failed to install Python 3 and pip3."; exit 1; }
    sleep 1
    
    # Check if installation was successful
    if ! command_exists python3 || ! command_exists pip3; then
        echo "❌ Error: Python 3 and/or pip3 installation failed. Please install them manually and re-run this script."
        exit 1
    else
        echo "✅ Python 3 and pip3 installed successfully."
    fi
fi

echo "⚙️ Installing required Python packages..."

# Install required Python packages
pip3 install gspread oauth2client > /dev/null || { echo "❌ Failed to install required Python packages."; exit 1; }
sleep 1

# Check if installation was successful
if ! pip3 show gspread >/dev/null || ! pip3 show oauth2client >/dev/null; then
    echo "❌ Error: Failed to install required Python packages. Please check your internet connection and try again."
    exit 1
else
    echo "✅ Required Python packages installed successfully."
fi

# Ask user for start column letter
read -p "Enter the start column letter to populate (e.g., A, B, C...): " START_COLUMN
#convert value to uppercase
START_COLUMN=$(echo "$START_COLUMN" | tr '[:lower:]' '[:upper:]')

# Download the script from GitHub
echo "Grabbing the script..."
wget -O ~/scripts/qnode_rewards_to_gsheet.py https://github.com/lamat1111/Quilibrium-Node-Rewards-to-Google-Sheet/raw/main/qnode_rewards_to_gsheet_custom_2.py

# Ensure script is executable
echo "Changing permissions for the script..."
chmod +x ~/scripts/qnode_rewards_to_gsheet.py 
sleep 1

# Remove existing config file if it exists
rm -f ~/scripts/qnode_rewards_to_gsheet.config

# Create .config file
echo "Creating configuration file..."
cat <<EOF > ~/scripts/qnode_rewards_to_gsheet.config
SHEET_NAME=Quilibrium nodes
SHEET_REWARDS_TAB_NAME=Rewards
SHEET_INCREMENT_TAB_NAME=Increment
SHEET_TIME-TAKEN_TAB_NAME=Time taken
START_COLUMN=$START_COLUMN
NODE_BINARY=$NODE_BINARY
EOF

# Ensure config file is executable (not necessary for config files, but keeping for consistency)
chmod +x ~/scripts/qnode_rewards_to_gsheet.config

# Cron command to execute
CRON_COMMAND="/usr/bin/python3 /root/scripts/qnode_rewards_to_gsheet.py"

sleep 1

# Check if a cron job containing the command exists
EXISTING_CRON_JOB=$(crontab -l | grep -F "$CRON_COMMAND")

# If it exists, delete the existing cron job
if [ -n "$EXISTING_CRON_JOB" ]; then
    echo "⚙️ Deleting existing cron job..."
    (crontab -l | grep -vF "$CRON_COMMAND") | crontab - || { echo "❌ Failed to delete existing cron job."; exit 1; }
    echo "✅ Existing cron job deleted successfully."
fi

# Add the new cron job
echo "⚙️ Adding the new cron job..."
(crontab -l ; echo "0 0 * * * $CRON_COMMAND") | crontab - || { echo "❌ Failed to add new cron job."; exit 1; }
echo "✅ New cron job added successfully:"
echo "0 0 * * * $CRON_COMMAND"

# Confirmation
echo
read -p "✅ Setup completed successfully. Do you want to run a test of the script now? (y/n): " RUN_TEST
if [[ $RUN_TEST =~ ^[Yy](es)?$ ]]; then
    echo "⚙️ Running the script for testing..."
    python3 ~/scripts/qnode_rewards_to_gsheet.py || { echo "❌ Script test run failed."; exit 1; }
    echo "✅ Script test run completed successfully."
else
    echo "✅ Setup completed. You can manually run the script or wait for the cron job to execute."
fi

echo "✅ Script setup completed successfully."