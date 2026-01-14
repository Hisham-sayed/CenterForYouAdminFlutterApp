# Center For You - Admin App

A professional Flutter mobile admin application for managing an educational platform. This app allows administrators to manage courses, subjects, lessons, videos, exams, users, and graduation party content.

## 📱 Features

### Content Management
- **Subjects** - Create, edit, and delete subjects with images
- **Lessons** - Organize content into lesson folders within subjects
- **Videos** - Add and manage video content with secure playback
- **Exams** - Link external exams to subjects

### User Management
- **Student List** - View enrolled students with search and pagination
- **Subject Management** - Remove all subjects from users

### Special Features
- **Graduation Parties** - Manage graduation video content
- **Secure Video Player** - Built-in video playback with YouTube support

## 🎨 UI/UX Features

- **Dark Theme** - Modern dark UI with neon cyan accents
- **RTL Support** - Full right-to-left language support
- **Responsive Design** - Optimized for various screen sizes
- **Loading States** - Clear feedback during network operations
- **Success Toasts** - Confirmation messages for all actions
- **Double-tap Prevention** - Safe button handling during async operations

## 🛠️ Tech Stack

- **Framework**: Flutter 3.10+
- **State Management**: ChangeNotifier + ListenableBuilder
- **HTTP Client**: http package
- **Storage**: SharedPreferences & FlutterSecureStorage
- **Video**: youtube_player_flutter
- **UI**: Google Fonts, Material Design 3

## 📁 Project Structure

```
lib/
├── core/
│   ├── architecture/    # Base controller
│   ├── constants/       # Colors, routes
│   ├── error/           # Error handling
│   ├── services/        # API service
│   └── widgets/         # App scaffold
├── features/
│   ├── auth/            # Authentication
│   ├── dashboard/       # Home screen
│   ├── graduation/      # Graduation parties
│   ├── subjects/        # Subjects, lessons, videos, exams
│   └── users/           # User management
├── shared/
│   └── widgets/         # Reusable UI components
└── main.dart
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10.3 or higher
- Android Studio / VS Code
- Android SDK for building APK

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd CenterForYouAdmin
```

2. Create `.env` file in root directory
```env
API_BASE_URL=https://your-api-url.com
```

3. Install dependencies
```bash
flutter pub get
```

4. Run the app
```bash
flutter run
```

### Build APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## 🔐 Authentication

The app uses JWT-based authentication with:
- Access Token (short-lived)
- Refresh Token (long-lived)
- Automatic token refresh
- Secure token storage

## 📄 License

Private - All rights reserved.
