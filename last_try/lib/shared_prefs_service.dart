import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String _keyUserUid = 'user_uid';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserSurname = 'user_surname';

  static Future<void> saveUserData({
    required String uid,
    required String? email,
    required String? name,
    String? surname,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserUid, uid);
    if (email != null) await prefs.setString(_keyUserEmail, email);
    if (name != null) await prefs.setString(_keyUserName, name);
    if (surname != null) await prefs.setString(_keyUserSurname, surname);
    print('[SharedPrefsService] User data saved: UID: $uid, Email: $email, Name: $name, Surname: $surname');
  }

  static Future<String?> getUserUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserUid);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  static Future<String?> getUserSurname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserSurname);
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserUid);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserSurname);
    print('[SharedPrefsService] User data cleared.');
  }
}