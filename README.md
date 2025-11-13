# ICA 17 – Firebase Cloud Messaging Demo

A simple Flutter app for the Mobile Application Development course (In-Class Activity 17).  
The app integrates **Firebase Cloud Messaging (FCM)** and demonstrates handling **regular** and **important** push notifications.

## Features

- Initializes Firebase on app launch.
- Displays the device’s **FCM token** on screen.
- Receives push notifications sent from **Firebase Cloud Messaging**.
- Distinguishes two types of notifications:
  - **REGULAR** – default style.
  - **IMPORTANT** – uses `data["type"] = "important"` and is highlighted in red.
- Shows a list of all received notifications with timestamp and source (foreground / background / opened from tray).

## How to Test

1. Run the app on an Android device/emulator.
2. Copy the FCM token displayed under **“Your FCM Token”**.
3. In **Firebase Console → Messaging**, create a **Firebase Notification message**:
   - For a **regular** notification: just set title/body and send to the token.
   - For an **important** notification: add custom data  
     `type = important` and send to the same token.
4. Observe how:
   - Regular notifications appear as **REGULAR** cards.
   - Important notifications appear as **IMPORTANT** cards with red styling.

## Tech Stack

- Flutter
- Firebase Core
- Firebase Cloud Messaging
<img width="1420" height="700" alt="Regular" src="https://github.com/user-attachments/assets/ee00ba41-63a5-402f-84aa-c6f6587fd387" />
<img width="1420" height="700" alt="Important" src="https://github.com/user-attachments/assets/25cda278-792a-44fd-a43e-3c0b12a77d8e" />
<img width="1420" height="700" alt="Interface" src="https://github.com/user-attachments/assets/259e7f4f-28df-43d7-8250-cff2bd4effae" />


