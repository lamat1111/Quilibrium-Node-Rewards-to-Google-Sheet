# Quilibrium Node rewards to Google Sheet
Populate a Google Sheet with your node rewards.

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

