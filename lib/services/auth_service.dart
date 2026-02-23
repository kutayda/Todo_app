import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Giriş Yap
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      rethrow; 
    }
  }

  // Kayıt Ol
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // Çıkış Yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Mevcut Kullanıcı Durumu (Stream)
  Stream<User?> get userStatus => _auth.authStateChanges();
}