import 'package:supabase_flutter/supabase_flutter.dart';

const String _supabaseUrl = 'https://gieevfsevgwpzkyefoz.supabase.co';
const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cIkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsnJlZiI6ImdpZWV2ZnNldmd3cHpreWVqZm96Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg2MDY2MDcsImV4cCI6MjA2NDE4MjYwN30.vZJYGCbEuyS9AnzL3ojDIrebrLIceEGe5Gv8B_kdEJ0';

late final SupabaseClient supabaseClientInstance;

class SupabaseServiceInitializer {
  static Future<void> initialize() async {
    print('[SupabaseServiceInitializer] Attempting to initialize Supabase with URL: $_supabaseUrl');
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
      );
      supabaseClientInstance = Supabase.instance.client;
      print('[SupabaseServiceInitializer] Supabase initialized successfully. Client assigned.');
    } catch (e) {
      print('[SupabaseServiceInitializer] !!! Supabase initialization FAILED: $e');
      rethrow;
    }
  }
}

class SupabaseService {
  final SupabaseClient _client = supabaseClientInstance;

  static const String profilesTable = 'profiles';

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    print('[SupabaseService] Attempting to GET profile for userId: $userId');
    try {
      final response = await _client
          .from(profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();
      print('[SupabaseService] getProfile response for $userId: $response');
      return response;
    } catch (e) {
      print('[SupabaseService] !!! Supabase getProfile ERROR for $userId: $e');
      if (e is PostgrestException) {
        print('[SupabaseService] PostgrestException Details: ${e.message}, Code: ${e.code}, Details: ${e.details}, Hint: ${e.hint}');
      }
      return null;
    }
  }

  Future<void> upsertProfile({
    required String userId,
    required String email,
    String? firstName,
    String? lastName,
    String? birthPlace,
    String? birthDate,
    String? currentCity,
  }) async {
    final Map<String, dynamic> dataToUpsert = {
      'id': userId,
      'email': email,
    };
    if (firstName != null && firstName.isNotEmpty) dataToUpsert['first_name'] = firstName;
    if (lastName != null && lastName.isNotEmpty) dataToUpsert['last_name'] = lastName;
    if (birthPlace != null && birthPlace.isNotEmpty) dataToUpsert['birth_place'] = birthPlace;
    if (birthDate != null && birthDate.isNotEmpty) dataToUpsert['birth_date'] = birthDate;
    if (currentCity != null && currentCity.isNotEmpty) dataToUpsert['current_city'] = currentCity;

    Map<String, dynamic>? existingProfile;
    try {
      existingProfile = await getProfile(userId);
    } catch (e) {
      print("[SupabaseService] Error checking existing profile during upsert: $e");
    }

    if (existingProfile == null) {
      dataToUpsert['created_at'] = DateTime.now().toIso8601String();
      print('[SupabaseService] Profile for $userId does not exist. Adding created_at client-side.');
    } else {
      print('[SupabaseService] Profile for $userId exists. Will update.');
    }

    print('[SupabaseService] Attempting to UPSERT profile for userId: $userId with data: $dataToUpsert');
    try {
      await _client.from(profilesTable).upsert(dataToUpsert, onConflict: 'id');
      print('[SupabaseService] Supabase profile upserted successfully for user: $userId');
    } catch (e) {
      print('[SupabaseService] !!! Supabase upsertProfile ERROR for $userId: $e');
      if (e is PostgrestException) {
        print('[SupabaseService] PostgrestException Details: ${e.message}, Code: ${e.code}, Details: ${e.details}, Hint: ${e.hint}');
      }
    }
  }

  static const String historyTable = 'user_text_history';

  Future<void> addTextHistory({
    required String userId,
    required String originalText,
    required String convertedText,
    required String conversionType,
  }) async {
    print('[SupabaseService] Attempting to ADD text history for userId: $userId');
    try {
      await _client.from(historyTable).insert({
        'user_id': userId,
        'original_text': originalText,
        'converted_text': convertedText,
        'conversion_type': conversionType,
      });
      print('[SupabaseService] Text history added successfully for user: $userId');
    } catch (e) {
      print('[SupabaseService] !!! Supabase addTextHistory ERROR for $userId: $e');
      if (e is PostgrestException) {
        print('[SupabaseService] PostgrestException Details: ${e.message}, Code: ${e.code}, Details: ${e.details}, Hint: ${e.hint}');
      }
    }
  }

  Future<List<Map<String, dynamic>>?> getTextHistory(String userId) async {
    print('[SupabaseService] Attempting to GET text history for userId: $userId');
    try {
      final response = await _client
          .from(historyTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      print('[SupabaseService] getTextHistory response for $userId: $response');
      return response;
    } catch (e) {
      print('[SupabaseService] !!! Supabase getTextHistory ERROR for $userId: $e');
      if (e is PostgrestException) {
        print('[SupabaseService] PostgrestException Details: ${e.message}, Code: ${e.code}, Details: ${e.details}, Hint: ${e.hint}');
      }
      return null;
    }
  }
}