# How to Create a Manual Update Release

Since we are not using the Google Play Store, we will use **GitHub Releases** to host the APK file and **Firebase Remote Config** to notify the app about the new version.

## Prerequisites
- You have built the release APK.
- You have access to the GitHub repository.
- You have access to the Firebase Console.

## Step 1: Build the Release APK
Run the following command in your terminal to build the release APK:
```bash
flutter build apk --release
```
The output file will be located at: `build/app/outputs/flutter-apk/app-release.apk`

## Step 2: Create a GitHub Release
1. Go to your GitHub repository: [hamza-damra/flutter_wallet_app](https://github.com/hamza-damra/flutter_wallet_app)
2. Click on **Releases** on the right sidebar.
3. Click **Draft a new release**.
4. **Choose a tag**: Create a new tag, e.g., `v1.0.3`.
5. **Release title**: Enter a title, e.g., `Version 1.0.3 - Glassy Theme Update`.
6. **Description**: Describe the changes (e.g., "Enhanced Home Screen with Glassy Theme").
7. **Attach binaries**: Drag and drop the `app-release.apk` file you built in Step 1.
8. Click **Publish release**.

## Step 3: Get the Download Link
1. After publishing, right-click on the `app-release.apk` link in the release assets and copy the link address.
   - It should look like: `https://github.com/hamza-damra/flutter_wallet_app/releases/download/v1.0.3/app-release.apk`

## Step 4: Update Firebase Remote Config
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Navigate to **Run** -> **Remote Config**.
3. Edit the following parameters:
   - **`latest_version_code`**: Set to the new version code (e.g., `4`).
   - **`latest_version_name`**: Set to the new version name (e.g., `1.0.3`).
   - **`apk_url`**: Paste the direct download link you copied from GitHub.
   - **`update_message`**: (Optional) "A new version with a beautiful Glassy theme is available!"
   - **`force_update`**: Set to `true` if you want to force everyone to update, or `false` for optional.
4. Click **Publish changes**.

## Verification
1. Open the app on a device with an older version.
2. The app should automatically prompt for an update.
3. Or, go to **Menu > About** and click **Check for Updates**.
4. Clicking "Update" should start downloading the APK from GitHub.
