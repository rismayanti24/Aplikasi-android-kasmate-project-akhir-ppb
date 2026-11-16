import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Instance singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Mendapatkan user yang sedang login saat ini
  User? get currentUser => _auth.currentUser;

  /// Stream perubahan status login realtime
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Cek apakah user sedang login
  bool get isLoggedIn => currentUser != null;

  /// Register akun baru dengan Email & Password
  Future<User?> register({
    required String email,
    required String password,
    String? namaLengkap,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null && namaLengkap != null && namaLengkap.isNotEmpty) {
        await user.updateDisplayName(namaLengkap.trim());
        await user.reload();
      }

      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Terjadi kesalahan saat pendaftaran: ${e.toString()}';
    }
  }

  /// Login dengan Email & Password
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Terjadi kesalahan saat masuk: ${e.toString()}';
    }
  }

  /// Logout dari akun
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Gagal keluar akun: ${e.toString()}';
    }
  }

  /// Hapus akun pengguna saat ini dari Firebase Authentication
  Future<void> hapusAkun() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Demi keamanan, silakan keluar lalu masuk kembali sebelum menghapus akun.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Gagal menghapus akun: ${e.toString()}';
    }
  }

  /// Kirim email reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Gagal mengirim email reset: ${e.toString()}';
    }
  }

  /// Helper untuk menerjemahkan error code Firebase ke Bahasa Indonesia yang ramah
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi salah. Silakan coba lagi.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan gunakan email lain atau masuk.';
      case 'invalid-email':
        return 'Format alamat email tidak valid.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan oleh administrator.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat.';
      case 'network-request-failed':
        return 'Koneksi internet terputus. Periksa jaringan kamu.';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi (${e.code}).';
    }
  }
}

// Instance global yang mudah diakses di seluruh aplikasi
final authService = AuthService();
