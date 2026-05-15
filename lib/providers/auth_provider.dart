import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? assignedLab;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.assignedLab,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      fullName: map['full_name'] ?? 'Unknown TA',
      email: map['email'] ?? '',
      role: map['role'] ?? 'lab_ta',
      assignedLab: map['assigned_lab'],
    );
  }
}

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    
    return UserProfile.fromMap(response);
  } catch (e) {
    print('Error fetching user profile: $e');
    return null;
  }
});
