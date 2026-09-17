# room_manager

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


Room Manager is a Flutter app for managing hotel floors, rooms, and guests in a simple visual layout.

## Features
🏢 Create and manage multiple floors
🛏️ Add and organize rooms on a customizable grid
👤 Store guest names and information
📅 Track check-in and check-out dates
🟢 Track room availability
🔴 Mark rooms as occupied
🟠 Mark rooms as damaged
🔵 Add extra rooms for storage or utilities
↔️ Move rooms around the grid with drag & drop
📊 Export floor room data to Excel
💾 Automatically save data locally

## Screenshots
<img width="1080" height="2400" alt="Screenshot_2026-09-17-03-00-37-20_822461a6166c58bd5f2d81d751d6ec7b" src="https://github.com/user-attachments/assets/a63a4868-0702-4a4b-abc1-c3bfa7705b4a" />
<img width="1080" height="2400" alt="Screenshot_2026-09-17-03-00-24-09_822461a6166c58bd5f2d81d751d6ec7b" src="https://github.com/user-attachments/assets/9de50d7e-6dc9-41b6-9001-7e1e74e4169e" />
<img width="1080" height="2400" alt="Screenshot_2026-09-17-03-06-05-58_b783bf344239542886fee7b48fa4b892" src="https://github.com/user-attachments/assets/1f7bf255-b753-4260-adcd-021baa817b97" />
<img width="1080" height="2400" alt="Screenshot_2026-09-17-03-05-09-72_822461a6166c58bd5f2d81d751d6ec7b" src="https://github.com/user-attachments/assets/8066e3eb-0ea7-4020-9666-c8228498f11c" />
<img width="1080" height="2400" alt="Screenshot_2026-09-17-03-04-20-34_822461a6166c58bd5f2d81d751d6ec7b" src="https://github.com/user-attachments/assets/e39f612a-4065-4e1c-a3b5-5445101665eb" />
<img width="1080" height="2400" alt="Screenshot_2026-09-17-03-03-38-88_c37d74246d9c81aa0bb824b57eaf7062" src="https://github.com/user-attachments/assets/af39d4ff-f9f8-4657-acea-d875f8b49dd6" />
<img width="1080" height="2400" alt="Screenshot_2026-09-17-03-01-46-90_822461a6166c58bd5f2d81d751d6ec7b" src="https://github.com/user-attachments/assets/018669cf-10ef-43a2-bdf0-59b9de5bb95f" />
<img width="1080" height="2400" alt="Screenshot_2026-09-17-03-01-36-12_822461a6166c58bd5f2d81d751d6ec7b" src="https://github.com/user-attachments/assets/d26b6b0e-ce8c-40fb-8d40-a3529ef43d25" />
<img width="1080" height="2400" alt="Screenshot_2026-09-17-03-01-29-70_822461a6166c58bd5f2d81d751d6ec7b" src="https://github.com/user-attachments/assets/a2a9c9f6-aedf-4559-bd55-b8985ddcc6e0" />


## Technologies
Flutter
Dart
Shared Preferences —> local data storage
Excel —> spreadsheet export
Share Plus —> sharing exported files
Path Provider —> temporary file storage


## Installation
  # 1. Connect an Android phone
  1. Connect your Android phone to your computer using a USB cable.
  2. On your phone, enable **Developer Options**.
  3. Enable **USB debugging**.
  4. If prompted on your phone, allow USB debugging for your computer.
  5. Open the project in **Android Studio**.

  # 2. Check Flutter installation
  Open the terminal in Android Studio and run: 
  flutter doctor
  Make sure Flutter and the Android toolchain are configured correctly.
  
  # 3. Check connected devices
  Run: 
  flutter devices
  Your connected Android phone should appear in the list.
  
  # 4. Get project dependencies
  Run:
  flutter pub get
  This downloads the dependencies required by the project.
  
  # 5. Run the application
  Run:
  flutter run
  Flutter will build and install the app on the connected device.
  
  You can also select the connected phone as the target device in Android Studio and press **Run ▶**.
  


## Data
Room and floor information is stored locally on the device using `SharedPreferences`.
