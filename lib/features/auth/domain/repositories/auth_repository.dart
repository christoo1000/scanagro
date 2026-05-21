abstract class AuthRepository {
  Future<void> login(String email, String password);
  Future<void> loginAsGuest();
  Future<void> logout();
  Stream<String?> get authStateChanges;
}
