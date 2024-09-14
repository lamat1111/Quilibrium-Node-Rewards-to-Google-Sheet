#!/bin/bash

cat << "EOF"

                  QQQQQQQQQ       1111111   
                QQ:::::::::QQ    1::::::1   
              QQ:::::::::::::QQ 1:::::::1   
             Q:::::::QQQ:::::::Q111:::::1   
             Q::::::O   Q::::::Q   1::::1   
             Q:::::O     Q:::::Q   1::::1   
             Q:::::O     Q:::::Q   1::::1   
             Q:::::O     Q:::::Q   1::::l   
             Q:::::O     Q:::::Q   1::::l   
             Q:::::O     Q:::::Q   1::::l   
             Q:::::O  QQQQ:::::Q   1::::l   
             Q::::::O Q::::::::Q   1::::l   
             Q:::::::QQ::::::::Q111::::::111
              QQ::::::::::::::Q 1::::::::::1
                QQ:::::::::::Q  1::::::::::1
                  QQQQQQQQ::::QQ111111111111
                          Q:::::Q           
                           QQQQQQ  QUILIBRIUM.ONE                                                                                                                                  


=======================================================================
               ✨ QNODE REWARDS TO GOOGLE SHEET ✨
=======================================================================
This script will create an automation to populate your Google Sheet
with QUIL hourly rewards for each node.

Remember to upload your .json authentication file for this to work.
You must create your Google Sheet and set up your authentication 
credentials before running this installer.

Detailed instructions:
https://github.com/lamat1111/Quilibrium-Node-Rewards-to-Google-Sheet


Made with 🔥 by LaMat - https://quilibrium.one
=======================================================================

Processing... ⏳

EOF

sleep 7

# Function to check if a command exists
command_exists () {
    command -v "$1" >/dev/null 2>&1
}

# Install Python 3, venv, and pip if not already installed
echo "Checking if Python, venv, and pip are installed..."
if ! command_exists python3 || ! command_exists python3-venv || ! command_exists pip3; then
    echo "Installing Python, venv, and pip..."
    sudo apt-get install -y python3 python3-venv python3-pip
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

#install JQ
echo "Installing JQ..."
sudo apt install jq -y

# User inputs
echo
read -p "➡️  Enter the Node Version (leave empty for default value '1.4.21'): " NODE_VERSION
NODE_VERSION=${NODE_VERSION:-"1.4.21"}  # Use default if empty
echo
read -p "➡️  Enter the Google Sheet Doc name (leave empty for default value 'Quilibrium nodes'): " GSHEET_DOC_NAME
GSHEET_DOC_NAME=${GSHEET_DOC_NAME:-"Quilibrium nodes"}  # Use default if empty
echo
read -p "➡️  Enter the Google Sheet individual sheet/tab name (leave empty for default value 'Rewards'): " GSHEET_SHEET_NAME
GSHEET_SHEET_NAME=${GSHEET_SHEET_NAME:-"Rewards"}  # Use default if empty
echo
# Ask user for start column letter
read -p "➡️  Enter the start column letter to populate (e.g., A, B, C...): " START_COLUMN
echo
# Convert value to uppercase
START_COLUMN=$(echo "$START_COLUMN" | tr '[:lower:]' '[:upper:]')
read -p "➡️  Enter the row number you want to begin populating (leave empty for default value '5'): " START_ROW
START_ROW=${START_ROW:-"5"}  # Use default if empty
echo

# Download the script from GitHub
echo "⚙️ Grabbing the script..."
wget -q -O ~/scripts/qnode_rewards_to_gsheet.py https://github.com/lamat1111/Quilibrium-Node-Rewards-to-Google-Sheet/raw/main/qnode_rewards_to_gsheet.py

# Ensure script is executable
echo "⚙️ Changing permissions for the script..."
chmod +x ~/scripts/qnode_rewards_to_gsheet.py 
sleep 1

# Determine the ExecStart line based on the architecture
ARCH=$(uname -m)
OS=$(uname -s)

# Determine the node binary name based on the architecture and OS
if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-amd64"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-amr64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-amr64"
    fi
fi

# Remove existing config file if it exists
rm -f ~/scripts/qnode_rewards_to_gsheet.config

# Create .config file
echo "⚙️ Creating configuration file..."
cat <<EOF > ~/scripts/qnode_rewards_to_gsheet.config
SHEET_NAME=$GSHEET_DOC_NAME
SHEET_TAB_NAME=$GSHEET_SHEET_NAME
START_COLUMN=$START_COLUMN
START_ROW=$START_ROW
NODE_BINARY=$NODE_BINARY
EOF

# Ensure config file is executable (not necessary for config files, but keeping for consistency)
chmod +x ~/scripts/qnode_rewards_to_gsheet.config

sleep 1

# Ask user for cron job frequency in hours
echo
read -p "➡️  Enter the frequency of the cron job in hours (default: 1 hour): " CRON_FREQUENCY_HOURS
echo
CRON_FREQUENCY_HOURS=${CRON_FREQUENCY_HOURS:-1}  # Default to 1 hour if user doesn't provide input

# Ask user for the cron job minute
echo "⚠️ IMPORTANT NOTE:"
echo "If you are running this script on several servers/nodes every hour, it is recommended"
echo "to set at least a different minute for each cron job (e.g., 1, 2, 3, 4,...)"
echo "Failing to do so may consume your Google Sheet read/write quota and cause the script to fail."
echo
read -p "➡️  Enter the minute (0-59) when you want the cron job to run (default: random): " CRON_MINUTE
CRON_MINUTE=${CRON_MINUTE:-$(shuf -i 0-59 -n 1)}  # Set default to random minute if user doesn't provide input

# Cron command to execute
CRON_COMMAND="/root/myenv/bin/python ~/scripts/qnode_rewards_to_gsheet.py"

# Check if a cron job containing the command exists
EXISTING_CRON_JOB=$(crontab -l | grep -F "$CRON_COMMAND")

# If it exists, delete the existing cron job
if [ -n "$EXISTING_CRON_JOB" ]; then
    echo "⚙️ Deleting existing cron job..."
    (crontab -l | grep -vF "$CRON_COMMAND") | crontab - || { echo "❌ Failed to delete existing cron job."; exit 1; }
    echo "✅ Existing cron job deleted successfully."
fi

# New cron job with specified frequency and minute
NEW_CRON_JOB="$CRON_MINUTE */$CRON_FREQUENCY_HOURS * * * $CRON_COMMAND"

# Add the new cron job
echo "⚙️ Adding the new cron job..."
(crontab -l ; echo "$NEW_CRON_JOB") | crontab - || { echo "❌ Failed to add new cron job."; exit 1; }
echo "✅ New cron job added successfully:"
echo "$NEW_CRON_JOB"

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
