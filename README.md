### Technical Details

- **Flutter:** Primary development framework
- **Firebase:**
  - Authentication (Email/Password, Google, GitHub)
  - Firestore for user data storage
- **Supabase:** For profile data and text conversion history
- **Shared Preferences:** For storing basic user preferences

---

## Key Features

- **User Authentication:**
  - Email/Password login and registration
  - Google Sign-In (with web support)
- **Profile Management:**
  - Edit personal information
  - View authentication details
  - Sync across Firebase and Supabase

---

## Technologies Used

- **Flutter**
- **Firebase**
  - Authentication
  - Firestore
- **Supabase**
  - User profiles
- **Shared Preferences**

---

## Screens and Their Functions

### 1. Login Page (login_page.dart)

- **User authentication with multiple methods:**
  - Email and password
  - Google Sign-In
- Form validation for email and password fields
- Registration form with additional fields (name, birth place, birth date, etc.)

### 4. Profile Page (profile_page.dart)

- **User profile management:**
  - View and edit personal information
  - Display authentication details
  - Shows data from both Supabase and Firestore

---

## Database Structure

### Firebase Firestore
- `users` collection:
  - Stores basic user info (email, sign-in method, creation date)

### Supabase
- `profiles` table:
  - Stores detailed user profile information
  - Includes first name, last name, birth place, birth date, current city

### Local Storage
- Shared Preferences for basic user data 

---

## State Management

- Built-in Flutter state management (setState)
- Direct database access for real-time updates

---


## Getting Started

To run this project:

1. Ensure you have Flutter installed
2. Add your Firebase and Supabase configuration
3. Run `flutter pub get`
4. Launch on your preferred device/emulator
