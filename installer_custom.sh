#!/bin/bash

echo ""
echo "This script will create an automation to populate your GSheet with QUIL hourly rewards for each node."
echo "This is a custom version and will not work for you unless you modify it."
echo ""
sleep 1

# Ask user for start column letter
read -p "Enter the start column letter to populate (e.g., A, B, C...): " START_COLUMN

# Download the script from GitHub
echo "Grabbing the script..."
wget -O ~/scripts/qnode_rewards_to_gsheet.py https://github.com/lamat1111/Quilibrium-Node-Rewards-to-Google-Sheet/raw/main/qnode_rewards_to_gsheet.py

# Ensure script is executable
echo "Changing permissions for the script..."
chmod +x ~/scripts/qnode_rewards_to_gsheet.py 
sleep 1

# Create .config file
echo "Creating configuration file..."
cat <<EOF > ~/scripts/qnode_rewards_to_gsheet.config
SHEET_NAME=Quilibrium nodes
SHEET_TAB_NAME=Rewards
START_COLUMN=$START_COLUMN
START_ROW=4
EOF

# Ensure config file is executable (not necessary for config files, but keeping for consistency)
chmod +x ~/scripts/qnode_rewards_to_gsheet.config

sleep 1

# Run the script for testing
echo "Running the script for testing..."
python3 ~/scripts/qnode_rewards_to_gsheet.py || { echo "❌ Script test run failed."; exit 1; }

echo "✅ Script setup and test run completed successfully."
