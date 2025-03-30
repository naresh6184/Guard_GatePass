# GuardPass App

## Overview

GuardPass App also  is a a part of **Gate Pass Automation Ecosystem** and a feature-rich Flutter application designed to efficiently manage the permissions on  gate passes. It combines Firebase-powered authentication and real-time database functionalities with a sleek and user-friendly interface.

## Features
- **User Authentication**:
  - Sign up and log in using Firebase Authentication.
  - Password recovery for easy account access.
- **Gate Pass Management**:
  - Scan gate passes and validate permissions.
  - Automatic handling of expired passes.
- **Modern UI**:
  - Intuitive and visually appealing design with custom assets.

## Tech Stack
- **Frontend**: Flutter
- **Backend/Database**: Firebase (Authentication, Firestore)
- **Assets**: Custom images and icons for a personalized user experience.

## File Structure
Key directories and files:
- `lib/`: Flutter source code, including:
  - `main.dart`: Entry point of the app.
  - `login.dart`: User login logic.
  - `signup.dart`: User registration functionality.
  - `gatepasspermission.dart`: Gate pass validation logic.
  - `update_expired_status.dart`: Automated updates for expired passes.
- `assets/`: Custom icons and images.
- `Guard images/`: Screenshots of the app in action.
- `pubspec.yaml`: Dependency and asset management.

## Screenshots
Below are screenshots showcasing the app:

| Sign Up Page |Login Page |
|--------------|----------------------|
| ![Signup](Guard%20images/IMG_20250116_102752.jpg)  | ![Login](Guard%20images/IMG_20250116_102817.jpg) |

| Gate Pass Dashboard | Gate Pass Permission Page |
|---------------------|---------------------------|
| ![Dashboard](Guard%20images/IMG_20250116_102733.jpg) | ![Permission](Guard%20images/image.png) |


## Creative Visualization
 ```mermaid
flowchart TD
    A[Sign Up] --> B[Log In]
    B --> C[Dashboard]
    C --> D[Scan Gate Passes]
    D --> E[Validate Pass Permissions]
    E --> F[Check Expiry]
    F --> G[Update Expired Passes]

```

## Getting Started

### Prerequisites
- Install Flutter SDK.
- Set up a Firebase project with Authentication and Firestore enabled.

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/naresh6184/Guard_GatePass.git
   cd Guard_GatePass
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Set up Firebase:
   - Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective directories.

### Run the App
Launch the app on a connected device or emulator:
```bash
flutter run
```

## Usage
- **Sign Up**: Register with an email and password.
- **Log In**: Authenticate and access the dashboard.
- **Manage Gate Passes**: Scan passes and validate permissions.
- **Handle Expirations**: Automatically update expired passes.

## Contributing
Contributions are welcome! Follow these steps:
1. Fork the repository.
2. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Commit changes:
   ```bash
   git commit -m "Add new feature"
   ```
4. Push the branch:
   ```bash
   git push origin feature/your-feature-name
   ```
5. Open a pull request.

## License
This project is licensed under the **MIT License**.

## Author
Naresh Jangir

Contact: nareshjangir6184@gmail.com


