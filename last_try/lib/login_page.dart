import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'shared_prefs_service.dart';
import 'db_helper.dart';
import 'google_sign_in_service.dart';
import 'google_sign_in_web_service.dart';
import 'supabase_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLogin = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _ageController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _currentCityController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  DateTime? _selectedDate;

  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _birthPlaceController.dispose();
    _birthDateController.dispose();
    _ageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentCityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleUserProfileData(User firebaseUser, {bool isNewEmailPasswordUser = false}) async {
    String? email = firebaseUser.email;
    String? firebaseDisplayName = firebaseUser.displayName;
    String? derivedFirstName;
    String? derivedLastName;

    if (firebaseDisplayName != null && firebaseDisplayName.contains(" ")) {
      final parts = firebaseDisplayName.split(" ");
      derivedFirstName = parts.first;
      derivedLastName = parts.length > 1 ? parts.sublist(1).join(" ") : null;
    } else {
      derivedFirstName = firebaseDisplayName;
    }

    String? supabaseFirstName = isNewEmailPasswordUser && _firstNameController.text.trim().isNotEmpty
        ? _firstNameController.text.trim()
        : derivedFirstName;
    String? supabaseLastName = isNewEmailPasswordUser && _lastNameController.text.trim().isNotEmpty
        ? _lastNameController.text.trim()
        : derivedLastName;
    String? supabaseBirthPlace = isNewEmailPasswordUser ? _birthPlaceController.text.trim() : null;
    String? supabaseBirthDate = isNewEmailPasswordUser ? _birthDateController.text.trim() : null;
    String? supabaseCurrentCity = isNewEmailPasswordUser ? _currentCityController.text.trim() : null;

    await _supabaseService.upsertProfile(
      userId: firebaseUser.uid,
      email: email!,
      firstName: supabaseFirstName,
      lastName: supabaseLastName,
      birthPlace: supabaseBirthPlace,
      birthDate: supabaseBirthDate,
      currentCity: supabaseCurrentCity,
    );

    if (isNewEmailPasswordUser) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set({
        'email': _emailController.text.trim(),
        'birthPlace_firestore': _birthPlaceController.text.trim(),
        'birthDate_firestore': _birthDateController.text.trim(),
        'age_firestore': _ageController.text.trim(),
        'createdAt': Timestamp.now(),
        'signInMethod': 'email',
      });
    }

    String? nameForPrefs = supabaseFirstName;
    String? surnameForPrefs = supabaseLastName;

    if ((nameForPrefs == null || nameForPrefs.isEmpty) && (surnameForPrefs == null || surnameForPrefs.isEmpty)) {
      nameForPrefs = firebaseDisplayName;
    }

    await SharedPrefsService.saveUserData(
      uid: firebaseUser.uid,
      email: email,
      name: nameForPrefs,
      surname: surnameForPrefs,
    );

    final userProfileForSqlite = UserProfileModel(
      userId: firebaseUser.uid,
      email: email,
      firstName: supabaseFirstName,
      lastName: supabaseLastName,
      birthPlace: supabaseBirthPlace,
      birthDate: supabaseBirthDate,
      currentCity: supabaseCurrentCity,
    );
    await DatabaseHelper.instance.upsertUserProfile(userProfileForSqlite);
    print('[LoginPage] User profile for UID: ${firebaseUser.uid} saved to SQLite. Data: ${userProfileForSqlite.toMap()}');
  }

  Future<void> _submitEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if(mounted) setState(() => _isLoading = true);

    try {
      UserCredential userCredential;
      if (_isLogin) {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (userCredential.user != null) {
          await _handleUserProfileData(userCredential.user!, isNewEmailPasswordUser: false);
        }
      } else {
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (userCredential.user != null) {
          await _handleUserProfileData(userCredential.user!, isNewEmailPasswordUser: true);
        }
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/text_conversion');
    } on FirebaseAuthException catch (e) {
      String message = 'Bir hata oluştu. Lütfen bilgilerinizi kontrol edin.';
      if (e.code == 'user-not-found' || e.code == 'INVALID_LOGIN_CREDENTIALS') {
        message = 'Bu e-posta için kullanıcı bulunamadı veya şifre hatalı.';
      } else if (e.code == 'wrong-password') {
        message = 'Hatalı şifre girdiniz.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Bu e-posta adresi zaten başka bir hesap tarafından kullanılıyor.';
      } else if (e.code == 'invalid-email') {
        message = 'Girdiğiniz e-posta adresi geçersiz.';
      } else if (e.code == 'weak-password') {
        message = 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      print("Generic error in _submitEmailPassword: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Beklenmedik bir hata oluştu.")));
    }
    finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if(mounted) setState(() => _isLoading = true);
    User? user;
    try {
      if (kIsWeb) {
        user = await GoogleSignInWebService.signInWithGoogle();
      } else {
        user = await GoogleSignInService.signInWithGoogle();
      }

      if (user != null) {
        await _handleUserProfileData(user);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/text_conversion');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google ile giriş iptal edildi veya başarısız oldu.')),
          );
        }
      }
    } catch (e) {
      print("Google sign-in error in LoginPage: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google ile giriş sırasında bir hata oluştu: ${e.toString().substring(0, (e.toString().length > 100) ? 100 : e.toString().length)}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGitHub() async {
    if(mounted) setState(() => _isLoading = true);
    try {
      final githubProvider = GithubAuthProvider();
      UserCredential userCredential = kIsWeb
          ? await FirebaseAuth.instance.signInWithPopup(githubProvider)
          : await FirebaseAuth.instance.signInWithProvider(githubProvider);
      final user = userCredential.user;

      if (user != null) {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();
        if (!userDoc.exists) {
          await userDocRef.set({
            'email': user.email ?? 'GitHub kullanıcısı e-postası yok',
            'displayName_firestore': user.displayName ?? 'GitHub Kullanıcısı',
            'signInMethod': 'github',
            'createdAt': Timestamp.now(),
          });
        }
        await _handleUserProfileData(user);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/text_conversion');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'GitHub ile giriş başarısız oldu.';
      if (e.code == 'account-exists-with-different-credential') {
        message = 'Bu e-posta ile farklı bir yöntemle (örn: Google) hesap zaten mevcut.';
      } else if (e.code == 'cancelled-popup-request' || e.code == 'popup-closed-by-user') {
        message = 'GitHub ile giriş işlemi iptal edildi.';
      }
      debugPrint('FirebaseAuthException GitHub sign-in error: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      debugPrint('Generic GitHub sign-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GitHub ile giriş sırasında beklenmedik bir hata oluştu.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.text_fields, size: 80, color: Colors.blue),
                            const SizedBox(height: 24),
                            Text(
                              _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'E-posta',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Lütfen e-posta adresinizi girin';
                                if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                                  return 'Lütfen geçerli bir e-posta adresi girin';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Şifre',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Lütfen şifrenizi girin';
                                if (value.length < 6) return 'Şifre en az 6 karakter olmalıdır';
                                return null;
                              },
                            ),
                            if (!_isLogin) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _firstNameController,
                                decoration: InputDecoration(
                                  labelText: 'Adınız',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _lastNameController,
                                decoration: InputDecoration(
                                  labelText: 'Soyadınız',
                                  prefixIcon: const Icon(Icons.person_search_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _birthPlaceController,
                                decoration: InputDecoration(
                                  labelText: 'Doğum Yeri',
                                  prefixIcon: const Icon(Icons.location_city),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Doğum yerini giriniz';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _birthDateController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Doğum Tarihi',
                                  prefixIcon: const Icon(Icons.date_range),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate ?? DateTime(2000),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null && picked != _selectedDate && mounted) {
                                    setState(() {
                                      _selectedDate = picked;
                                      _birthDateController.text = "${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}";
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Doğum tarihi seçiniz';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _currentCityController,
                                decoration: InputDecoration(
                                  labelText: 'Yaşadığı İl',
                                  prefixIcon: const Icon(Icons.location_on_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Yaş ',
                                  prefixIcon: const Icon(Icons.cake_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Yaşınızı giriniz';
                                  if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Geçerli bir yaş girin';
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitEmailPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                  _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_isLogin) ...[
                              const Text("veya şununla devam et:", style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.g_mobiledata_outlined, color: Colors.redAccent, size: 28),
                                  label: const Text('Google ile Giriş Yap', style: TextStyle(fontSize: 17, color: Colors.black87)),
                                  onPressed: _isLoading ? null : _signInWithGoogle,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    side: BorderSide(color: Colors.grey.shade300),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.code_rounded, color: Colors.white, size: 26),
                                  label: const Text('GitHub ile Giriş Yap', style: TextStyle(fontSize: 17, color: Colors.white)),
                                  onPressed: _isLoading ? null : _signInWithGitHub,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF333333),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _isLoading ? null : () {
                                if (mounted) setState(() => _isLogin = !_isLogin);
                              },
                              child: Text(
                                _isLogin ? 'Hesabın yok mu? Kayıt Ol' : 'Zaten hesabın var mı? Giriş Yap',
                                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}