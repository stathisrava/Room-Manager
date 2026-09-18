# Room_Manager

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
<img width="250" height="450" alt="Screenshot_2026-09-17-03-06-05-58_b783bf344239542886fee7b48fa4b892" src="https://github.com/user-attachments/assets/e9babc68-79ff-4240-9d92-7f8485d83190" />
<img width="250" height="450" alt="Screenshot_2026-09-17-03-04-20-34_822461a6166c58bd5f2d81d751d6ec7b" src="https://github.com/user-attachments/assets/989fcceb-67ee-428c-9af5-c01ae733161f" />
<img width="250" height="450" alt="Screenshot_2026-09-17-03-00-24-09_822461a6166c58bd5f2d81d751d6ec7b" src="https://github.com/user-attachments/assets/d1a467fa-a4db-47c4-9abe-3f2bf1bd4c8c" />
<img width="250" height="450" alt="Screenshot_2026-09-17-03-05-09-72_822461a6166c58bd5f2d81d751d6ec7b" src="https://github.com/user-attachments/assets/76999bf2-199c-4d4c-b44b-31cde411ea8d" />
<img width="250" height="450" alt="Screenshot_2026-09-17-03-00-37-20_822461a6166c58bd5f2d81d751d6ec7b" src="https://github.com/user-attachments/assets/05153ada-1c1d-4107-8c95-b01ce801c8e8" />
<img width="250" height="450" alt="Screenshot_2026-09-17-03-01-29-70_822461a6166c58bd5f2d81d751d6ec7b" src="https://github.com/user-attachments/assets/59eb9590-3122-4001-8e78-979f399475f3" />
<img width="250" height="450" alt="Screenshot_2026-09-17-03-01-36-12_822461a6166c58bd5f2d81d751d6ec7b" src="https://github.com/user-attachments/assets/de2e6f22-4b06-4719-a63d-95ba7eadc196" />
<img width="250" height="450" alt="Screenshot_2026-09-17-03-01-46-90_822461a6166c58bd5f2d81d751d6ec7b" src="https://github.com/user-attachments/assets/9979edae-7677-4fe0-84fa-198de846a67d" />
<img width="400" height="450" alt="Screenshot_2026-09-17-03-03-38-88_c37d74246d9c81aa0bb824b57eaf7062" src="https://github.com/user-attachments/assets/feae6ba0-c0d3-48df-9204-551059cc973e" />


## Technologies
-Flutter  
-Dart  
-Shared Preferences —> local data storage  
-Excel —> spreadsheet export  
-Share Plus —> sharing exported files  
-Path Provider —> temporary file storage  


## Installation
   ### 1. Connect an Android phone
  -Connect your Android phone to your computer using a USB cable.  
  -On your phone, enable **Developer Options**.  
  -Enable **USB debugging**.  
  -If prompted on your phone, allow USB debugging for your computer.  
  -Open the project in **Android Studio**.  

  ### 2. Check Flutter installation
  Open the terminal in Android Studio and run:  
  flutter doctor  
  Make sure Flutter and the Android toolchain are configured correctly.  
  
  ### 3. Check connected devices
  Run:  
  flutter devices  
  Your connected Android phone should appear in the list.  
  
  ### 4. Get project dependencies
  Run:  
  flutter pub get  
  This downloads the dependencies required by the project.  
  
  ### 5. Run the application
  Run:  
  flutter run  
  Flutter will build and install the app on the connected device.  
  
  You can also select the connected phone as the target device in Android Studio and press Run.
  


## Data
Room and floor information is stored locally on the device using `SharedPreferences`.
