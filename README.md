# Quilibrium-Node-Rewards-to-Google-Sheet
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
  

## Upload the credentials to your server

Name yout json `quilibrium_gsheet_auth.json` and upload it to a `/root/scripts` folder. You can also do this directly n your terminal by running this command:

```bash
nano ~/scripts/quilibrium_gsheet_auth.json
```
paste all your json text and save it

## Run the installer and follow the instructions in your terminal.

```bash
mkdir -p ~/scripts && \
wget -q -O ~/scripts/qnode_rewards_to_gsheet_installer.sh https://raw.githubusercontent.com/lamat1111/Quilibrium-Node-Rewards-to-Google-Sheet/main/installer.sh && \
chmod +x ~/scripts/qnode_rewards_to_gsheet_installer.sh && \
~/scripts/qnode_rewards_to_gsheet_installer.sh
```

The installer will create the file `~/scripts/qnode_rewards_to_gsheet.config`, which you can manually edit if you need. If something does not work in populating your Google Sheet doc, that is the first place you should look in by simply running:

```bash
nano ~/scripts/qnode_rewards_to_gsheet.config
```
