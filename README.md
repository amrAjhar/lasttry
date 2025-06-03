# Text Converter App

Text Converter App is a Flutter application that allows users to convert text between different formats (uppercase, lowercase, reverse, capitalize words) and provides text analysis tools. The app features user authentication, profile management, and text conversion history.

## Project Purpose

The main purpose of this project is to provide users with a convenient tool for text manipulation and analysis, with secure authentication and data storage across multiple platforms (Firebase, Supabase, and local SQLite).

### Technical Details

- **Flutter:** Primary development framework
- **Firebase:**
  - Authentication (Email/Password, Google, GitHub)
  - Firestore for user data storage
- **Supabase:** For profile data and text conversion history
- **SQLite:** Local storage for user profiles
- **Shared Preferences:** For storing basic user preferences

---

## Key Features

- **User Authentication:**
  - Email/Password login and registration
  - Google Sign-In (with web support)
  - GitHub Sign-In
- **Text Conversion:**
  - Convert to uppercase
  - Convert to lowercase
  - Reverse text
  - Capitalize words
- **Text Tools:**
  - Word count
  - Character count
  - Line count
  - Copy/paste functionality
- **Profile Management:**
  - Edit personal information
  - View authentication details
  - Sync across Firebase and Supabase
- **History Tracking:** Logs of text conversions stored in Supabase

---

## Technologies Used

- **Flutter**
- **Firebase**
  - Authentication
  - Firestore
- **Supabase**
  - User profiles
  - Text conversion history
- **SQLite** (Local database)
- **Shared Preferences**

---

## Screens and Their Functions

### 1. Login Page (login_page.dart)

- **User authentication with multiple methods:**
  - Email and password
  - Google Sign-In
  - GitHub Sign-In
- Form validation for email and password fields
- Registration form with additional fields (name, birth place, birth date, etc.)
- Smooth animations for UI transitions

### 2. Text Conversion Page (text_conversion_page.dart)

- **Text conversion features:**
  - Uppercase conversion
  - Lowercase conversion
  - Text reversal
  - Word capitalization
- Copy converted text to clipboard
- History of conversions logged to Supabase
- Clean, responsive UI with animations

### 3. Tools Page (tools_page.dart)

- **Text analysis tools:**
  - Word count
  - Character count
  - Line count
- Copy/paste functionality
- Clear text input
- Statistics display in card layout

### 4. Profile Page (profile_page.dart)

- **User profile management:**
  - View and edit personal information
  - Display authentication details
  - Shows data from both Supabase and Firestore
- Profile picture display (from Google/GitHub if available)
- Edit mode with save/cancel functionality
- Animations for smooth transitions

---

## Database Structure

### Firebase Firestore
- `users` collection:
  - Stores basic user info (email, sign-in method, creation date)
  - Additional fields for email/password users (birth place, birth date, etc.)

### Supabase
- `profiles` table:
  - Stores detailed user profile information
  - Includes first name, last name, birth place, birth date, current city
- `user_text_history` table:
  - Stores text conversion history
  - Contains original text, converted text, and conversion type

### Local Storage
- SQLite database for offline access to user profiles
- Shared Preferences for basic user data (UID, email, name)

---

## State Management

- Built-in Flutter state management (setState)
- StreamBuilder for auth state changes
- Direct database access for real-time updates

---


## Getting Started

To run this project:

1. Ensure you have Flutter installed
2. Add your Firebase and Supabase configuration
3. Run `flutter pub get`
4. Launch on your preferred device/emulator
