#!/bin/bash

echo "Converting Python setup to use virtual environment..."

# Install required packages
echo "Installing required packages..."
sudo apt update
sudo apt install -y python3 python3-venv python3-pip

# Create and setup virtual environment
echo "Creating virtual environment..."
python3 -m venv ~/myenv

# Activate virtual environment
echo "Activating virtual environment..."
source ~/myenv/bin/activate

# Install required Python packages
echo "Installing Python packages..."
pip install gspread oauth2client

# Function to update cron job
update_cron_job() {
    local old_command="$1"
    local script_path="$2"
    
    # Get existing cron schedule for this command
    existing_schedule=$(crontab -l | grep "$old_command" | awk '{$6=""; print substr($0,1,length($0)-1)}')
    
    if [ ! -z "$existing_schedule" ]; then
        echo "Found existing cron job for $script_path"
        echo "Current schedule: $existing_schedule"
        
        # Create new command with venv python
        new_command="$existing_schedule /root/myenv/bin/python $script_path"
        
        # Update crontab: replace old command with new one
        (crontab -l | sed "s|$old_command|/root/myenv/bin/python $script_path|g") | crontab -
        
        echo "Updated cron job to use virtual environment"
    fi
}

# Update both possible cron jobs
echo "Updating cron jobs..."
update_cron_job "/usr/bin/python3 ~/scripts/qnode_rewards_to_gsheet.py" "~/scripts/qnode_rewards_to_gsheet.py"
update_cron_job "/usr/bin/python3 /root/scripts/qnode_rewards_to_gsheet_2.py" "/root/scripts/qnode_rewards_to_gsheet_2.py"

echo "Testing virtual environment setup..."
if python -c "import gspread; print('✅ gspread successfully imported')" 2>/dev/null; then
    echo "✅ Virtual environment is working correctly"
else
    echo "❌ Error: Failed to import gspread. Please check the installation"
    exit 1
fi

echo "
Setup completed:
1. Virtual environment created at ~/myenv
2. Required packages installed
3. Cron jobs updated to use virtual environment
4. Original cron schedules preserved

To manually activate the virtual environment in the future:
source ~/myenv/bin/activate

Current cron jobs:"
crontab -l | grep "qnode_rewards"

echo "
To verify everything is working, you can run:
/root/myenv/bin/python ~/scripts/qnode_rewards_to_gsheet.py"