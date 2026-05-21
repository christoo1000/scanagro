import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabase;

  AuthRepositoryImpl({required this.supabase});

  @override
  Future<void> login(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> loginAsGuest() async {
    // Supabase doesn't have a direct "anonymous" sign-in like Firebase, 
    // but we can use a custom logic or a shared guest account if needed.
    // For now, we'll simulate guest mode by not requiring auth for certain features.
  }

  @override
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  @override
  Stream<String?> get authStateChanges => 
    supabase.auth.onAuthStateChange.map((event) => event.session?.user.id);
}
