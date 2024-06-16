# Quilibrium Node rewards to Google Sheet
This script automates the integration of Node rewards data into Google Sheets, utilizing JSON authentication for secure API access and providing both automated and manual installation options.

## Create your API authentication credentials

1. **Navigate to Google Console:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/).

2. **Create a New Project:**
   - If you haven't already, create a new project by clicking on the project dropdown menu at the top of the page and selecting "New Project". Give your project a name and click "Create".

3. **Enable APIs:**
   - In the Google Cloud Console, navigate to the "APIs & Services" > "Library" section.
   - Search for "Google Sheets API" and "Google Drive API" and enable them for your project.

4. **Create a Service Account:**
   - Go to "APIs & Services" > "Credentials" section.
   - Click on "Create credentials" and select "Service account".
   - Enter a name for your service account, choose a role (typically Project > Editor), and click "Continue".
   - Skip the optional steps (they are not necessary for basic authentication setup).
   - Click "Done" to create the service account.

5. **Generate and Download JSON Key File:**
   - In the "Credentials" section, locate your newly created service account under "Service Accounts".
   - Find the row for your service account and click on the pencil icon to edit.
   - Click on "Add key" > "Create new key".
   - Select "JSON" as the key type and click "Create". This will download a JSON file containing your private key and other authentication details. Keep this file secure as it grants access to your project.

6. **Grant Permissions to Google Sheet:**
   - Open your Google Sheet where you want to grant access.
   - Click on "Share" button in the top right corner.
   - Paste the email address of the service account (found in the JSON key file) into the "People" field and select "Editor" as the permission level.
   - Click "Send".
  
---

## Upload the credentials to your server

Name your JSON file `quilibrium_gsheet_auth.json` and upload it to the `/root/scripts` folder. You can also do this directly in your terminal by running the following command:

```bash
nano /root/scripts/quilibrium_gsheet_auth.json
```
Paste your entire JSON content into the editor and save the file.

## Run the installer and follow the instructions in your terminal.

```bash
mkdir -p ~/scripts && \
wget -q -O ~/scripts/qnode_rewards_to_gsheet_installer.sh https://raw.githubusercontent.com/lamat1111/Quilibrium-Node-Rewards-to-Google-Sheet/main/installer.sh && \
chmod +x ~/scripts/qnode_rewards_to_gsheet_installer.sh && \
~/scripts/qnode_rewards_to_gsheet_installer.sh
```

The installer will create the `~/scripts/qnode_rewards_to_gsheet.config` file, which you can manually edit if needed. If something doesn't work when populating your Google Sheet, this is the first file you should check by running:

```bash
nano ~/scripts/qnode_rewards_to_gsheet.config
```

## Manual installation

Alternatively, you can proceed with a manual installation using the files from this repository:

1. Rename your authentication JSON file to `quilibrium_gsheet_auth.json`,and upload it to the `~/scripts` folder.
3. Download `qnode_rewards_to_gsheet.config`, edit it as necessary, and upload it to the `~/scripts` folder.
4. Make `qnode_rewards_to_gsheet.py` executable by running: `chmod +x ~/scripts/qnode_rewards_to_gsheet.py`.
5. Set up a cronjob to execute `~/scripts/qnode_rewards_to_gsheet.py` periodically.


## Troubleshooting

*If you are on a VPS/VDS, the script coudl give you an error because it cannot install the Python packages. In this case you will need to create a virtual environment for Python and install them there.*

Here is how to install `gspread` and `oauth2client` using `pip3` in a virtual environment on a Linux system, and how to automate virtual environment activation by adding a command to `~/.bashrc`.

### Installing gspread and oauth2client in a Virtual Environment

#### 1. Create a Virtual Environment

Open a terminal and follow these commands:

```bash
# Install Python 3 venv module if not already installed
sudo apt update
sudo apt install python3-venv

# Create a new directory for your project (optional)
mkdir my_project
cd my_project

# Create a virtual environment named 'myenv'
python3 -m venv myenv
```

#### 2. Activate the Virtual Environment

Activate the virtual environment to isolate package installations:

```bash
# Activate the virtual environment
source myenv/bin/activate
```

#### 3. Install gspread and oauth2client

Now install `gspread` and `oauth2client` within the virtual environment:

```bash
# Install gspread and oauth2client using pip3
pip3 install gspread oauth2client
```

#### 4. Test Installation

You can verify that the packages were installed correctly:

```bash
# Test gspread installation
python3 -c "import gspread; print(gspread.__version__)"

# Test oauth2client installation
python3 -c "import oauth2client; print(oauth2client.__version__)"
```

#### 5. Automate Virtual Environment Activation (Optional but Recommended)

To automatically activate the virtual environment whenever you start a new terminal session, add the following line to your `~/.bashrc` file:

```bash
# Open ~/.bashrc in a text editor
nano ~/.bashrc

# Add the following line at the end of the file
source /path/to/your/myenv/bin/activate

# Save and close the file (in nano: Ctrl + X, then Y to confirm, then Enter)
```

Replace `/path/to/your/myenv` with the actual path to your virtual environment. If you're in your home directory and your virtual environment is named `myenv`, you can use `source ~/myenv/bin/activate`.

#### 6. Reload ~/.bashrc

After editing `~/.bashrc`, reload it in the current terminal session:

```bash
source ~/.bashrc
```

### Summary

Now you have `gspread` and `oauth2client` installed in a Python virtual environment (`myenv`). This setup ensures that your Python dependencies are isolated and won't interfere with other projects or the system-wide Python installation. Additionally, your virtual environment will be automatically activated every time you open a new terminal session, simplifying your workflow.

This approach is effective for managing Python packages and ensuring a clean development environment. If you encounter any issues, double-check the paths and commands, and ensure your virtual environment is activated (`(myenv)` prefix in your terminal prompt).
