#!/bin/bash

NODE_BINARY="node-1.4.21-linux-amd64"

echo ""
echo "This script will create an automation to populate your GSheet with your node rewards, increment and time taken."
echo "This is a custom version and will not work for you unless you modify it."
echo ""
sleep 1

# Function to check if a command exists
command_exists () {
    command -v "$1" >/dev/null 2>&1
}

# Install Python 3, venv, and pip if not already installed
echo "Checking if Python, venv, and pip are installed..."
if ! command_exists python3 || ! command_exists python3-venv || ! command_exists pip3; then
    echo "Installing Python, venv, and pip..."
    sudo apt install -y python3 python3-venv python3-pip
else
    echo "Python, venv, and pip are already installed."
fi

# Check if the virtual environment already exists
VENV_DIR="myenv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating a virtual environment..."
    python3 -m venv $VENV_DIR
else
    echo "Virtual environment '$VENV_DIR' already exists."
fi

# Activate the virtual environment
echo "Activating the virtual environment..."
source $VENV_DIR/bin/activate

# Install required Python packages
echo "Installing required packages..."
pip install gspread oauth2client

echo "Setup complete. Virtual environment is active."
echo "To deactivate the virtual environment, run 'deactivate'"
echo "To activate this environment in the future, run 'source myenv/bin/activate' from this directory"

apt install jq -y

# Ask user for start column letter
read -p "Enter the start column letter to populate (e.g., A, B, C...): " START_COLUMN
#convert value to uppercase
START_COLUMN=$(echo "$START_COLUMN" | tr '[:lower:]' '[:upper:]')

# Ask user for start row number
read -p "Enter the start row number to populate (default: 2): " START_ROW
# Set default value if user doesn't provide input
START_ROW=${START_ROW:-2}

read -p "➡️  Enter the minute (0-59) when you want the cron job to run (default: random): " CRON_MINUTE
CRON_MINUTE=${CRON_MINUTE:-$(shuf -i 0-59 -n 1)}  # Set default to random minute if user doesn't provide input

# Download the script from GitHub
echo "Grabbing the script..."
wget -O ~/scripts/qnode_rewards_to_gsheet_2.py https://github.com/lamat1111/Quilibrium-Node-Rewards-to-Google-Sheet/raw/main/qnode_rewards_to_gsheet_custom_2.py

# Ensure script is executable
echo "Changing permissions for the script..."
chmod +x ~/scripts/qnode_rewards_to_gsheet_2.py 
sleep 1

# Remove existing config file if it exists
rm -f ~/scripts/qnode_rewards_to_gsheet_2.config

# Create .config file
echo "Creating configuration file..."
cat <<EOF > ~/scripts/qnode_rewards_to_gsheet_2.config
SHEET_NAME=Quilibrium nodes
SHEET_REWARDS_TAB_NAME=Rewards 2
SHEET_INCREMENT_TAB_NAME=Increment
SHEET_TIME_TAKEN_TAB_NAME=Time taken
START_COLUMN=$START_COLUMN
START_ROW=$START_ROW
NODE_BINARY=$NODE_BINARY
EOF

# Ensure config file is executable (not necessary for config files, but keeping for consistency)
chmod +x ~/scripts/qnode_rewards_to_gsheet_2.config

# Cron command to execute
CRON_COMMAND="/root/myenv/bin/python /root/scripts/qnode_rewards_to_gsheet_2.py"

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
(crontab -l ; echo "$CRON_MINUTE 1 * * * $CRON_COMMAND") | crontab - || { echo "❌ Failed to add new cron job."; exit 1; }
echo "✅ New cron job added successfully: runs at minute $CRON_MINUTE every day at 1 AM"
echo "$CRON_MINUTE 1 * * * $CRON_COMMAND"

# Confirmation
echo
read -p "✅ Setup completed successfully. Do you want to run a test of the script now? (y/n): " RUN_TEST
if [[ $RUN_TEST =~ ^[Yy](es)?$ ]]; then
    echo "⚙️ Running the script for testing..."
    python3 ~/scripts/qnode_rewards_to_gsheet_2.py || { echo "❌ Script test run failed."; exit 1; }
    echo "✅ Script test run completed successfully."
else
    echo "✅ Setup completed. You can manually run the script or wait for the cron job to execute."
fi

echo "✅ Script setup completed successfully."
