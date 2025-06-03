import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleSignInWebService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
      final User? user = userCredential.user;

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'email': user.email,
          'name': user.displayName ?? '',
          'createdAt': Timestamp.now(),
          'signInMethod': 'google',
        });
      }

      return user;
    } catch (e) {
      print('Google web sign-in error: $e');
      return null;
    }
  }
}
