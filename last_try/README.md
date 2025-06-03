# 🎲 Random Emoji App

This is a simple Flutter app that shows random emojis and allows users to register, log in, and manage their profiles. The app uses Firebase for authentication and Supabase + local storage for managing user data.

## ✅ Features

- User registration and login using:
  - Email & password
- User profile contains:
  - Birth date
  - Birth place
  - Province of residence
- Profile info saved in **Supabase**
- Authentication info saved in **Firebase**
- User UID, email, name, and surname saved in **SharedPreferences**
- Profile info also cached using **SQLite**
- Base page system with shared `AppBar` and `Drawer`
- Shows random emojis on the home page

## 📁 Project Structure


lib/
├── models/                # User, profile, emoji models
├── services/              # Firebase, Supabase, local storage
├── viewmodels/            # View logic and state
├── views/                 # Pages like Home, Profile, Login
├── widgets/               # Reusable UI components (Drawer, AppBar)
└── main.dart              # Entry point
