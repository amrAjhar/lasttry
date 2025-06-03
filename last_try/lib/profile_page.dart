import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_page.dart';
import 'supabase_service.dart';
import 'db_helper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseService _supabaseService = SupabaseService();

  fb_auth.User? _currentUser;
  Map<String, dynamic>? _supabaseProfileData;
  Map<String, dynamic>? _firestoreUserData;

  bool _isLoading = true;
  bool _isEditingSupabase = false;

  final _supabaseFirstNameController = TextEditingController();
  final _supabaseLastNameController = TextEditingController();
  final _supabaseBirthPlaceController = TextEditingController();
  final _supabaseBirthDateController = TextEditingController();
  final _supabaseCurrentCityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUser = _firebaseAuth.currentUser;
    _loadAllProfileData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  Future<void> _loadAllProfileData() async {
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (mounted) setState(() => _isLoading = true);

    try {
      _supabaseProfileData = await _supabaseService.getProfile(_currentUser!.uid);
      if (mounted && _supabaseProfileData != null) {
        _supabaseFirstNameController.text = _supabaseProfileData!['first_name'] ?? '';
        _supabaseLastNameController.text = _supabaseProfileData!['last_name'] ?? '';
        _supabaseBirthPlaceController.text = _supabaseProfileData!['birth_place'] ?? '';
        _supabaseBirthDateController.text = _supabaseProfileData!['birth_date'] ?? '';
        _supabaseCurrentCityController.text = _supabaseProfileData!['current_city'] ?? '';
      }

      final firestoreDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (mounted && firestoreDoc.exists) {
        _firestoreUserData = firestoreDoc.data();
      }
    } catch (e) {
      print("Error loading profile data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profil verileri yüklenirken hata: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfileChanges() async {
    if (_currentUser == null || !mounted) return;
    setState(() => _isLoading = true);
    try {
      String updatedFirstName = _supabaseFirstNameController.text.trim();
      String updatedLastName = _supabaseLastNameController.text.trim();
      String updatedBirthPlace = _supabaseBirthPlaceController.text.trim();
      String updatedBirthDate = _supabaseBirthDateController.text.trim();
      String updatedCurrentCity = _supabaseCurrentCityController.text.trim();

      await _supabaseService.upsertProfile(
        userId: _currentUser!.uid,
        email: _currentUser!.email!,
        firstName: updatedFirstName,
        lastName: updatedLastName,
        birthPlace: updatedBirthPlace,
        birthDate: updatedBirthDate,
        currentCity: updatedCurrentCity,
      );
      print('[ProfilePage] Profile updated in Supabase for UID: ${_currentUser!.uid}');

      final userProfileForSqlite = UserProfileModel(
        userId: _currentUser!.uid,
        email: _currentUser!.email,
        firstName: updatedFirstName,
        lastName: updatedLastName,
        birthPlace: updatedBirthPlace,
        birthDate: updatedBirthDate,
        currentCity: updatedCurrentCity,
      );
      await DatabaseHelper.instance.upsertUserProfile(userProfileForSqlite);
      print('[ProfilePage] User profile for UID: ${_currentUser!.uid} updated in SQLite. Data: ${userProfileForSqlite.toMap()}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla güncellendi (Supabase & SQLite)!')),
      );
      setState(() {
        _isEditingSupabase = false;
      });
      await _loadAllProfileData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil güncellenirken hata oluştu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectSupabaseBirthDate(BuildContext context) async {
    DateTime initialDate = DateTime(2000);
    if (_supabaseBirthDateController.text.isNotEmpty) {
      initialDate = DateTime.tryParse(_supabaseBirthDateController.text) ?? initialDate;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _supabaseBirthDateController.text = "${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}";
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _supabaseFirstNameController.dispose();
    _supabaseLastNameController.dispose();
    _supabaseBirthPlaceController.dispose();
    _supabaseBirthDateController.dispose();
    _supabaseCurrentCityController.dispose();
    super.dispose();
  }

  Widget _buildInfoRow(String label, String? value, {Widget? trailing, bool isEditable = false, TextEditingController? controller, VoidCallback? onEditTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: isEditable && controller != null
                ? TextField(
              controller: controller,
              decoration: const InputDecoration(isDense: true),
              readOnly: label.toLowerCase().contains("tarih"),
              onTap: (label.toLowerCase().contains("tarih") && onEditTap != null) ? onEditTap : null,
            )
                : Text(value ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentUser != null) {
      return const BasePage(
        title: 'Profil',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return const BasePage(
        title: 'Profil',
        body: Center(child: Text('Lütfen giriş yapmak için ana sayfaya dönün.')),
      );
    }

    String displayNameToShow = 'İsim Yok';
    if (_supabaseProfileData != null) {
      final firstName = _supabaseProfileData!['first_name'] as String?;
      final lastName = _supabaseProfileData!['last_name'] as String?;
      if (firstName != null && firstName.isNotEmpty) {
        displayNameToShow = firstName;
        if (lastName != null && lastName.isNotEmpty) {
          displayNameToShow += ' $lastName';
        }
      } else if (lastName != null && lastName.isNotEmpty) {
        displayNameToShow = lastName;
      } else if (_currentUser!.displayName != null && _currentUser!.displayName!.isNotEmpty) {
        displayNameToShow = _currentUser!.displayName!;
      }
    } else if (_currentUser!.displayName != null && _currentUser!.displayName!.isNotEmpty) {
      displayNameToShow = _currentUser!.displayName!;
    }

    final String displayEmail = _currentUser!.email ?? 'E-posta yok';
    final String firebasePhotoUrl = _currentUser!.photoURL ?? '';
    final String firebaseCreatedAt = _currentUser!.metadata.creationTime?.toLocal().toString().substring(0, 10) ?? 'N/A';

    final String firestoreBirthPlace = _firestoreUserData?['birthPlace_firestore'] ?? 'N/A';
    final String firestoreBirthDate = _firestoreUserData?['birthDate_firestore'] ?? 'N/A';
    final String firestoreAge = _firestoreUserData?['age_firestore'] ?? 'N/A';

    List<Widget> profileAppBarActions = [
      if (_isEditingSupabase)
        IconButton(
          icon: const Icon(Icons.save),
          tooltip: 'Değişiklikleri Kaydet',
          onPressed: _isLoading ? null : _saveProfileChanges,
        ),
      IconButton(
        icon: Icon(_isEditingSupabase ? Icons.cancel : Icons.edit),
        tooltip: _isEditingSupabase ? 'Düzenlemeyi İptal Et' : 'Profili Düzenle',
        onPressed: _isLoading ? null : () {
          setState(() {
            _isEditingSupabase = !_isEditingSupabase;
            if (!_isEditingSupabase) {
              _loadAllProfileData();
            }
          });
        },
      ),
    ];

    Widget profileBody = FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _loadAllProfileData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade300, Colors.blue.shade700],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            image: firebasePhotoUrl.isNotEmpty
                                ? DecorationImage(image: NetworkImage(firebasePhotoUrl), fit: BoxFit.cover)
                                : null,
                          ),
                          child: firebasePhotoUrl.isEmpty
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(displayNameToShow, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(displayEmail, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        Chip(
                          avatar: const Icon(Icons.calendar_today, size: 16),
                          label: Text("Firebase Üyelik: $firebaseCreatedAt"),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text("Profil Bilgileri (Supabase & SQLite)", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue.shade700)),
                const Divider(thickness: 1.5),
                _buildInfoRow("Adınız:", _supabaseProfileData?['first_name'], controller: _supabaseFirstNameController, isEditable: _isEditingSupabase),
                _buildInfoRow("Soyadınız:", _supabaseProfileData?['last_name'], controller: _supabaseLastNameController, isEditable: _isEditingSupabase),
                _buildInfoRow("Doğum Yeriniz:", _supabaseProfileData?['birth_place'], controller: _supabaseBirthPlaceController, isEditable: _isEditingSupabase),
                _buildInfoRow(
                  "Doğum Tarihiniz:", _supabaseProfileData?['birth_date'],
                  controller: _supabaseBirthDateController,
                  isEditable: _isEditingSupabase,
                  onEditTap: _isEditingSupabase ? () => _selectSupabaseBirthDate(context) : null,
                ),
                _buildInfoRow("Yaşadığı İl:", _supabaseProfileData?['current_city'], controller: _supabaseCurrentCityController, isEditable: _isEditingSupabase),
                if (_isEditingSupabase) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Değişiklikleri Kaydet"),
                    onPressed: _isLoading ? null : _saveProfileChanges,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ],
                const SizedBox(height: 24),

                Text("Firestore Özel Alanlar", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.deepPurple)),
                const Divider(thickness: 1.5),
                _buildInfoRow("Doğum Yeri (Firestore):", firestoreBirthPlace),
                _buildInfoRow("Doğum Tarihi (Firestore):", firestoreBirthDate),
                _buildInfoRow("Yaş (Firestore):", firestoreAge),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );

    return BasePage(
      title: 'Profil',
      appBarActions: profileAppBarActions,
      body: profileBody,
    );
  }
}